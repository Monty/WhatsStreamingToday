/*
compress_newEpisodes.rs is a rust version of compress_newEpisodes.py

Squish output of newEpisodes.sh to reduce numeric episode sequences
such that:
    Bannan, S08E01, Episode 01
    Bannan, S08E02, Episode 02
becomes:
    Bannan, S08E01-02, Episode 01-02
*/

use clap::{error::ErrorKind, Parser};
use once_cell::sync::Lazy;
use regex::Regex;
use std::fs::File;
use std::io::{self, BufRead, BufReader, Write};
use std::path::PathBuf;

// Use Lazy from once_cell to compile regexes only once.
static PAT: Lazy<Regex> = Lazy::new(|| Regex::new(r"^(.*),\s*S(\d+)E(\d+),\s*(.*)$").unwrap());
static EP_RE: Lazy<Regex> = Lazy::new(|| Regex::new(r"(?i)\bEpisode\s*(\d{1,4})").unwrap());
static PT_RE: Lazy<Regex> = Lazy::new(|| Regex::new(r"(?i)\bPart\s*(\d{1,4})").unwrap());
static EP_PT: Lazy<Regex> = Lazy::new(|| Regex::new(r"(?i)\b(Episode|Part)\s*\d{1,4}").unwrap());
static WS_RE: Lazy<Regex> = Lazy::new(|| Regex::new(r"\s+").unwrap());

#[derive(Debug, Clone)]
struct ParsedLine {
    original: String,
    prefix: String,
    season: String,
    episode: String,
    suffix: String,
}

/// Normalizes lines that start with '"' and end with '"""' by removing all quotes.
fn normalize_quotes(s: &str) -> String {
    if s.starts_with('"') && s.trim_end().ends_with("\"\"\"") {
        s.replace('"', "")
    } else {
        s.to_string()
    }
}

/// Parses a (normalized) line into its components.
fn parse(line: &str) -> Option<ParsedLine> {
    PAT.captures(line).map(|caps| {
        // Reconstruct the line with proper formatting (ensuring space after commas)
        let original = format!("{}, S{}E{}, {}", &caps[1], &caps[2], &caps[3], &caps[4]);
        ParsedLine {
            original,
            prefix: caps[1].to_string(),
            season: caps[2].to_string(),
            episode: caps[3].to_string(),
            suffix: caps[4].to_string(),
        }
    })
}

/// Strips Episode/Part numbers for logical grouping comparison
fn base_suffix(s: &str) -> String {
    let t = EP_PT.replace_all(s, "");
    let t = WS_RE.replace_all(&t, " ");
    t.trim_matches(|c: char| c.is_whitespace() || c == ':' || c == ',' || c == '-')
        .to_lowercase()
}

/// Determines if two lines belong to the same show/season/arc
fn same(a: &ParsedLine, b: &ParsedLine) -> bool {
    a.prefix == b.prefix && a.season == b.season && base_suffix(&a.suffix) == base_suffix(&b.suffix)
}

/// Checks if all numbers (main E, Episode, Part) are sequential.
fn is_consecutive(a: &ParsedLine, b: &ParsedLine) -> bool {
    // 1. Check main episode number
    let a_ep = match a.episode.parse::<i32>() {
        Ok(n) => n,
        Err(_) => return false,
    };
    let b_ep = match b.episode.parse::<i32>() {
        Ok(n) => n,
        Err(_) => return false,
    };
    if b_ep != a_ep + 1 {
        return false;
    }

    // 2. Check for 'Episode N' in title
    let a_ep_m = EP_RE.captures(&a.suffix);
    let b_ep_m = EP_RE.captures(&b.suffix);

    match (a_ep_m, b_ep_m) {
        (Some(a_m), Some(b_m)) => {
            // Both have "Episode N", check if they are consecutive
            let a_num = match a_m[1].parse::<i32>() {
                Ok(n) => n,
                Err(_) => return false,
            };
            let b_num = match b_m[1].parse::<i32>() {
                Ok(n) => n,
                Err(_) => return false,
            };
            if b_num != a_num + 1 {
                return false;
            }
        }
        (None, None) => {
            // Neither has "Episode N", that's fine
        }
        _ => {
            // One has "Episode N" and one doesn't; they are not sequential
            return false;
        }
    }

    // 3. Check for 'Part N' in title
    let a_pt_m = PT_RE.captures(&a.suffix);
    let b_pt_m = PT_RE.captures(&b.suffix);

    match (a_pt_m, b_pt_m) {
        (Some(a_m), Some(b_m)) => {
            // Both have "Part N", check if they are consecutive
            let a_num = match a_m[1].parse::<i32>() {
                Ok(n) => n,
                Err(_) => return false,
            };
            let b_num = match b_m[1].parse::<i32>() {
                Ok(n) => n,
                Err(_) => return false,
            };
            if b_num != a_num + 1 {
                return false;
            }
        }
        (None, None) => {
            // Neither has "Part N", that's fine
        }
        _ => {
            // One has "Part N" and one doesn't; they are not sequential
            return false;
        }
    }

    // All checks passed
    true
}

/// Helper to get title number (Part or Episode) or fall back to main E num.
fn get_title_num(p: &ParsedLine) -> String {
    // Check for Part number
    if let Some(pt_m) = PT_RE.captures(&p.suffix) {
        return pt_m[1].to_string();
    }

    // Check for Episode number
    if let Some(ep_m) = EP_RE.captures(&p.suffix) {
        return ep_m[1].to_string();
    }

    // Fallback to main episode number
    p.episode.clone()
}

/// Emits a compressed or single line for a group of parsed entries
fn append_group(group: &[ParsedLine], output_lines: &mut Vec<String>) {
    if group.is_empty() {
        return;
    }

    // Single line, nothing to compress
    if group.len() == 1 {
        output_lines.push(group[0].original.clone());
        return;
    }

    let first = &group[0];
    let last = group.last().unwrap();
    let e1 = &first.episode;
    let e2 = &last.episode;
    let s1 = &first.suffix;

    // Use `replace_all` to handle lines with both Episode and Part.
    let new_suffix = EP_PT.replace_all(s1, |caps: &regex::Captures| {
        // `caps[1]` is the word "Episode" or "part" in its original case.
        let word_capture = &caps[1];
        let word_lower = word_capture.to_lowercase();

        // Replace Episode/Part occurrences with appropriate ranges
        if word_lower == "episode" {
            if let (Some(ep1_m), Some(ep2_m)) = (EP_RE.captures(s1), EP_RE.captures(&last.suffix)) {
                let num1 = &ep1_m[1];
                let num2 = &ep2_m[1];
                // Check if first number has leading zeros (is padded)
                let is_padded = num1.starts_with('0') && num1.len() > 1;
                // Format second number to match first number's padding
                let formatted_num2 = if is_padded {
                    format!(
                        "{:0width$}",
                        num2.parse::<u32>().unwrap_or(0),
                        width = num1.len()
                    )
                } else {
                    num2.to_string()
                };
                return format!("{} {}-{}", word_capture, num1, formatted_num2);
            }
        }
        if word_lower == "part" {
            if let (Some(pt1_m), Some(pt2_m)) = (PT_RE.captures(s1), PT_RE.captures(&last.suffix)) {
                let num1 = &pt1_m[1];
                let num2 = &pt2_m[1];
                // Check if first number has leading zeros (is padded)
                let is_padded = num1.starts_with('0') && num1.len() > 1;
                // Format second number to match first number's padding
                let formatted_num2 = if is_padded {
                    format!(
                        "{:0width$}",
                        num2.parse::<u32>().unwrap_or(0),
                        width = num1.len()
                    )
                } else {
                    num2.to_string()
                };
                return format!("{} {}-{}", word_capture, num1, formatted_num2);
            }
        }
        // Fallback: if numbers aren't found, return the original full match.
        caps[0].to_string()
    });

    output_lines.push(format!(
        "{}, S{}E{}-{}, {}",
        first.prefix, first.season, e1, e2, new_suffix
    ));
}

/// Processes a vector of pre-normalized lines.
fn squish_lines(lines: Vec<String>, prog_name: &str) -> Vec<String> {
    const YELLOW_WARNING: &str = "\x1B[33mWarning\x1B[0m";

    let mut output_lines = Vec::new();
    let mut group: Vec<ParsedLine> = Vec::new();

    for line in &lines {
        if let Some(p) = parse(line) {
            if group.is_empty() {
                // Always start a new group if one isn't active
                group.push(p);
            } else {
                let last_in_group = group.last().unwrap();
                if same(last_in_group, &p) {
                    // It's the same show/season/arc.
                    if is_consecutive(last_in_group, &p) {
                        // It's consecutive. Add it to the group.
                        group.push(p);
                    } else {
                        // --- GAP DETECTED ---
                        // It's the same show, but not consecutive.

                        // 1. Emit warning to stderr
                        let start_num = get_title_num(last_in_group);
                        let end_num = get_title_num(&p);

                        eprintln!(
                            "{}: [{}] {} S{}: missing episodes between {} and {}",
                            prog_name, YELLOW_WARNING, p.prefix, p.season, start_num, end_num
                        );

                        // 2. Flush the old group
                        append_group(&group, &mut output_lines);

                        // 3. Start a new group with the current item
                        group = vec![p];
                    }
                } else {
                    // It's a different show/season/arc. This is a normal break.
                    append_group(&group, &mut output_lines);
                    group = vec![p];
                }
            }
        } else {
            // Not a parsable line (e.g., a header or missing space after comma)
            // Flush the last group
            append_group(&group, &mut output_lines);
            group.clear();

            // Fix missing space after comma in non-parsable lines
            let fixed_line = if line.contains(',') && !line.contains(", ") {
                line.replace(",", ", ")
            } else {
                line.clone()
            };

            output_lines.push(fixed_line);
        }
    }
    append_group(&group, &mut output_lines);
    output_lines
}

#[derive(Parser, Debug)]
#[command(version, about, long_about = None)]
struct Args {
    /// Optional input filename (reads from stdin if omitted)
    input: Option<PathBuf>,
}

/// Reads show episode listings and compresses consecutive episode sequences.
fn main() -> io::Result<()> {
    const RED_ERROR: &str = "\x1B[31mError\x1B[0m";
    let invoked_path = std::env::args().next().unwrap_or_default();
    let prog_name = std::path::Path::new(&invoked_path)
        .file_name()
        .and_then(|s| s.to_str())
        .unwrap_or("program")
        .to_string();

    // Use try_parse() which returns a Result, instead of parse().
    match Args::try_parse() {
        Ok(args) => {
            // --- On success
            let reader: Box<dyn BufRead> = if let Some(input_path) = args.input {
                match File::open(&input_path) {
                    Ok(file) => Box::new(BufReader::new(file)),
                    Err(error) => {
                        if error.kind() == io::ErrorKind::NotFound {
                            eprintln!(
                                "{}: [{}] File '{}' does not exist.",
                                prog_name,
                                RED_ERROR,
                                input_path.display()
                            );
                            std::process::exit(1);
                        } else {
                            return Err(error);
                        }
                    }
                }
            } else {
                // --- On a parsing error
                if atty::is(atty::Stream::Stdin) {
                    eprintln!(
                        "{}: [{}] No input file or piped input",
                        prog_name, RED_ERROR
                    );
                    eprintln!("Usage: ./{} <file> or use a pipe, e.g.:", prog_name);
                    eprintln!("  ./{} episodes.txt", prog_name);
                    eprintln!("  ./newEpisodes.sh | ./{}", prog_name);
                    std::process::exit(2);
                }
                Box::new(io::stdin().lock())
            };

            let normalized_lines = reader
                .lines()
                .map(|line_result| line_result.map(|line| normalize_quotes(&line)))
                .collect::<Result<Vec<_>, _>>()?;

            let squished = squish_lines(normalized_lines, &prog_name);

            let mut stdout = io::stdout();
            for line in squished {
                writeln!(stdout, "{}", line)?;
            }
        }
        Err(e) => {
            // Customize certain errors
            if e.kind() == ErrorKind::UnknownArgument {
                if let Some(arg) = e.to_string().split('\'').nth(1) {
                    eprintln!(
                        "{}: [{}] Unrecognized argument '{}'",
                        prog_name, RED_ERROR, arg
                    );
                }
                std::process::exit(2);
            } else {
                // For other errors let clap print its own helpful message.
                e.exit();
            }
        }
    }

    Ok(())
}

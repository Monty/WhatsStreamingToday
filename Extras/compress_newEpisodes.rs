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
    PAT.captures(line).map(|caps| ParsedLine {
        original: line.to_string(),
        prefix: caps[1].to_string(),
        season: caps[2].to_string(),
        episode: caps[3].to_string(),
        suffix: caps[4].to_string(),
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
                // Reuse the original-cased word from `word_capture`.
                return format!("{} {}-{}", word_capture, &ep1_m[1], &ep2_m[1]);
            }
        }
        if word_lower == "part" {
            if let (Some(pt1_m), Some(pt2_m)) = (PT_RE.captures(s1), PT_RE.captures(&last.suffix)) {
                // Reuse the original-cased word from `word_capture`.
                return format!("{} {}-{}", word_capture, &pt1_m[1], &pt2_m[1]);
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
fn squish_lines(lines: Vec<String>) -> Vec<String> {
    let mut output_lines = Vec::new();
    let mut group: Vec<ParsedLine> = Vec::new();

    for line in &lines {
        if let Some(p) = parse(line) {
            if group.is_empty() || same(group.last().unwrap(), &p) {
                group.push(p);
            } else {
                append_group(&group, &mut output_lines);
                group = vec![p];
            }
        } else {
            append_group(&group, &mut output_lines);
            group.clear();
            output_lines.push(line.clone());
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

            let squished = squish_lines(normalized_lines);

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

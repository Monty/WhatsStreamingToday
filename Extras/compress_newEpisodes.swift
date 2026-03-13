#!/usr/bin/env swift

/*
 compress_newEpisodes.swift is a swift version of compress_newEpisodes.py

 Squish output of newEpisodes.sh to reduce numeric episode sequences
 such that:
     Bannan, S08E01, Episode 01
     Bannan, S08E02, Episode 02
 becomes:
     Bannan, S08E01-02, Episode 01-02
 */

import Foundation

/// ANSI color codes for warnings and errors
let yellowWarning = "\u{001B}[33mWarning\u{001B}[0m"
let redError = "\u{001B}[31mError\u{001B}[0m"

/// Compiled regular expressions
let patRe   = #/(.*),\s*S(\d+)E(\d+),\s*(.*)/#.ignoresCase()
let epRe    = #/\bEpisode\s*(\d{1,4})/#.ignoresCase()
let ptRe    = #/\bPart\s*(\d{1,4})/#.ignoresCase()
let epPtRe  = #/\b(Episode|Part)\s*\d{1,4}/#.ignoresCase()
let wsRe    = #/\s+/#

/// ParsedLine represents a parsed episode line
struct ParsedLine {
    let original: String
    let prefix: String
    let season: String
    let episode: String
    let suffix: String
}

/// Normalize lines that start with '"' and end with '"""' by removing all double quotes
func normalizeQuotedLine(_ s: String) -> String {
    let trimmed = s.trimmingCharacters(in: .whitespaces)
    if s.hasPrefix("\""), trimmed.hasSuffix("\"\"\"") {
        return s.replacingOccurrences(of: "\"", with: "")
    }
    return s
}

/// Parse a normalized line into its components
func parseLine(_ line: String) -> ParsedLine? {
    guard let match = line.wholeMatch(of: patRe) else {
        return nil
    }

    let prefix  = String(match.output.1)
    let season  = String(match.output.2)
    let episode = String(match.output.3)
    let suffix  = String(match.output.4)

    let original = "\(prefix), S\(season)E\(episode), \(suffix)"

    return ParsedLine(original: original, prefix: prefix, season: season, episode: episode, suffix: suffix)
}

/// Remove any Episode/Part numbers before logical grouping comparison
func normalizeLineForComparison(_ s: String) -> String {
    let t = s.replacing(epPtRe, with: "")
    let u = t.replacing(wsRe, with: " ")
    return u.trimmingCharacters(in: CharacterSet(charactersIn: " :,-")).lowercased()
}

/// Determine if two lines belong to the same show/season/arc
func isSameArc(_ a: ParsedLine, _ b: ParsedLine) -> Bool {
    a.prefix == b.prefix &&
        a.season == b.season &&
        normalizeLineForComparison(a.suffix) == normalizeLineForComparison(b.suffix)
}

/// Check if all numbers (main E, Episode, Part) are sequential
func isConsecutiveEpisode(_ a: ParsedLine, _ b: ParsedLine) -> Bool {
    // 1. Check main episode number
    guard let aEp = Int(a.episode), let bEp = Int(b.episode) else {
        return false
    }
    if bEp != aEp + 1 {
        return false
    }

    // 2. Check for 'Episode N' in title
    let aEpMatch = a.suffix.firstMatch(of: epRe)
    let bEpMatch = b.suffix.firstMatch(of: epRe)

    switch (aEpMatch, bEpMatch) {
    case let (aM?, bM?):
        // Both have "Episode N", check if they are consecutive
        guard let aNum = Int(aM.output.1), let bNum = Int(bM.output.1) else { return false }
        if bNum != aNum + 1 { return false }
    case (nil, nil):
        break  // Neither has "Episode N", that's fine
    default:
        return false  // One has "Episode N" and one doesn't
    }

    // 3. Check for 'Part N' in title
    let aPtMatch = a.suffix.firstMatch(of: ptRe)
    let bPtMatch = b.suffix.firstMatch(of: ptRe)

    switch (aPtMatch, bPtMatch) {
    case let (aM?, bM?):
        // Both have "Part N", check if they are consecutive
        guard let aNum = Int(aM.output.1), let bNum = Int(bM.output.1) else { return false }
        if bNum != aNum + 1 { return false }
    case (nil, nil):
        break  // Neither has "Part N", that's fine
    default:
        return false  // One has "Part N" and one doesn't
    }

    return true
}

/// Determine the best number to use when warning about a gap
func getBestWarningNum(_ p: ParsedLine) -> String {
    // Check for Part number
    if let ptMatch = p.suffix.firstMatch(of: ptRe) {
        return String(ptMatch.output.1)
    }

    // Check for Episode number
    if let epMatch = p.suffix.firstMatch(of: epRe) {
        return String(epMatch.output.1)
    }

    // Fallback to main episode number
    return p.episode
}

/// Emit a compressed or single line for a group of parsed entries
func appendGroup(_ group: [ParsedLine], _ outputLines: inout [String]) {
    if group.isEmpty {
        return
    }

    // Single line, nothing to compress
    if group.count == 1 {
        outputLines.append(group[0].original)
        return
    }

    let first = group[0]
    let last  = group[group.count - 1]
    let e1    = first.episode
    let e2    = last.episode
    let s1    = first.suffix

    // Extract episode/part numbers from first and last entries
    var e1Text = "", e2Text = ""
    var p1Text = "", p2Text = ""

    if let ep1 = s1.firstMatch(of: epRe),
       let ep2 = last.suffix.firstMatch(of: epRe) {
        e1Text = String(ep1.output.1)
        e2Text = String(ep2.output.1)

        // Preserve padding
        if e1Text.hasPrefix("0"), e1Text.count > 1, let num = Int(e2Text) {
            e2Text = String(format: "%0\(e1Text.count)d", num)
        }
    }

    if let pt1 = s1.firstMatch(of: ptRe),
       let pt2 = last.suffix.firstMatch(of: ptRe) {
        p1Text = String(pt1.output.1)
        p2Text = String(pt2.output.1)

        // Preserve padding
        if p1Text.hasPrefix("0"), p1Text.count > 1, let num = Int(p2Text) {
            p2Text = String(format: "%0\(p1Text.count)d", num)
        }
    }

    // Replace Episode/Part sequences with appropriate ranges
    // Process matches in reverse to maintain string indices
    var newSuffix = s1
    let matches = s1.matches(of: epPtRe)

    for match in matches.reversed() {
        let word      = String(match.output.1)
        let wordLower = word.lowercased()

        let replacement: String
        if wordLower == "episode", !e1Text.isEmpty, !e2Text.isEmpty {
            replacement = "\(word) \(e1Text)-\(e2Text)"
        } else if wordLower == "part", !p1Text.isEmpty, !p2Text.isEmpty {
            replacement = "\(word) \(p1Text)-\(p2Text)"
        } else {
            continue
        }

        newSuffix.replaceSubrange(match.range, with: replacement)
    }

    let line = "\(first.prefix), S\(first.season)E\(e1)-\(e2), \(newSuffix)"
    outputLines.append(line)
}

/// Process all normalized lines and group/compress consecutive entries
func squishLines(_ lines: [String], _ progName: String) -> [String] {
    var outputLines: [String] = []
    var group: [ParsedLine] = []

    for line in lines {
        if let p = parseLine(line) {
            if group.isEmpty {
                group.append(p)
            } else {
                let lastInGroup = group[group.count - 1]
                if isSameArc(lastInGroup, p) {
                    if isConsecutiveEpisode(lastInGroup, p) {
                        group.append(p)
                    } else {
                        // GAP DETECTED
                        let startNum = getBestWarningNum(lastInGroup)
                        let endNum   = getBestWarningNum(p)

                        fputs("\(progName): [\(yellowWarning)] \(p.prefix) S\(p.season): missing episodes between \(startNum) and \(endNum)\n", stderr)

                        appendGroup(group, &outputLines)
                        group = [p]
                    }
                } else {
                    appendGroup(group, &outputLines)
                    group = [p]
                }
            }
        } else {
            // Not a parsable line
            appendGroup(group, &outputLines)
            group = []

            // Fix missing space after comma in non-parsable lines
            var fixedLine = line
            if line.contains(","), !line.contains(", ") {
                fixedLine = line.replacingOccurrences(of: ",", with: ", ")
            }

            outputLines.append(fixedLine)
        }
    }

    appendGroup(group, &outputLines)
    return outputLines
}

/// Print help message
func printHelp(_ progName: String) {
    print("""
    Reads show episode listings from stdin or a file and compresses consecutive episode sequences.

    For example:
      Bannan, S08E01, Episode 01
      Bannan, S08E02, Episode 02
    becomes:
      Bannan, S08E01-02, Episode 01-02

    Usage:
      \(progName) [input_file]
      \(progName) -h, --help

    Arguments:
      input_file    Optional input filename (reads from stdin if omitted)

    Options:
      -h, --help    Show this help message and exit

    Examples:
      ./newEpisodes.sh | ./\(progName) > newEpisodes.txt
      ./\(progName) episodes.txt > newEpisodes.txt
    """)
}

/// Main entry point
func main() {
    let progName = URL(fileURLWithPath: CommandLine.arguments[0]).lastPathComponent
    let args     = Array(CommandLine.arguments.dropFirst())

    // Check for help flags
    for arg in args {
        if arg == "-h" || arg == "--help" {
            printHelp(progName)
            exit(0)
        }
    }

    // Check for unknown flags
    for arg in args {
        if arg.hasPrefix("-") {
            fputs("\(progName): [\(redError)] Unrecognized argument '\(arg)'\n", stderr)
            exit(2)
        }
    }

    var lines: [String] = []

    if args.isEmpty {
        // Check if stdin is a terminal
        if isatty(STDIN_FILENO) != 0 {
            fputs("\(progName): [\(redError)] No input file or piped input\n", stderr)
            fputs("Usage: ./\(progName) <file> or use a pipe, e.g.:\n", stderr)
            fputs("  ./\(progName) episodes.txt\n", stderr)
            fputs("  ./newEpisodes.sh | ./\(progName)\n", stderr)
            exit(2)
        }

        // Read from stdin
        while let line = readLine(strippingNewline: true) {
            lines.append(normalizeQuotedLine(line))
        }
    } else if args.count == 1 {
        // Read from file
        let filename = args[0]

        guard let content = try? String(contentsOfFile: filename, encoding: .utf8) else {
            fputs("\(progName): [\(redError)] File '\(filename)' does not exist.\n", stderr)
            exit(1)
        }

        lines = content.components(separatedBy: .newlines).map { normalizeQuotedLine($0) }
        // Remove trailing empty line if present
        if lines.last?.isEmpty == true {
            lines.removeLast()
        }
    } else {
        fputs("\(progName): [\(redError)] Too many arguments\n", stderr)
        exit(2)
    }

    let squished = squishLines(lines, progName)

    for line in squished {
        print(line)
    }
}

main()

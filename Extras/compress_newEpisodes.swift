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
let patRe = try! NSRegularExpression(pattern: #"^(.*),\s*S(\d+)E(\d+),\s*(.*)$"#, options: [.caseInsensitive])
let epRe = try! NSRegularExpression(pattern: #"\bEpisode\s*(\d{1,4})"#, options: [.caseInsensitive])
let ptRe = try! NSRegularExpression(pattern: #"\bPart\s*(\d{1,4})"#, options: [.caseInsensitive])
let epPtRe = try! NSRegularExpression(pattern: #"\b(Episode|Part)\s*\d{1,4}"#, options: [.caseInsensitive])
let wsRe = try! NSRegularExpression(pattern: #"\s+"#, options: [])

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
    let nsLine = line as NSString
    let range = NSRange(location: 0, length: nsLine.length)

    guard let match = patRe.firstMatch(in: line, options: [], range: range) else {
        return nil
    }

    let prefix = nsLine.substring(with: match.range(at: 1))
    let season = nsLine.substring(with: match.range(at: 2))
    let episode = nsLine.substring(with: match.range(at: 3))
    let suffix = nsLine.substring(with: match.range(at: 4))

    let original = "\(prefix), S\(season)E\(episode), \(suffix)"

    return ParsedLine(original: original, prefix: prefix, season: season, episode: episode, suffix: suffix)
}

/// Remove any Episode/Part numbers before logical grouping comparison
func normalizeLineForComparison(_ s: String) -> String {
    var t = s
    let nsString = t as NSString
    let range = NSRange(location: 0, length: nsString.length)

    t = epPtRe.stringByReplacingMatches(in: t, options: [], range: range, withTemplate: "")

    let nsT = t as NSString
    let wsRange = NSRange(location: 0, length: nsT.length)
    t = wsRe.stringByReplacingMatches(in: t, options: [], range: wsRange, withTemplate: " ")

    t = t.trimmingCharacters(in: CharacterSet(charactersIn: " :,-"))
    return t.lowercased()
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
    let aEpMatch = epRe.firstMatch(in: a.suffix, options: [], range: NSRange(location: 0, length: a.suffix.count))
    let bEpMatch = epRe.firstMatch(in: b.suffix, options: [], range: NSRange(location: 0, length: b.suffix.count))

    if let aMatch = aEpMatch, let bMatch = bEpMatch {
        let aNs = a.suffix as NSString
        let bNs = b.suffix as NSString
        let aNum = Int(aNs.substring(with: aMatch.range(at: 1)))!
        let bNum = Int(bNs.substring(with: bMatch.range(at: 1)))!
        if bNum != aNum + 1 {
            return false
        }
    } else if (aEpMatch == nil) != (bEpMatch == nil) {
        return false
    }

    // 3. Check for 'Part N' in title
    let aPtMatch = ptRe.firstMatch(in: a.suffix, options: [], range: NSRange(location: 0, length: a.suffix.count))
    let bPtMatch = ptRe.firstMatch(in: b.suffix, options: [], range: NSRange(location: 0, length: b.suffix.count))

    if let aMatch = aPtMatch, let bMatch = bPtMatch {
        let aNs = a.suffix as NSString
        let bNs = b.suffix as NSString
        let aNum = Int(aNs.substring(with: aMatch.range(at: 1)))!
        let bNum = Int(bNs.substring(with: bMatch.range(at: 1)))!
        if bNum != aNum + 1 {
            return false
        }
    } else if (aPtMatch == nil) != (bPtMatch == nil) {
        return false
    }

    return true
}

/// Determine the best number to use when warning about a gap
func getBestWarningNum(_ p: ParsedLine) -> String {
    // Check for Part number
    if let ptMatch = ptRe.firstMatch(in: p.suffix, options: [], range: NSRange(location: 0, length: p.suffix.count)) {
        let ns = p.suffix as NSString
        return ns.substring(with: ptMatch.range(at: 1))
    }

    // Check for Episode number
    if let epMatch = epRe.firstMatch(in: p.suffix, options: [], range: NSRange(location: 0, length: p.suffix.count)) {
        let ns = p.suffix as NSString
        return ns.substring(with: epMatch.range(at: 1))
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
    let last = group[group.count - 1]
    let e1 = first.episode
    let e2 = last.episode
    let s1 = first.suffix

    // Extract episode/part numbers
    var e1Text = ""
    var e2Text = ""
    var p1Text = ""
    var p2Text = ""

    if let ep1Match = epRe.firstMatch(in: s1, options: [], range: NSRange(location: 0, length: s1.count)) {
        let ns1 = s1 as NSString
        e1Text = ns1.substring(with: ep1Match.range(at: 1))

        if let ep2Match = epRe.firstMatch(in: last.suffix, options: [], range: NSRange(location: 0, length: last.suffix.count)) {
            let ns2 = last.suffix as NSString
            e2Text = ns2.substring(with: ep2Match.range(at: 1))

            // Preserve padding
            if e1Text.hasPrefix("0"), e1Text.count > 1 {
                if let num = Int(e2Text) {
                    e2Text = String(format: "%0\(e1Text.count)d", num)
                }
            }
        }
    }

    if let pt1Match = ptRe.firstMatch(in: s1, options: [], range: NSRange(location: 0, length: s1.count)) {
        let ns1 = s1 as NSString
        p1Text = ns1.substring(with: pt1Match.range(at: 1))

        if let pt2Match = ptRe.firstMatch(in: last.suffix, options: [], range: NSRange(location: 0, length: last.suffix.count)) {
            let ns2 = last.suffix as NSString
            p2Text = ns2.substring(with: pt2Match.range(at: 1))

            // Preserve padding
            if p1Text.hasPrefix("0"), p1Text.count > 1 {
                if let num = Int(p2Text) {
                    p2Text = String(format: "%0\(p1Text.count)d", num)
                }
            }
        }
    }

    // Replace Episode/Part sequences with appropriate ranges
    var newSuffix = s1
    let matches = epPtRe.matches(in: s1, options: [], range: NSRange(location: 0, length: s1.count))

    // Process matches in reverse to maintain string indices
    for match in matches.reversed() {
        let ns = s1 as NSString
        let fullMatch = ns.substring(with: match.range)
        let word = ns.substring(with: match.range(at: 1))
        let wordLower = word.lowercased()

        var replacement = fullMatch
        if wordLower == "episode", !e1Text.isEmpty, !e2Text.isEmpty {
            replacement = "\(word) \(e1Text)-\(e2Text)"
        } else if wordLower == "part", !p1Text.isEmpty, !p2Text.isEmpty {
            replacement = "\(word) \(p1Text)-\(p2Text)"
        }

        let nsNewSuffix = newSuffix as NSString
        newSuffix = nsNewSuffix.replacingCharacters(in: match.range, with: replacement)
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
                        let endNum = getBestWarningNum(p)

                        FileHandle.standardError.write(
                            "\(progName): [\(yellowWarning)] \(p.prefix) S\(p.season): missing episodes between \(startNum) and \(endNum)\n"
                                .data(using: .utf8)!,
                        )

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

/// Extension to write strings to stderr
extension FileHandle {
    func write(_ string: String) {
        if let data = string.data(using: .utf8) {
            write(data)
        }
    }
}

/// Main entry point
func main() {
    let progName = (CommandLine.arguments[0] as NSString).lastPathComponent
    let args = Array(CommandLine.arguments.dropFirst())

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
            FileHandle.standardError.write("\(progName): [\(redError)] Unrecognized argument '\(arg)'\n")
            exit(2)
        }
    }

    var lines: [String] = []

    if args.isEmpty {
        // Check if stdin is a terminal
        if isatty(STDIN_FILENO) != 0 {
            FileHandle.standardError.write("\(progName): [\(redError)] No input file or piped input\n")
            FileHandle.standardError.write("Usage: ./\(progName) <file> or use a pipe, e.g.:\n")
            FileHandle.standardError.write("  ./\(progName) episodes.txt\n")
            FileHandle.standardError.write("  ./newEpisodes.sh | ./\(progName)\n")
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
            FileHandle.standardError.write("\(progName): [\(redError)] File '\(filename)' does not exist.\n")
            exit(1)
        }

        lines = content.components(separatedBy: .newlines).map { normalizeQuotedLine($0) }
        // Remove trailing empty line if present
        if lines.last?.isEmpty == true {
            lines.removeLast()
        }
    } else {
        FileHandle.standardError.write("\(progName): [\(redError)] Too many arguments\n")
        exit(2)
    }

    let squished = squishLines(lines, progName)

    for line in squished {
        print(line)
    }
}

main()

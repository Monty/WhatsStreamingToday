package main

import (
	"bufio"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
)

// ANSI color codes for warnings and errors
const (
	yellowWarning = "\033[33mWarning\033[0m"
	redError      = "\033[31mError\033[0m"
)

// Compiled regular expressions
var (
	patRe  = regexp.MustCompile(`(?i)^(.*),\s*S(\d+)E(\d+),\s*(.*)$`)
	epRe   = regexp.MustCompile(`(?i)\bEpisode\s*(\d{1,4})`)
	ptRe   = regexp.MustCompile(`(?i)\bPart\s*(\d{1,4})`)
	epPtRe = regexp.MustCompile(`(?i)\b(Episode|Part)\s*\d{1,4}`)
	wsRe   = regexp.MustCompile(`\s+`)
)

// ParsedLine represents a parsed episode line
type ParsedLine struct {
	original string
	prefix   string
	season   string
	episode  string
	suffix   string
}

// normalizeQuotedLine removes all quotes from lines that start with '"' and end with '"""'
func normalizeQuotedLine(s string) string {
	trimmed := strings.TrimSpace(s)
	if strings.HasPrefix(s, `"`) && strings.HasSuffix(trimmed, `"""`) {
		return strings.ReplaceAll(s, `"`, "")
	}
	return s
}

// parseLine parses a normalized line into its components
func parseLine(line string) *ParsedLine {
	matches := patRe.FindStringSubmatch(line)
	if matches == nil {
		return nil
	}

	return &ParsedLine{
		original: fmt.Sprintf("%s, S%sE%s, %s", matches[1], matches[2], matches[3], matches[4]),
		prefix:   matches[1],
		season:   matches[2],
		episode:  matches[3],
		suffix:   matches[4],
	}
}

// normalizeLineForComparison removes Episode/Part numbers for comparison
func normalizeLineForComparison(s string) string {
	t := epPtRe.ReplaceAllString(s, "")
	t = wsRe.ReplaceAllString(t, " ")
	t = strings.Trim(t, " :,-")
	return strings.ToLower(t)
}

// isSameArc determines if two lines belong to the same show/season/arc
func isSameArc(a, b *ParsedLine) bool {
	return a.prefix == b.prefix &&
		a.season == b.season &&
		normalizeLineForComparison(a.suffix) == normalizeLineForComparison(b.suffix)
}

// isConsecutiveEpisode checks if all numbers (main E, Episode, Part) are sequential
func isConsecutiveEpisode(a, b *ParsedLine) bool {
	// 1. Check main episode number
	aEp, _ := strconv.Atoi(a.episode)
	bEp, _ := strconv.Atoi(b.episode)
	if bEp != aEp+1 {
		return false
	}

	// 2. Check for 'Episode N' in title
	aEpMatch := epRe.FindStringSubmatch(a.suffix)
	bEpMatch := epRe.FindStringSubmatch(b.suffix)

	if aEpMatch != nil && bEpMatch != nil {
		aNum, _ := strconv.Atoi(aEpMatch[1])
		bNum, _ := strconv.Atoi(bEpMatch[1])
		if bNum != aNum+1 {
			return false
		}
	} else if (aEpMatch == nil) != (bEpMatch == nil) {
		// One has "Episode N" and one doesn't
		return false
	}

	// 3. Check for 'Part N' in title
	aPtMatch := ptRe.FindStringSubmatch(a.suffix)
	bPtMatch := ptRe.FindStringSubmatch(b.suffix)

	if aPtMatch != nil && bPtMatch != nil {
		aNum, _ := strconv.Atoi(aPtMatch[1])
		bNum, _ := strconv.Atoi(bPtMatch[1])
		if bNum != aNum+1 {
			return false
		}
	} else if (aPtMatch == nil) != (bPtMatch == nil) {
		// One has "Part N" and one doesn't
		return false
	}

	return true
}

// getBestWarningNum determines the best number to use when warning about a gap
func getBestWarningNum(p *ParsedLine) string {
	// Check for Part number
	if ptMatch := ptRe.FindStringSubmatch(p.suffix); ptMatch != nil {
		return ptMatch[1]
	}

	// Check for Episode number
	if epMatch := epRe.FindStringSubmatch(p.suffix); epMatch != nil {
		return epMatch[1]
	}

	// Fallback to main episode number
	return p.episode
}

// appendGroup emits a compressed or single line for a group of parsed entries
func appendGroup(group []*ParsedLine, outputLines *[]string) {
	if len(group) == 0 {
		return
	}

	// Single line, nothing to compress
	if len(group) == 1 {
		*outputLines = append(*outputLines, group[0].original)
		return
	}

	first := group[0]
	last := group[len(group)-1]
	e1 := first.episode
	e2 := last.episode
	s1 := first.suffix

	// Extract episode/part numbers
	var e1Text, e2Text, p1Text, p2Text string

	if ep1Match := epRe.FindStringSubmatch(s1); ep1Match != nil {
		e1Text = ep1Match[1]
		if ep2Match := epRe.FindStringSubmatch(last.suffix); ep2Match != nil {
			e2Text = ep2Match[1]
			// Preserve padding
			if strings.HasPrefix(e1Text, "0") && len(e1Text) > 1 {
				num, _ := strconv.Atoi(e2Text)
				e2Text = fmt.Sprintf("%0*d", len(e1Text), num)
			}
		}
	}

	if pt1Match := ptRe.FindStringSubmatch(s1); pt1Match != nil {
		p1Text = pt1Match[1]
		if pt2Match := ptRe.FindStringSubmatch(last.suffix); pt2Match != nil {
			p2Text = pt2Match[1]
			// Preserve padding
			if strings.HasPrefix(p1Text, "0") && len(p1Text) > 1 {
				num, _ := strconv.Atoi(p2Text)
				p2Text = fmt.Sprintf("%0*d", len(p1Text), num)
			}
		}
	}

	// Replace Episode/Part sequences with appropriate ranges
	newSuffix := epPtRe.ReplaceAllStringFunc(s1, func(match string) string {
		parts := epPtRe.FindStringSubmatch(match)
		if len(parts) < 2 {
			return match
		}

		word := parts[1]
		wordLower := strings.ToLower(word)

		if wordLower == "episode" && e1Text != "" && e2Text != "" {
			return fmt.Sprintf("%s %s-%s", word, e1Text, e2Text)
		}
		if wordLower == "part" && p1Text != "" && p2Text != "" {
			return fmt.Sprintf("%s %s-%s", word, p1Text, p2Text)
		}
		return match
	})

	line := fmt.Sprintf("%s, S%sE%s-%s, %s", first.prefix, first.season, e1, e2, newSuffix)
	*outputLines = append(*outputLines, line)
}

// squishLines processes all normalized lines and groups/compresses consecutive entries
func squishLines(lines []string, progName string) []string {
	var outputLines []string
	var group []*ParsedLine

	for _, line := range lines {
		p := parseLine(line)
		if p != nil {
			if len(group) == 0 {
				// Always start a new group if one isn't active
				group = append(group, p)
			} else {
				lastInGroup := group[len(group)-1]
				if isSameArc(lastInGroup, p) {
					// It's the same show/season/arc
					if isConsecutiveEpisode(lastInGroup, p) {
						// It's consecutive, add it to the group
						group = append(group, p)
					} else {
						// GAP DETECTED - same show but not consecutive
						startNum := getBestWarningNum(lastInGroup)
						endNum := getBestWarningNum(p)

						fmt.Fprintf(os.Stderr, "%s: [%s] %s S%s: missing episodes between %s and %s\n",
							progName, yellowWarning, p.prefix, p.season, startNum, endNum)

						// Flush the old group
						appendGroup(group, &outputLines)

						// Start a new group with the current item
						group = []*ParsedLine{p}
					}
				} else {
					// It's a different show/season/arc - normal break
					appendGroup(group, &outputLines)
					group = []*ParsedLine{p}
				}
			}
		} else {
			// Not a parsable line (e.g., a header)
			appendGroup(group, &outputLines)
			group = nil

			// Fix missing space after comma in non-parsable lines
			if strings.Contains(line, ",") && !strings.Contains(line, ", ") {
				line = strings.ReplaceAll(line, ",", ", ")
			}

			outputLines = append(outputLines, line)
		}
	}

	appendGroup(group, &outputLines)
	return outputLines
}

// readLines reads all lines from a reader
func readLines(reader io.Reader) ([]string, error) {
	var lines []string
	scanner := bufio.NewScanner(reader)
	for scanner.Scan() {
		line := normalizeQuotedLine(scanner.Text())
		lines = append(lines, line)
	}
	return lines, scanner.Err()
}

// isTerminal checks if a file descriptor is a terminal
func isTerminal(file *os.File) bool {
	stat, err := file.Stat()
	if err != nil {
		return false
	}
	return (stat.Mode() & os.ModeCharDevice) != 0
}

// printHelp prints the help message
func printHelp(progName string) {
	fmt.Printf(`Reads show episode listings from stdin or a file and compresses consecutive episode sequences.

For example:
  Bannan, S08E01, Episode 01
  Bannan, S08E02, Episode 02
becomes:
  Bannan, S08E01-02, Episode 01-02

Usage:
  %s [input_file]
  %s -h, --help

Arguments:
  input_file    Optional input filename (reads from stdin if omitted)

Options:
  -h, --help    Show this help message and exit

Examples:
  ./newEpisodes.sh | ./%s > newEpisodes.txt
  ./%s episodes.txt > newEpisodes.txt
`, progName, progName, progName, progName)
}

func main() {
	progName := filepath.Base(os.Args[0])

	// Parse arguments
	args := os.Args[1:]

	// Check for help flags
	if len(args) > 0 {
		for _, arg := range args {
			if arg == "-h" || arg == "--help" {
				printHelp(progName)
				os.Exit(0)
			}
		}
	}

	// Check for unknown flags (starting with -)
	for _, arg := range args {
		if strings.HasPrefix(arg, "-") {
			fmt.Fprintf(os.Stderr, "%s: [%s] Unrecognized argument '%s'\n", progName, redError, arg)
			os.Exit(2)
		}
	}

	var reader io.Reader

	if len(args) == 0 {
		// No arguments, check if stdin is a terminal
		if isTerminal(os.Stdin) {
			fmt.Fprintf(os.Stderr, "%s: [%s] No input file or piped input\n", progName, redError)
			fmt.Fprintf(os.Stderr, "Usage: ./%s <file> or use a pipe, e.g.:\n", progName)
			fmt.Fprintf(os.Stderr, "  ./%s episodes.txt\n", progName)
			fmt.Fprintf(os.Stderr, "  ./newEpisodes.sh | ./%s\n", progName)
			os.Exit(2)
		}
		reader = os.Stdin
	} else if len(args) == 1 {
		// One argument - treat as filename
		file, err := os.Open(args[0])
		if err != nil {
			if os.IsNotExist(err) {
				fmt.Fprintf(os.Stderr, "%s: [%s] File '%s' does not exist.\n", progName, redError, args[0])
				os.Exit(1)
			}
			fmt.Fprintf(os.Stderr, "%s: [%s] Error opening file: %v\n", progName, redError, err)
			os.Exit(1)
		}
		defer file.Close() // nolint:errcheck
		reader = file
	} else {
		fmt.Fprintf(os.Stderr, "%s: [%s] Too many arguments\n", progName, redError)
		os.Exit(2)
	}

	// Read and process lines
	lines, err := readLines(reader)
	if err != nil {
		fmt.Fprintf(os.Stderr, "%s: [%s] Error reading input: %v\n", progName, redError, err)
		os.Exit(1)
	}

	squished := squishLines(lines, progName)

	// Write output
	for _, line := range squished {
		fmt.Println(line)
	}
}

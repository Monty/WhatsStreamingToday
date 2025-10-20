#!/usr/bin/env python3
import sys
import re
import argparse
from typing import Optional

# Grab name of running program from argv
prog = sys.argv[0].split("/")[-1]

# ANSI color code for warning
YELLOW_WARNING = "\033[33mWarning\033[0m"
RED_ERROR = "\033[31mError\033[0m"

# Regex patterns to parse: prefix, season, episode, suffix
PAT = re.compile(r"^(.*),\s*S(\d+)E(\d+),\s*(.*)$", re.I)
EP_RE = re.compile(r"(?i)\bEpisode\s*(\d{1,4})")
PT_RE = re.compile(r"(?i)\bPart\s*(\d{1,4})")
EP_PT = re.compile(r"(?i)\b(Episode|Part)\s*\d{1,4}")


# Helper functions
def normalize_quotes(s: str) -> str:
    # If a line starts with '"' and ends with '"""', remove all '"'
    if s.startswith('"') and s.rstrip().endswith('"""'):
        return s.replace('"', "")
    return s


def base_suffix(s: str) -> str:
    # Strip Episode/Part numbers for logical grouping comparison
    t = re.sub(r"(?i)\b(?:Episode|Part)\s*\d{1,4}", "", s)
    t = re.sub(r"\s+", " ", t)
    return re.sub(r"^[\s:,\-]+|[\s:,\-]+$", "", t).lower()


def parse(line: str) -> Optional[dict[str, str]]:
    # Parse a line into prefix, season, episode, suffix dict
    m = PAT.match(line)
    if not m:
        return None
    return {"pre": m[1], "S": m[2], "E": m[3], "suf": m[4]}


def same(a: Optional[dict[str, str]], b: Optional[dict[str, str]]) -> bool:
    # Determine if two lines belong to the same show/season/arc
    return (
        a
        and b
        and a["pre"] == b["pre"]
        and a["S"] == b["S"]
        and base_suffix(a["suf"]) == base_suffix(b["suf"])
    )


# Checks if all numbers (main E, Episode, Part) are sequential.
def is_consecutive(a: dict[str, str], b: dict[str, str]) -> bool:
    """Determine if line 'b' is a direct sequential episode to line 'a'."""
    # 1. Check main episode number
    if int(b["E"]) != int(a["E"]) + 1:
        return False

    # 2. Check for 'Episode N' in title
    a_ep_m = EP_RE.search(a["suf"])
    b_ep_m = EP_RE.search(b["suf"])

    if a_ep_m and b_ep_m:
        # Both have "Episode N", check if they are consecutive
        if int(b_ep_m.group(1)) != int(a_ep_m.group(1)) + 1:
            return False
    elif a_ep_m or b_ep_m:
        # One has "Episode N" and one doesn't; they are not sequential
        return False

    # 3. Check for 'Part N' in title
    a_pt_m = PT_RE.search(a["suf"])
    b_pt_m = PT_RE.search(b["suf"])

    if a_pt_m and b_pt_m:
        # Both have "Part N", check if they are consecutive
        if int(b_pt_m.group(1)) != int(a_pt_m.group(1)) + 1:
            return False
    elif a_pt_m or b_pt_m:
        # One has "Part N" and  doesn't; they are not sequential
        return False

    # All checks passed
    return True


# Core function: Emit a compressed or single line for a group of parsed entries
def append_group(group: list[dict[str, str]], output_lines: list[str]) -> None:
    if not group:
        return

    # Single line, nothing to compress
    if len(group) == 1:
        e = group[0]
        output_lines.append(f"{e['pre']}, S{e['S']}E{e['E']}, {e['suf']}")
        return

    # Multiple consecutive entries → compress into one line
    first, last = group[0], group[-1]
    e1, e2 = first["E"], last["E"]
    s1, s2 = first["suf"], last["suf"]

    # Extract episode/part numbers
    ep1_m = EP_RE.search(s1)
    ep2_m = EP_RE.search(s2)
    pt1_m = PT_RE.search(s1)
    pt2_m = PT_RE.search(s2)

    # Keep numbers exactly as they appear
    e1_text = ep1_m.group(1) if ep1_m else first["E"]
    e2_text = ep2_m.group(1) if ep2_m else last["E"]
    p1_text = pt1_m.group(1) if pt1_m else None
    p2_text = pt2_m.group(1) if pt2_m else None

    # Replace Episode/Part occurrences with appropriate ranges
    def repl(m):
        word = m[1]
        if word.lower() == "episode":
            return f"{word} {e1_text}-{e2_text}"
        if word.lower() == "part" and p1_text and p2_text:
            return f"{word} {p1_text}-{p2_text}"
        return m[0]

    suf = EP_PT.sub(repl, s1)
    output_lines.append(f"{first['pre']}, S{first['S']}E{e1}-{e2}, {suf}")


# --- NEW HELPER FUNCTION ---
def _get_title_num(p: dict[str, str]) -> str:
    """Helper to get title number (Part or Ep) or fall back to main E num."""
    # Check for Part number
    pt_m = PT_RE.search(p["suf"])
    if pt_m:
        return pt_m.group(1)

    # Check for Episode number
    ep_m = EP_RE.search(p["suf"])
    if ep_m:
        return ep_m.group(1)

    # Fallback to main episode number
    return p["E"]


# --- MODIFIED FUNCTION ---
# Process all lines and group/compress consecutive entries
def squish_lines(lines: list[str]) -> list[str]:
    output_lines, group = [], []
    for line in lines:
        p = parse(line)
        if p:
            if not group:
                # Always start a new group if one isn't active
                group.append(p)
            else:
                last_in_group = group[-1]
                if same(last_in_group, p):
                    # It's the same show/season/arc.
                    if is_consecutive(last_in_group, p):
                        # It's consecutive. Add it to the group.
                        group.append(p)
                    else:
                        # --- GAP DETECTED ---
                        # It's the same show, but not consecutive.

                        # 1. Emit warning to stderr
                        start_num = _get_title_num(last_in_group)
                        end_num = _get_title_num(p)

                        sys.stderr.write(
                            f"{prog}: [{YELLOW_WARNING}] "
                            f"{p['pre']} S{p['S']}: missing episodes between "
                            f"{start_num} and {end_num}\n"
                        )

                        # 2. Flush the old group
                        append_group(group, output_lines)

                        # 3. Start a new group with the current item
                        group = [p]
                else:
                    # It's a different show/season/arc. This is a normal break.
                    append_group(group, output_lines)
                    group = [p]
        else:
            # Not a parsable line (e.g., a header)
            # Flush the last group
            append_group(group, output_lines)
            group = []
            # and print the non-parsable line
            output_lines.append(line)

    append_group(group, output_lines)  # Flush the last group
    return output_lines


# Provide description and examples for -h or --help
def build_parser() -> argparse.ArgumentParser:
    description = (
        "Reads show episode listings from stdin or a file "
        "and compresses consecutive episode sequences.\n\n"
        "For example:\n"
        "  Bannan, S08E01, Episode 01\n"
        "  Bannan, S08E02, Episode 02\n"
        "becomes:\n"
        "  Bannan, S08E01-02, Episode 01-02"
    )

    epilog = (
        "Examples:\n"
        f"  ./newEpisodes.sh | ./{prog} > newEpisodes.txt\n"
        f"  ./{prog} episodes.txt > newEpisodes.txt"
    )

    parser = argparse.ArgumentParser(
        prog=prog,
        description=description,
        epilog=epilog,
        formatter_class=argparse.RawTextHelpFormatter,
    )

    parser.add_argument(
        "input",
        nargs="?",
        help="Optional input filename (reads from stdin if omitted)",
    )

    return parser


# Entry point: read from file argument or stdin, write to stdout
def main() -> None:
    parser = build_parser()
    args, unknown = parser.parse_known_args()

    # Handle unknown arguments
    if unknown:
        for arg in unknown:
            sys.stderr.write(f"{prog}: [{RED_ERROR}] Unrecognized argument '{arg}'\n")
        sys.exit(2)

    # Error if no input file or piped input
    if not args.input and sys.stdin.isatty():
        sys.stderr.write(
            f"{prog}: [{RED_ERROR}] No input file or piped input\n"
            f"Usage: ./{prog} <file> or use a pipe, e.g.:\n"
            f"  ./{prog} episodes.txt\n"
            f"  ./newEpisodes.sh | ./{prog}\n"
        )
        sys.exit(2)

    # Read input lines
    lines_to_process = []
    if args.input:
        try:
            with open(args.input, "r") as f:
                lines_to_process = [normalize_quotes(line.rstrip("\n")) for line in f]
        except FileNotFoundError as e:
            sys.stderr.write(
                f"{prog}: [{RED_ERROR}] File '{e.filename}' does not exist.\n"
            )
            sys.exit(1)
    else:
        lines_to_process = [normalize_quotes(line.rstrip("\n")) for line in sys.stdin]

    squished_lines = squish_lines(lines_to_process)
    print("\n".join(squished_lines))


if __name__ == "__main__":
    main()

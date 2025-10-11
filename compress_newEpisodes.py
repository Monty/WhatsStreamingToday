#!/usr/bin/env python3

# Squish output of newEpisodes.sh to reduce numeric episode sequences
# i.e.
#   Bannan, S08E01, Episode 01
#   Bannan, S08E02, Episode 02
# becomes
#   Bannan, S08E01-02, Episode 01-02

# Usage: ./newEpisodes.sh | ./compress_newEpisodes.py
#        ./compress_newEpisodes.py <[input file]

import sys
import re

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
    # Strip Episode/Part numbers for logical grouping comparison.
    t = re.sub(r"(?i)\b(?:Episode|Part)\s*\d{1,4}", "", s)
    t = re.sub(r"\s+", " ", t)
    return re.sub(r"^[\s:,\-]+|[\s:,\-]+$", "", t).lower()


def parse(line: str):
    # Parse a line into prefix, season, episode, suffix dict.
    m = PAT.match(line)
    if not m:
        return None
    return {"pre": m[1], "S": m[2], "E": m[3], "suf": m[4]}


def same(a, b) -> bool:
    # Determine if two lines belong to the same show/season/arc.
    return (
        a
        and b
        and a["pre"] == b["pre"]
        and a["S"] == b["S"]
        and base_suffix(a["suf"]) == base_suffix(b["suf"])
    )


# Core function: Emit a compressed or single line for a group of parsed entries.
def flush(group, out):
    if not group:
        return

    # Single line, nothing to compress
    if len(group) == 1:
        e = group[0]
        out.append(f"{e['pre']}, S{e['S']}E{e['E']}, {e['suf']}")
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
    out.append(f"{first['pre']}, S{first['S']}E{e1}-{e2}, {suf}")


# Process all lines and group/compress consecutive entries.
def squish_lines(lines):
    out, group = [], []
    for line in lines:
        p = parse(line)
        if p and (not group or same(group[-1], p)):
            group.append(p)
        else:
            flush(group, out)
            group = [p] if p else []
            if not p:
                out.append(line)
    flush(group, out)
    return out


# Entry point: read from stdin, write to stdout.
def main():
    lines = [normalize_quotes(line.rstrip("\n")) for line in sys.stdin]
    output_lines = squish_lines(lines)
    sys.stdout.write("\n".join(output_lines) + "\n")


if __name__ == "__main__":
    main()

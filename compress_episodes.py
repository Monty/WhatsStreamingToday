#!/usr/bin/env python3

# Squish output of newEpisodes.sh to reduce numeric episode sequences
# i.e.
#   Bannan, S08E01, Episode 01
#   Bannan, S08E02, Episode 02
# becomes
#   Bannan, S08E01-02, Episode 01-02

import sys
import re
from typing import List, Optional, Dict


# If a line starts with '"' and ends with '"""', remove all double quotes.
def normalize_quotes(line: str) -> str:
    if line.startswith('"') and line.rstrip().endswith('"""'):
        return line.replace('"', "")
    return line


# Pattern to parse: prefix, season, episode, suffix
PATTERN = re.compile(r"^(.*),\s*S(\d+)E(\d+),\s*(.*)$", re.IGNORECASE)
EP_PART_RE = re.compile(r"(?i)\b(Episode|Part)\b\s*(\d{1,4})")
PART_RE = re.compile(r"(?i)\bPart\b\s*(\d{1,4})")
EPISODE_RE = re.compile(r"(?i)\bEpisode\b\s*(\d{1,4})")


# Parse a line into prefix, season, episode, suffix dict.
def parse_line(line: str) -> Optional[Dict[str, str]]:
    m = PATTERN.match(line)
    if not m:
        return None
    return {
        "prefix": m.group(1),
        "season": m.group(2),
        "episode": m.group(3),
        "suffix": m.group(4),
    }


# Strip Episode/Part numbers for logical grouping comparison.
def suffix_base(suffix: str) -> str:
    cleaned = re.sub(r"(?i)\b(?:Episode|Part)\b\s*\d{1,4}", "", suffix)
    cleaned = re.sub(r"\s+", " ", cleaned).strip()
    cleaned = re.sub(r"^[\s:,\-]+|[\s:,\-]+$", "", cleaned)
    return cleaned.lower()


# Determine if two lines belong to the same show/season/arc.
def same_series(a: Dict[str, str], b: Dict[str, str]) -> bool:
    if not a or not b:
        return False
    return (
        a["prefix"] == b["prefix"]
        and a["season"] == b["season"]
        and suffix_base(a["suffix"]) == suffix_base(b["suffix"])
    )


# Emit a compressed or single line for a group of parsed entries.
def flush_range(group: List[Dict[str, str]], out: List[str]) -> None:
    if not group:
        return

    # Single line, nothing to compress, print as-is
    if len(group) == 1:
        e = group[0]
        out.append(f"{e['prefix']}, S{e['season']}E{e['episode']}, {e['suffix']}")
        return

    first, last = group[0], group[-1]
    prefix, season = first["prefix"], first["season"]
    e1, e2 = first["episode"], last["episode"]
    suffix_first = first["suffix"]
    suffix_last = last["suffix"]

    # Extract episode/part numbers to determine padding
    e1_match = EPISODE_RE.search(suffix_first)
    e2_match = EPISODE_RE.search(suffix_last)
    p1_match = PART_RE.search(suffix_first)
    p2_match = PART_RE.search(suffix_last)

    # Determine widths for episode and part numbers separately
    ep_pad_first = len(e1_match.group(1)) if e1_match else len(e1)
    ep_pad_last = len(e2_match.group(1)) if e2_match else len(e2)
    part_pad_first = len(p1_match.group(1)) if p1_match else 0
    part_pad_last = len(p2_match.group(1)) if p2_match else 0

    # Format SxxEyyy field keeping its own padding
    e1_field = str(int(e1)).zfill(len(e1))
    e2_field = str(int(e2)).zfill(len(e2))

    # Format Episode range preserving its padding
    e1_ep = (
        str(int(e1_match.group(1))).zfill(ep_pad_first) if e1_match else str(int(e1))
    )
    e2_ep = str(int(e2_match.group(1))).zfill(ep_pad_last) if e2_match else str(int(e2))

    # Format Part range preserving its own padding
    if p1_match and p2_match:
        p1_val = str(int(p1_match.group(1))).zfill(part_pad_first)
        p2_val = str(int(p2_match.group(1))).zfill(part_pad_last)
    else:
        p1_val = p2_val = None

    # Replace Episode/Part occurrences with appropriate ranges
    def repl(m: re.Match) -> str:
        word = m.group(1)
        if word.lower() == "episode":
            return f"{word} {e1_ep}-{e2_ep}"
        elif word.lower() == "part" and p1_val and p2_val:
            return f"{word} {p1_val}-{p2_val}"
        return m.group(0)

    new_suffix = EP_PART_RE.sub(repl, suffix_first)
    out.append(f"{prefix}, S{season}E{e1_field}-{e2_field}, {new_suffix}")


# Process all lines and group/compress consecutive entries.
def process_lines(lines: List[str]) -> List[str]:
    out: List[str] = []
    group: List[Dict[str, str]] = []
    for raw in lines:
        line = normalize_quotes(raw.rstrip("\n"))
        parsed = parse_line(line)
        if parsed and (not group or same_series(group[-1], parsed)):
            group.append(parsed)
        else:
            flush_range(group, out)
            group = [parsed] if parsed else []
            if not parsed:
                out.append(line)
    flush_range(group, out)
    return out


# Entry point: read from stdin or a file, write to stdout.
def main(argv: List[str]) -> int:
    if len(argv) >= 2:
        with open(argv[1], "r", encoding="utf-8") as f:
            lines = [ln.rstrip("\n") for ln in f]
    else:
        lines = [ln.rstrip("\n") for ln in sys.stdin]

    out_lines = process_lines(lines)
    sys.stdout.write("\n".join(out_lines) + "\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))

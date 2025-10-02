#!/usr/bin/env python3

# Squish output of newEpisodes.sh to reduce numeric episode sequences
# i.e.
#   Bannan, S08E01, Episode 01
#   Bannan, S08E02, Episode 02
# becomes
#   Bannan, S08E01-02, Episode 01-02

import re
import sys
import argparse
from pathlib import Path


def compress_file_lines(lines, output_path):
    # lines should be a list of strings
    # rest of function remains the same, replacing lines read from file with parameter lines

    # Match "Episode N" or "Part N" at the end of the last comma-separated field
    trailing_pattern = re.compile(r"^(.*\b(?:Episode|Part))\s+(\d+)\s*$", re.IGNORECASE)
    # Match the SxxEyyy code in the middle field
    code_pattern = re.compile(r"^(S\d+E)(\d+)$", re.IGNORECASE)

    out_lines = []
    i = 0

    while i < len(lines):
        line = lines[i]
        parts = [p.strip() for p in line.split(",", 2)]
        if len(parts) == 3:
            show, code, trailer = parts
            m_trail = trailing_pattern.match(trailer)
            m_code = code_pattern.match(code)
            if m_trail and m_code:
                base_trailer = m_trail.group(1)
                start_num = int(m_trail.group(2))
                start_str = m_trail.group(2)
                start_width = len(start_str)

                code_prefix = m_code.group(1)
                code_num = int(m_code.group(2))
                code_str = m_code.group(2)
                code_width = len(code_str)

                seq_lines = [line]
                j = i + 1
                last_num = start_num
                last_str = start_str
                last_width = start_width
                last_code = code_num
                last_code_str = code_str
                last_code_width = code_width

                while j < len(lines):
                    next_parts = [p.strip() for p in lines[j].split(",", 2)]
                    if len(next_parts) == 3:
                        _, code2, trailer2 = next_parts
                        m_trail2 = trailing_pattern.match(trailer2)
                        m_code2 = code_pattern.match(code2)
                        if (
                            m_trail2
                            and m_code2
                            and m_trail2.group(1) == base_trailer
                            and m_code2.group(1) == code_prefix
                        ):
                            num2 = int(m_trail2.group(2))
                            code_num2 = int(m_code2.group(2))
                            if num2 == last_num + 1 and code_num2 == last_code + 1:
                                seq_lines.append(lines[j])
                                last_num = num2
                                last_str = m_trail2.group(2)
                                last_width = len(last_str)
                                last_code = code_num2
                                last_code_str = m_code2.group(2)
                                last_code_width = len(last_code_str)
                                j += 1
                                continue
                    break
                if len(seq_lines) > 1:
                    # Build compressed episode code range (preserve padding)
                    if last_code == code_num:
                        code_range = f"{code_prefix}{code_str}"
                    else:
                        code_range = f"{code_prefix}{code_str}-{last_code_str}"
                    # Build compressed trailer range (preserve padding)
                    if last_num == start_num:
                        new_trailer = f"{base_trailer} {start_str}"
                    else:
                        new_trailer = f"{base_trailer} {start_str}-{last_str}"
                    new_line = f"{show}, {code_range}, {new_trailer}"
                    out_lines.append(new_line)
                    i = j
                    continue
        out_lines.append(line)
        i += 1

    Path(output_path).write_text("\n".join(out_lines))
    print(f"Compressed file written to {output_path}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Compress episode codes with padded ranges"
    )
    parser.add_argument(
        "input",
        nargs="?",
        type=argparse.FileType("r"),
        default=sys.stdin,
        help="Input file (default: stdin)",
    )
    parser.add_argument("output", type=str, help="Output file path")
    args = parser.parse_args()

    # Read all lines from input (file or stdin)
    lines = [line.rstrip("\n") for line in args.input]

    compress_file_lines(lines, args.output)

#!/usr/bin/env python3

# Squish output of newEpisodes.sh to reduce numeric episode sequences
# i.e.
#   Bannan, S08E01, Episode 01
#   Bannan, S08E02, Episode 02
# becomes
#   Bannan, S08E01, Episode 01-02

import re
from pathlib import Path


def compress_file(input_path, output_path):
    lines = Path(input_path).read_text().splitlines()

    # Matches any text ending with "Episode N" or "Part N"
    pattern = re.compile(r"^(.*\b(?:Episode|Part))\s+(\d+)\s*$", re.IGNORECASE)

    out_lines = []
    i = 0

    while i < len(lines):
        line = lines[i]
        if "," in line:
            left, right = line.rsplit(",", 1)
            right = right.strip()
            m = pattern.match(right)
            if m:
                base = m.group(1)
                start_num = int(m.group(2))
                start_width = len(m.group(2))
                seq_lines = [line]
                j = i + 1
                last_num = start_num
                last_width = start_width
                while j < len(lines):
                    next_line = lines[j]
                    if "," in next_line:
                        l2, r2 = next_line.rsplit(",", 1)
                        r2 = r2.strip()
                        m2 = pattern.match(r2)
                        if m2 and m2.group(1) == base:
                            num2 = int(m2.group(2))
                            if num2 == last_num + 1:
                                seq_lines.append(next_line)
                                last_num = num2
                                last_width = len(m2.group(2))
                                j += 1
                                continue
                    break
                if len(seq_lines) > 1:
                    # Build compressed line
                    new_trailer = f"{base} {str(start_num).zfill(start_width)}-{str(last_num).zfill(last_width)}"
                    new_line = f"{left.strip()}, {new_trailer}"
                    out_lines.append(new_line)
                    i = j
                    continue
        out_lines.append(line)
        i += 1

    Path(output_path).write_text("\n".join(out_lines))
    print(f"Compressed file written to {output_path}")


if __name__ == "__main__":
    import sys

    if len(sys.argv) != 3:
        print("Usage: ./compress_episodes.py input.txt output.txt")
    else:
        compress_file(sys.argv[1], sys.argv[2])

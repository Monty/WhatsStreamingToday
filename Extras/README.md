## EXTRAS

This directory contains Rust, Go, and Swift source code equivalents
of `compress_newEpisodes.py` which you can study or compile.

It also contains a worst-case test file and the expected results
from compressing it.

Swift is unique in that you can execute the source code directly
like the Python version, or you can compile it into a binary
executable that runs significantly faster.

Rust, Go and compiled Swift are faster, but Python still wins for
convenience — it handles a 233 KB, 5,944-line file in under 45 ms,
and there’s no compilation step to worry about.

```
# Run benchmarks
$ hyperfine --warmup 10 \
    './compress_newEpisodes_rust squishTest.txt >/dev/null' \
    './compress_newEpisodes_go squishTest.txt >/dev/null' \
    './compress_newEpisodes_swift squishTest.txt >/dev/null' \
    './compress_newEpisodes.py squishTest.txt >/dev/null' \
    './compress_newEpisodes.swift squishTest.txt >/dev/null'

Benchmark 1: ./compress_newEpisodes_rust squishTest.txt >/dev/null
  Time (mean ± σ):      10.0 ms ±   0.3 ms    [User: 8.2 ms, System: 1.6 ms]
  Range (min … max):     9.6 ms …  11.0 ms    233 runs

Benchmark 2: ./compress_newEpisodes_go squishTest.txt >/dev/null
  Time (mean ± σ):      14.1 ms ±   0.2 ms    [User: 12.1 ms, System: 2.1 ms]
  Range (min … max):    13.6 ms …  14.9 ms    181 runs

Benchmark 3: ./compress_newEpisodes_swift squishTest.txt >/dev/null
  Time (mean ± σ):      38.3 ms ±   0.5 ms    [User: 36.4 ms, System: 1.5 ms]
  Range (min … max):    37.4 ms …  40.6 ms    73 runs

Benchmark 4: ./compress_newEpisodes.py squishTest.txt >/dev/null
  Time (mean ± σ):      44.0 ms ±   0.4 ms    [User: 34.7 ms, System: 6.9 ms]
  Range (min … max):    42.7 ms …  44.6 ms    63 runs

Benchmark 5: ./compress_newEpisodes.swift squishTest.txt >/dev/null
  Time (mean ± σ):     364.4 ms ±   1.0 ms    [User: 311.3 ms, System: 34.6 ms]
  Range (min … max):   362.3 ms … 365.5 ms    10 runs

Summary
  ./compress_newEpisodes_rust squishTest.txt >/dev/null ran
    1.41 ± 0.05 times faster than ./compress_newEpisodes_go squishTest.txt >/dev/null
    3.83 ± 0.13 times faster than ./compress_newEpisodes_swift squishTest.txt >/dev/null
    4.40 ± 0.14 times faster than ./compress_newEpisodes.py squishTest.txt >/dev/null
   36.43 ± 1.10 times faster than ./compress_newEpisodes.swift squishTest.txt >/dev/null
```

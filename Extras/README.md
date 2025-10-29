## EXTRAS

This directory contains Rust and Go source code equivalents of
`compress_newEpisodes.py` which you can study or compile.

It also contains a worst-case test file and the expected results
from compressing it.

Although Rust and Go are faster than Python, I'd stick with Python
as it takes less than 45 ms to process a 233k file with 5840 line,
and skips the setup required for compilation.


```
$ hyperfine --warmup 10 \
    './compress_newEpisodes.py squishTest.txt >/dev/null' \
    './compress_newEpisodes_rust squishTest.txt >/dev/null' \
    './compress_newEpisodes_go squishTest.txt >/dev/null'

Benchmark 1: ./compress_newEpisodes.py squishTest.txt >/dev/null
  Time (mean ± σ):      43.0 ms ±   0.5 ms    [User: 34.6 ms, System: 6.5 ms]
  Range (min … max):    41.6 ms …  44.1 ms    65 runs

Benchmark 2: ./compress_newEpisodes_rust squishTest.txt >/dev/null
  Time (mean ± σ):       9.7 ms ±   0.2 ms    [User: 8.1 ms, System: 1.4 ms]
  Range (min … max):     9.3 ms …  10.4 ms    244 runs

Benchmark 3: ./compress_newEpisodes_go squishTest.txt >/dev/null
  Time (mean ± σ):      13.7 ms ±   0.2 ms    [User: 11.9 ms, System: 2.0 ms]
  Range (min … max):    13.3 ms …  14.4 ms    178 runs

Summary
  ./compress_newEpisodes_rust squishTest.txt >/dev/null ran
    1.42 ± 0.04 times faster than ./compress_newEpisodes_go squishTest.txt >/dev/null
    4.45 ± 0.11 times faster than ./compress_newEpisodes.py squishTest.txt >/dev/null
```

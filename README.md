# Sloth

Aimed to be a faster pandas, by being a *thin* wrapper for numpy. Keep in mind that this is not a replacement for pandas as only a few features are supported. If you want more features code them up yourself.

Currently only indexing and resampling is supported.

Benchmarks between Sloth and Pandas coming soon.

This program is fast like [Flash](https://www.youtube.com/watch?v=dM-li2Cn5Pw).

Benchmarks
| CMD | Sloth | Pandas |
| --- | ----- | ------ |
| iloc[0] | 2.58 µs ± 298 ns | 168 µs ± 18.9 µs |

Who's the sloth now?

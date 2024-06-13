# Sloth
(named sloth becuase koala was taken)

Aimed to be a faster pandas, by being a *thin* wrapper for numpy. Keep in mind that this is not a replacement for pandas as only a few features are supported. If you want more features code them up yourself.

Currently only indexing and resampling is supported.

More detailed and accurate benchmarks between Sloth and Pandas coming soon.

This program is fast like [Flash](https://www.youtube.com/watch?v=dM-li2Cn5Pw).

## Benchmarks

| CMD | Sloth | Pandas |
| --- | ----- | ------ |
| iloc[0] | 2.58 µs ± 298 ns | 168 µs ± 18.9 µs |
| iloc[5:300000] | 3.48 µs ± 251 ns | 210 µs ± 15.1 µs |

![benchmark_results](https://github.com/evanwporter/Sloth/assets/115374841/50b6fbfd-8f40-4a08-868f-6763c9ef7a0a)

Still not fast enough? Try [Cloth](https://github.com/evanwporter/Sloth/tree/experimental)!

## Where

| **Link**  | **URL**                                    |
|-----------|---------------------------------------------|
| docs      | [https://evanwporter.github.io/Sloth](https://evanwporter.github.io/Sloth)   |
| code      | [https://github.com/evanwporter/Sloth](https://github.com/evanwporter/Sloth) |
| cloth     | [https://github.com/evanwporter/Sloth/tree/experimental](https://github.com/evanwporter/Sloth/tree/experimental) |


.. Sphinx Example documentation master file, created by
   sphinx-quickstart on Sun Dec  4 18:31:33 2016.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

Sloth
=====

.. toctree::
   :maxdepth: 1

   frame/frame
   index/index
   indexer/indexer
   resample/resampler
   rolling/rolling    


(named sloth because koala was taken)

Aimed to be a faster pandas, by being a *thin* wrapper for numpy. Keep in mind that this is not a replacement for pandas as only a few features are supported. If you want more features code them up yourself.

Currently only indexing and resampling is supported.

More detailed and accurate benchmarks between Sloth and Pandas coming soon.

This program is fast like `Flash <https://www.youtube.com/watch?v=dM-li2Cn5Pw>`_.

Benchmarks
----------

.. list-table::
   :header-rows: 1

   * - CMD
     - Sloth
     - Pandas
   * - ``iloc[0]``
     - 2.58 µs ± 298 ns
     - 168 µs ± 18.9 µs
   * - ``iloc[5:300000]``
     - 3.48 µs ± 251 ns
     - 210 µs ± 15.1 µs

.. image:: https://github.com/evanwporter/Sloth/assets/115374841/50b6fbfd-8f40-4a08-868f-6763c9ef7a0a
   :alt: benchmark_results

Where
-----

.. list-table::
   :header-rows: 1

   * - **Link**
     - **URL**
   * - docs
     - `https://evanwporter.github.io/Sloth <https://evanwporter.github.io/Sloth>`_
   * - code
     - `https://github.com/evanwporter/Sloth <https://github.com/evanwporter/Sloth>`_



Index
=====

* :ref:`genindex`
* :ref:`modindex`
* :ref:`search`


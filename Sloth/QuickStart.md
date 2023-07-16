Start off by creating by compiling the files using the code:

`python setup.py build_ext --inplace`

Once that's done, import the files using `from frame import DataFrame`. I'm working on creating a package.

Then create a pandas dataframe and initialize the Sloth DataFrame using `DataFrame.from_pandas()`.

# Motivation
The main reason why someone would use a dataframe instead of a 2d numpy array is because a dataframe allows for indexing (not to mention the many other features that come with having an index (ie: resampling). The problem with pandas is that is is incredibly slow at most things but especially indexing. If pandas is a one size fits all then sloth is a one size. Pandas has tons of features that I have no intention of implementing, simply becuase I do not need these things. If you want to implement these [be my guest](https://github.com/amuon/Sloth/pulls).

# How it works
I'm pretty bad at documenting my code so I wrote this.

## Indexing

When given a index, columns and values:
	Index: [A, B, C, D, E...Z]
	Columns: [A, B, C, D, E...Z]
	Values: 26x26 numpy array

The output dataframe looks like this:
|   | A | B | C | D |...| Z |
|---|---|---|---|---|---|---|
| A |   |   |   |   |   |   |
| B |   |   |   |   |   |   |
| C |   |   |   |   |   |   |
| D |   |   |   |   |   |   |
|...|   |   |   |   |   |   |
| Z |   |   |   |   |   |   |

We'll call this the example dataframe.

How it works is that the index and the location of that index are mapped onto a [hashmap](https://github.com/realead/cykhash) (`dict` is a hashmap) in the form (index, location). Thus the index of the example dataframe would look like this:
  
	{A: 0, B: 1, C: 2, D: 3 ... Z: 25}

The code used to generate this hashmap is roughly equivalent to:

	dict(zip(index, itertools.count()))
 
where index is the user given array of index values.
 
When the method `loc[A]` is called on the dataframe, the dataframe hashes `A` (`index[A]` where `index` is a `dict`) to get the row location of `A` which is in this case 0. It then takes this row location and passes it to values (a 2d numpy array): `values[0]`. Basically the operation under the hood looks like `values[index[A]]`. This returns the row in the numpy array, and then converts it to a `Series` object. 

Slicing works in a similar way. Given the command `loc[A:D]`, the example dataframe hashes A and D into the index (returns `0` and `3`) and calls values[0:3]. Again the operation under the hood looks like `values[index[A]: index[D]]`. This operation would return a `DataFrame` object.

The main bottleneck in the program is that the entire index must be hashed to a range of numbers at the program start. There are several possible solutions as outlined below.

(1)

Operations like loc[B:D] means that a new hashmap must be created for values B through D. While this isn't as much a problem for small indexes like this one it gets to be a problem when you get into tens of thousands of rows. The solution is to create a new hashmap every time the dataframe is indexed, rather simply to keep track of the frontal displacement (FD) and back displacement (BD). When a dataframe is initialized it sets `FD` to 0 and `BD` to the length of the index. When an operation like loc[B:Y] is done, a copy of the original dataframe is created and the FD is changed to 1, and the BD is changed to 24. Nothing else is changed, meaning the index, the columns and the values all remain the same.

Now when one performs an operation like iloc[0:2] the dataframe adds the FD to `0` and to `2` to get the index positions (`1` and `3`) in the row. When one wants to access the values (for example to perform some computation or to convert to pandas), `values[FD: BD]` is returned. While the BD is not currently used at this moment it will be used in the feauture so that negative indexing can be done.

(2)

**NOT YET IMPLEMENTED**

The creation of PeriodIndex which takes parameters `interval` and `start`. Given an index that increases continuosly at a predefined interval. Given query the index location can be found using the formula `((query - start) / interval)`.

## Resampling

Uses [`np.searchsorted`](https://numpy.org/doc/stable/reference/generated/numpy.searchsorted.html) to find the correct index.

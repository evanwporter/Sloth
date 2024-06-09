# cython: profile=True

cimport numpy as np
import numpy as np
from .indexer cimport IntegerLocation, Location, iAT
from .index cimport DateTimeIndex, _Index, ObjectIndex, RangeIndex
cimport cython

import logging

from .resample cimport Resampler
from .rolling cimport Rolling

import pandas as pd


cdef class Frame:
    """
    Basic Frame
    
    Parameters
    ----------
    values : np.ndarray
        Data that is to be represented by the DataFrame. The dimensions 
        of "values" must be equal to len(columns) x len(index)
    index : array-like
        Index that of values. len(index) must be equal to values.shape[1]
    """
    def __init__(self, np.ndarray values, index=None, index_type=None):
        self.values_ = values.view()
        
        if isinstance(index, _Index):
            # Fast track for creating and index. Allows dataframe to skip over the lengthy
            # process of creating a new index
            self.index = index
        elif index is None:
            self.index = RangeIndex(start=0, stop=values.shape[0], step=1)
        elif index_type == "datetime":
            try:
                if np.issubdtype(index.dtype, np.datetime64):
                    self.index = DateTimeIndex(index)
            except:
                logging.warn("The index is not of the datetime type as specified.")
                self.index = ObjectIndex(index)
        elif isinstance(index, np.ndarray):
            if np.issubdtype(index.dtype, np.datetime64):
                self.index = DateTimeIndex(index)
            else:
                self.index = ObjectIndex(index)
        else:
            self.index = ObjectIndex(index)
                
        self.iloc = IntegerLocation(self)
        self.loc = Location(self)

        self.mask = slice(0, len(self.index.keys_), 1)

        if self.values_.shape[0] != self.index.size:
            raise ValueError("Mismatch between Index length ({}) and Values length ({})".format(index.size, values.size))

    
    @property
    def values(self):
        """
        Get the values of the frame as a numpy array.
        
        Returns
        -------
        np.ndarray
            Numpy array representing the values of the frame.
            
        Examples
        --------
        >>> frame = Frame(np.array([[1, 2, 3], [4, 5, 6]]))
        >>> frame.values
        array([[1, 2, 3],
                [4, 5, 6]])
        """
        return np.asarray(self.values_)[self.mask]
    
    def __repr__(self):
        """
        Return a string representation of the frame.
        
        Returns
        -------
        str
            String representation of the frame.
            
        Examples
        --------
        >>> frame = Frame(np.array([[1, 2], [3, 4]]))
        >>> repr(frame)
        '   0  1\n0  1  2\n1  3  4'
        """
        return str(self.to_pandas())
    
    def __array__(self):
        """
        Convert the frame to a numpy array.
        
        Returns
        -------
        np.ndarray
            Numpy array representation of the frame.
            
        Examples
        --------
        >>> frame = Frame(np.array([[1, 2], [3, 4]]))
        >>> np.array(frame)
        array([[1, 2],
               [3, 4]])
        """
        return self.values
    
    def __len__(self):
        """
        Get the length of the frame.
        
        Returns
        -------
        int
            Length of the frame.
            
        Examples
        --------
        >>> frame = Frame(np.array([[1, 2], [3, 4]]))
        >>> len(frame)
        2
        """
        return len(self.values)

    @property
    def shape(self):
        """
        Get the shape of the frame.
        
        Returns
        -------
        tuple
            Shape of the frame.
            
        Examples
        --------
        >>> frame = Frame(np.array([[1, 2], [3, 4]]))
        >>> frame.shape
        (2, 2)
        """
        return np.asarray(self.values).shape
    
    def astype(self, type_):
        """
        Cast the values of the frame to the specified type.
        
        Parameters
        ----------
        type_ : type
            Type to cast the values to.
            
        Examples
        --------
        >>> frame = Frame(np.array([[1, 2], [3, 4]]))
        >>> frame.astype(float)
        """
        self.values = self.values.astype(type_)     
    
    def iterrows(self):
        """
        Iterate over the rows of the frame.
        
        Yields
        ------
        np.ndarray
            Numpy array representing a row of the frame.
            
        Examples
        --------
        >>> frame = Frame(np.array([[1, 2, 3], [4, 5, 6]]))
        >>> for row in frame.iterrows():
        ...     print(row)
        [1 2 3]
        [4 5 6]
        """
        return self.values
    
    def to_numpy(self):
        """
        Convert the frame to a numpy array.
        
        Returns
        -------
        np.ndarray
            Numpy array representation of the frame.
            
        Examples
        --------
        >>> frame = Frame(np.array([[1, 2], [3, 4]]))
        >>> frame.to_numpy()
        array([[1, 2],
               [3, 4]])
        """
        return self.values

    @property
    def dtype(self):
        """
        Get the data type of the values of the frame.
        
        Returns
        -------
        np.dtype
            Data type of the values.
            
        Examples
        --------
        >>> frame = Frame(np.array([[1, 2], [3, 4]]))
        >>> frame.dtype
        dtype('int64')
        """
        return self.values.dtype

    def resample(self, freq):
        """
        Resample the frame to a specified frequency.
        
        Parameters
        ----------
        freq : str
            Frequency string.
            
        Returns
        -------
        :doc:`../resample/resampler`
            Resampler object for resampling the frame.
            
        Examples
        --------
        >>> frame = Frame(np.array([[1], [2], [3]]), index=np.array(['2021-01-01', '2021-01-02', '2021-01-03'], dtype='datetime64'))
        >>> frame.resample('D')
        <Resampler>
        """
        if not isinstance(self.index, DateTimeIndex):
            raise TypeError("Index must be a DateTimeIndex.")
        return Resampler(self, freq)
    
    def rolling(self, window):
        """
        Provide rolling window calculations.
        
        Parameters
        ----------
        window : int
            Size of the moving window.
            
        Returns
        -------
        :doc:`../rolling/rolling`
            Rolling object for performing rolling window calculations.
            
        Examples
        --------
        >>> frame = Frame(np.array([[1, 2, 3], [4, 5, 6]]))
        >>> frame.rolling(2)
        <Rolling>
        """
        return Rolling(self, window)

    def _fast_init(self, mask):
        """
        Backdoor of sorts. Allows for a quicker initialization after slicing.

        Parameters
        ----------
        mask : slice
            Slice to be used.
            
        Returns
        -------
        Frame
            Frame object initialized with the specified mask.
            
        Examples
        --------
        >>> frame = Frame(np.array([[1, 2], [3, 4]]))
        >>> new_frame = frame._fast_init(slice(0, 1))
        """
        frame = self.__new__(self.__class__)
        
        frame.mask = mask
        frame.values_ = self.values_

        frame.index = self.index._fast_init(mask)

        frame.reference = self.reference

        frame.iloc = IntegerLocation(frame)
        frame.loc = Location(frame)

        return frame

    def plot(self, *args, **kwargs):
        """
        Plotting function. Requires matplotlib and Pandas to be installed. All parameters are passed onto pandas.
        
        Returns
        -------
        matplotlib.axes.AxesSubplot
            AxesSubplot object representing the plot.
            
        Examples
        --------
        >>> frame = Frame(np.array([[1, 2, 3], [4, 5, 6]]))
        >>> frame.plot()
        <AxesSubplot:xlabel='index', ylabel='values'>
        """
        return self.to_pandas().plot(*args, **kwargs)
    
    def tail(self, n=5):
        """
        Return the last `n` rows of the frame.

        This function returns the last `n` rows of the frame, based on the number
        of rows specified by the `n` parameter. If `n` is not provided, it defaults
        to 5. It is useful for quickly inspecting the tail of a frame for large datasets.

        Parameters
        ----------
        n : int, optional
            Number of rows to return. Defaults to 5.

        Returns
        -------
        Frame
            A new Frame instance containing the last `n` rows.

        See Also
        --------
        Frame.head : Returns the first `n` rows.

        Examples
        --------
        >>> frame = Frame(np.array([[1, 2, 3], [4, 5, 6], [7, 8, 9], [10, 11, 12]]))
        >>> frame.tail(2)
        array([[ 7,  8,  9],
            [10, 11, 12]])
        """
        return self.iloc[-n:]


    def head(self, n=5):
        """
        Return the first `n` rows of the frame.

        This function returns the first `n` rows of the frame, based on the number
        of rows specified by the `n` parameter. If `n` is not provided, it defaults
        to 5. It is useful for quickly inspecting the head of a frame for large datasets.

        Parameters
        ----------
        n : int, optional
            Number of rows to return. Defaults to 5.

        Returns
        -------
        Frame
            A new Frame instance containing the first `n` rows.

        See Also
        --------
        Frame.tail : Returns the last `n` rows.

        Examples
        --------
        >>> frame = Frame(np.array([[1, 2, 3], [4, 5, 6], [7, 8, 9], [10, 11, 12]]))
        >>> frame.head(2)
        array([[1, 2, 3],
                [4, 5, 6]])
        """
        return self.iloc[:n]        

cdef class Series(Frame):
    """
    One-dimensional labeled array capable of holding any data type.

    Parameters
    ----------
    values : np.ndarray
        The array holding the data.
    index : Index
        The index (axis labels).
    name : str, optional
        The name of the Series.
    index_type : IndexType, optional
        The type of index.

    Attributes
    ----------
    reference : str
        A reference code for the Series.
    name : str or None
        The name of the Series.
    """

    def __init__(self, np.ndarray values, index, name=None, index_type=None):
        self.reference = "S"

        if name is not None:
            self.name = str(name)

        super().__init__(values, index, index_type)

        if np.ndim(values) != 1:
            raise ValueError("Unexpected number of dimensions for values. Expected 1, got {}.".format(np.ndim(values)))

    def to_pandas(self):
        """
        Convert the Series to a pandas Series.

        Returns
        -------
        pd.Series
            A pandas Series containing the same data.
            
        Examples
        --------
        >>> series = Series(np.array([1, 2, 3]), index=np.array(['a', 'b', 'c']))
        >>> series.to_pandas()
        a    1
        b    2
        c    3
        dtype: int64
        """
        return pd.Series(self.values, index=self.index.to_pandas(), name=self.name, dtype=self.dtype)

    """
    MATH
    """
    def _quick_init(self, values):
        """
        Quickly initialize a new Series with given values.

        Parameters
        ----------
        values : np.ndarray
            The values for the new Series.

        Returns
        -------
        Series
            A new Series with the given values.
            
        Examples
        --------
        >>> series = Series(np.array([1, 2, 3]), index=np.array(['a', 'b', 'c']))
        >>> new_series = series._quick_init(np.array([4, 5, 6]))
        """
        return Series(values=values, index=self.index)

    def __mul__(self, other):
        """
        Multiply the Series by a scalar or another Series element-wise.

        Parameters
        ----------
        other : scalar or Series
            The scalar or Series to multiply by.

        Returns
        -------
        Series
            A new Series resulting from element-wise multiplication.
            
        Examples
        --------
        >>> series = Series(np.array([1, 2, 3]), index=np.array(['a', 'b', 'c']))
        >>> series * 2
        a    2
        b    4
        c    6
        dtype: int64
        """
        return self._quick_init(self.values * other)

    def __div__(self, other):
        """
        Divide the Series by a scalar or another Series element-wise.

        Parameters
        ----------
        other : scalar or Series
            The scalar or Series to divide by.

        Returns
        -------
        Series
            A new Series resulting from element-wise division.
            
        Examples
        --------
        >>> series = Series(np.array([2, 4, 6]), index=np.array(['a', 'b', 'c']))
        >>> series / 2
        a    1.0
        b    2.0
        c    3.0
        dtype: float64
        """
        return self._quick_init(self.values / other)

    def __rdiv__(self, other):
        """
        Divide a scalar by the Series element-wise.

        Parameters
        ----------
        other : scalar
            The scalar to divide by.

        Returns
        -------
        Series
            A new Series resulting from element-wise division.
            
        Examples
        --------
        >>> series = Series(np.array([2, 4, 6]), index=np.array(['a', 'b', 'c']))
        >>> 12 / series
        a    6.0
        b    3.0
        c    2.0
        dtype: float64
        """
        return self._quick_init(other / self.values)

    def __add__(self, other):
        """
        Add a scalar or another Series element-wise.

        Parameters
        ----------
        other : scalar or Series
            The scalar or Series to add.

        Returns
        -------
        Series
            A new Series resulting from element-wise addition.
            
        Examples
        --------
        >>> series = Series(np.array([1, 2, 3]), index=np.array(['a', 'b', 'c']))
        >>> series + 2
        a    3
        b    4
        c    5
        dtype: int64
        """
        return self._quick_init(self.values + other)

    def __sub__(self, other):
        """
        Subtract a scalar or another Series element-wise.

        Parameters
        ----------
        other : scalar or Series
            The scalar or Series to subtract.

        Returns
        -------
        Series
            A new Series resulting from element-wise subtraction.
            
        Examples
        --------
        >>> series = Series(np.array([1, 2, 3]), index=np.array(['a', 'b', 'c']))
        >>> series - 1
        a    0
        b    1
        c    2
        dtype: int64
        """
        return self._quick_init(self.values - other)

    def __rsub__(self, other):
        """
        Subtract the Series from a scalar element-wise.

        Parameters
        ----------
        other : scalar
            The scalar to subtract from.

        Returns
        -------
        Series
            A new Series resulting from element-wise subtraction.
            
        Examples
        --------
        >>> series = Series(np.array([1, 2, 3]), index=np.array(['a', 'b', 'c']))
        >>> 5 - series
        a    4
        b    3
        c    2
        dtype: int64
        """
        return self._quick_init(other - self.values)

    def __gt__(self, other):
        """
        Check if the Series is greater than a scalar or another Series element-wise.

        Parameters
        ----------
        other : scalar or Series
            The scalar or Series to compare with.

        Returns
        -------
        Series
            A new Series of boolean values resulting from element-wise comparison.
            
        Examples
        --------
        >>> series = Series(np.array([1, 2, 3]), index=np.array(['a', 'b', 'c']))
        >>> series > 2
        a    False
        b    False
        c     True
        dtype: bool
        """
        return self._quick_init(self.values > other)

    def __lt__(self, other):
        """
        Check if the Series is less than a scalar or another Series element-wise.

        Parameters
        ----------
        other : scalar or Series
            The scalar or Series to compare with.

        Returns
        -------
        Series
            A new Series of boolean values resulting from element-wise comparison.
            
        Examples
        --------
        >>> series = Series(np.array([1, 2, 3]), index=np.array(['a', 'b', 'c']))
        >>> series < 2
        a     True
        b    False
        c    False
        dtype: bool
        """
        return self._quick_init(self.values < other)

    def __ge__(self, other):
        """
        Check if the Series is greater than or equal to a scalar or another Series element-wise.

        Parameters
        ----------
        other : scalar or Series
            The scalar or Series to compare with.

        Returns
        -------
        Series
            A new Series of boolean values resulting from element-wise comparison.
            
        Examples
        --------
        >>> series = Series(np.array([1, 2, 3]), index=np.array(['a', 'b', 'c']))
        >>> series >= 2
        a    False
        b     True
        c     True
        dtype: bool
        """
        return self._quick_init(self.values >= other)

    def __le__(self, other):
        """
        Check if the Series is less than or equal to a scalar or another Series element-wise.

        Parameters
        ----------
        other : scalar or Series
            The scalar or Series to compare with.

        Returns
        -------
        Series
            A new Series of boolean values resulting from element-wise comparison.
            
        Examples
        --------
        >>> series = Series(np.array([1, 2, 3]), index=np.array(['a', 'b', 'c']))
        >>> series <= 2
        a     True
        b     True
        c    False
        dtype: bool
        """
        return self._quick_init(self.values <= other)



cdef class DataFrame(Frame):
    """
    The Sloth Dataframe is meant to be a faster version of pandas 
    dataframe. It accomplished this by being a thin wrapper of 
    numpy. Essentially its a numpy matrix with an index and a
    list of columns corresponding to the the row and columns of
    the numpy matrix.

    Parameters
    ----------
    values : numpy.ndarray[ndims=2]
        Matrix to store in the DataFrame
    index : array-like or Index, optional
        Index to use for resulting frame. Defaults to RangeIndex if no index is provided.
    columns : array-like or Index, optional
        Column labels to use for resulting frame. Defaults to RangeIndex if no columns are provided.
    """
        
    @cython.boundscheck(False)  # Deactivate bounds checking
    @cython.wraparound(False)   # Deactivate negative indexing.
    def __init__(self, np.ndarray values, index=None, columns=None, index_type=None):
        """
        Initialize DataFrame.

        Parameters
        ----------
        values : numpy.ndarray[ndims=2]
            Matrix to store in the DataFrame
        index : array-like or Index, optional
            Index to use for resulting frame. Defaults to RangeIndex if no index is provided.
        columns : array-like or Index, optional
            Column labels to use for resulting frame. Defaults to RangeIndex if no columns are provided.
        index_type : type, optional
            Type of index.

        Raises
        ------
        ValueError
            If unexpected number of dimensions for values or if there's a mismatch between columns length and values width.
            
        Examples
        --------
        >>> df = DataFrame(np.array([[1, 2], [3, 4]]), index=['row1', 'row2'], columns=['col1', 'col2'])
        >>> df.values
        array([[1, 2],
               [3, 4]])
        """
        self.reference = "D"

        # Because columns is a list of strings,
        # it is a ObjectIndex
        if isinstance(columns, ObjectIndex):
            self.columns = columns
        elif columns is None:
            self.columns = RangeIndex(start=0, stop=values.shape[1], step=1)
        else:
            self.columns = ObjectIndex(columns)
                
        super().__init__(values, index, index_type)

        self.extras = {}

        self.iat = iAT(self)
        
        if np.ndim(values) != 2:
            raise ValueError("Unexpected number of dimensions for values. Expected 2, got {}.".format(np.ndim(values)))

        if values.shape[1] != columns.size:
            raise ValueError("Mismatch between Columns length ({}) and Values Width ({})".format(columns.size, values.shape[1]))
                
#         self.loc = Location(self.values, self.index, self.columns)
    
    @classmethod
    def from_pandas(cls, dataframe):
        """
        Class method to convert pandas dataframe to a sloth frame

        Parameters
        ----------
        dataframe : pandas.DataFrame
            pd.DataFrame to convert into a sloth DataFrame

        Returns
        -------
        DataFrame
            The sloth dataframe

        Examples
        --------
        >>> import pandas as pd
        >>> df = pd.DataFrame({'A': [1, 2], 'B': [3, 4]})
        >>> sloth_df = DataFrame.from_pandas(df)
        >>> sloth_df.values
        array([[1, 3],
               [2, 4]])
        """
        # TODO: Error handling
        return cls(
            values=dataframe.to_numpy(), 
            index=dataframe.index.values, 
            columns=dataframe.columns.values
        )
    
    def to_pandas(self):
        """
        Class method to convert sloth dataframe to pandas dataframe

        Returns
        -------
        pandas.DataFrame
            The pandas dataframe

        Examples
        --------
        >>> df = DataFrame(np.array([[1, 2], [3, 4]]), index=['row1', 'row2'], columns=['col1', 'col2'])
        >>> df.to_pandas()
              col1  col2
        row1     1     2
        row2     3     4
        """
        return pd.DataFrame(
            self.values, 
            index=self.index.to_pandas(), 
            columns=self.columns.to_pandas()
        )
    
    def __getitem__(self, arg):
        """
        For handling column calls

        Parameters
        ----------
        arg : str or array of strings
            str means that it is a single column name
            array means that it is a list of column names

        Returns
        -------
        Series or DataFrame
            A Series if arg is a single column name, otherwise a modified DataFrame.

        Raises
        ------
        TypeError
            If arg is an incorrect type.

        Examples
        --------
        >>> df = DataFrame(np.array([[1, 2], [3, 4]]), index=['row1', 'row2'], columns=['A', 'B'])
        >>> df['A']
        A
        row1    1
        row2    3
        dtype: int64

        >>> df[['A', 'B']]
              A  B
        row1  1  2
        row2  3  4
        """
        if isinstance(arg, str):
            # str means that arg is a column name,
            # thus a series will be returned
            return self._handle_str(arg)
            
        # Array-like
        # Fancy indexing
        elif isinstance(arg, (list, np.ndarray)):
            return self._handle_array(arg)
        
        elif isinstance(arg, (Series)):
            if arg.dtype == "bool":
                return self._handle_bool_array(arg.values)

        raise TypeError("{} is an incorrect type".format(type(arg)))
    
    cdef DataFrame _handle_bool_array(self, np.ndarray[np.npy_bool, ndim=1] arg):
        """
        Handle boolean array indexing.

        Parameters
        ----------
        arg : numpy.ndarray
            Boolean array for indexing.

        Returns
        -------
        DataFrame
            A modified DataFrame based on boolean indexing.

        Examples
        --------
        >>> df = DataFrame(np.array([[1, 2], [3, 4]]), index=['row1', 'row2'], columns=['A', 'B'])
        >>> mask = df['A'] > 1
        >>> filtered_df = df[mask]
              A  B
        row2  3  4
        """
        return DataFrame(
            values=self.values[arg], 
            index=self.index.keys[arg], 
            columns=self.columns
        )

    def __getattr__(self, arg):
        """
        Similar to '__getitem__' but allows for fancy stuff like
        DataFrame.<column> instead of DataFrame["<column>"]

        Parameters
        ----------
        arg : str
            single column name

        Returns
        -------
        Series
            A Series representing the column.

        Raises
        ------
        AttributeError
            If the column is not found.

        Examples
        --------
        >>> df = DataFrame(np.array([[1, 2], [3, 4]]), index=['row1', 'row2'], columns=['A', 'B'])
        >>> df.A
        A
        row1    1
        row2    3
        dtype: int64
        """
        if arg in self.columns.index:
            return self._handle_str(arg)
        raise AttributeError(f"{arg} not found.")

    cdef inline Series _handle_str(self, arg):
        """
        Handle string indexing.

        Parameters
        ----------
        arg : str
            Column name.

        Returns
        -------
        Series
            A Series representing the column.

        Examples
        --------
        >>> df = DataFrame(np.array([[1, 2], [3, 4]]), index=['row1', 'row2'], columns=['A', 'B'])
        >>> df._handle_str('A')
        A
        row1    1
        row2    3
        dtype: int64
        """
        return Series(
            # A 1d numpy array
            values=self.values[:, self.columns.get_item(arg)], 
            index=self.index, 
            name=arg
        )
    
    cdef inline DataFrame _handle_array(self, arg):
        """
        Handle array indexing.

        Parameters
        ----------
        arg : array of strs
            List of column names.

        Returns
        -------
        DataFrame
            A modified DataFrame with the selected columns.

        Examples
        --------
        >>> df = DataFrame(np.array([[1, 2, 3], [4, 5, 6]]), index=['row1', 'row2'], columns=['A', 'B', 'C'])
        >>> df._handle_array(['A', 'C'])
              A  C
        row1  1  3
        row2  4  6
        """
        cdef np.int64_t length = len(arg)
        cdef np.int64_t[:] args = np.zeros(length, dtype=np.int64)
        cdef np.int64_t i

        for i in range(length):
            args[i] = self.columns.get_item(arg[i])

        return DataFrame(self.values[:, args], index=self.index, columns=arg)

    def __setitem__(self, arg, value):
        """
        Set item method.

        Parameters
        ----------
        arg : str
            Column name or index.
        value : any
            Value to set.

        Examples
        --------
        >>> df = DataFrame(np.array([[1, 2], [3, 4]]), index=['row1', 'row2'], columns=['A', 'B'])
        >>> df['A'] = [5, 6]
              A  B
        row1  5  2
        row2  6  4
        """
        if isinstance(value, Series):
            value = value.values

        # You can only set columns
        if arg in self.columns:
            self.values[:, self.columns.get_item(arg)] = value
        else: # column does not exist, thus a new one must be created
            index = np.append(self.columns.keys, arg)
            self.columns = ObjectIndex(index)
            self.values = np.concatenate((self.values, np.transpose([value])), axis=1)
    
    def reindex(self, index):
        """
        Fits the dataframe with a new index.

        Parameters
        ----------
        index : numpy.ndarray
            Index to fit the dataframe with.
    
        Returns
        -------
        DataFrame
            A new DataFrame fitted with the new index.

        Examples
        --------
        >>> df = DataFrame(np.array([[1, 2], [3, 4]]), index=['row1', 'row2'], columns=['A', 'B'])
        >>> new_df = df.reindex(np.array(['row1', 'row3'], dtype=object))
              A   B
        row1  1   2
        row3 NaN NaN
        """
        cdef: 
            np.ndarray new_values
            int i, idx

        if np.issubdtype(index.dtype, np.datetime64):
            index = index.astype("datetime64[ns]")

        new_values = np.empty((index.size, self.shape[1]))
        new_values[:] = np.nan

        for i in range(index.size):
            try:
                idx = self.index.get_item(self.index.index[i])
            except KeyError:
                continue
            new_values[idx] = self.iloc[idx]
        
        return DataFrame(values=new_values, index=index, columns=self.columns)

    def _fast_init(self, mask):
        """
        Fast initialization method.

        Parameters
        ----------
        mask : numpy.ndarray
            Boolean mask.

        Returns
        -------
        DataFrame
            A new DataFrame.

        Examples
        --------
        >>> df = DataFrame(np.array([[1, 2], [3, 4]]), index=['row1', 'row2'], columns=['A', 'B'])
        >>> mask = df['A'] > 1
        >>> new_df = df._fast_init(mask)
              A  B
        row1  1  2
        """
        frame = super()._fast_init(mask)

        frame.columns = self.columns

        return frame

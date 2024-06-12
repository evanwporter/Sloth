# cython: profile=True

cimport numpy as np
import numpy as np
from .indexer cimport IntegerLocation, Location, iAT
from .index cimport DateTimeIndex, _Index, ObjectIndex, RangeIndex
cimport cython

import logging

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
            # TODO: Could be made faster by using pointers
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
        frame.values_ = self.values_ # TODO: look into pointers

        frame.index = self.index._fast_init(mask)

        frame.reference = self.reference

        frame.iloc = IntegerLocation(frame)
        frame.loc = Location(frame)

        return frame

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
            self.columns = ObjectIndex(np.arange(0, values.shape[1], 1))
        else:
            self.columns = ObjectIndex(columns)
                
        super().__init__(values, index, index_type)

        self.extras = {}

        self.iat = iAT(self)
        
        if np.ndim(values) != 2:
            raise ValueError("Unexpected number of dimensions for values. Expected 2, got {}.".format(np.ndim(values)))

        if values.shape[1] != self.columns.size:
            raise ValueError("Mismatch between Columns length ({}) and Values Width ({})".format(columns.size, values.shape[1]))
                
#         self.loc = Location(self.values, self.index, self.columns)
    
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
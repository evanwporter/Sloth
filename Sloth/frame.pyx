# cython: profile=True

cimport numpy as np
import numpy as np
from indexer cimport IntegerLocation, Location
from index cimport DateTimeIndex, _Index, ObjectIndex, RangeIndex
cimport cython

import logging

from resample cimport Resampler
from rolling cimport Rolling

import pandas as pd

"""
Public Variables
(Displacement Compliant)
------------------------
  * values
"""


cdef class Frame:
        
    def __init__(self, np.ndarray values, index=None, index_type=None):
        """
        Parameters
        ----------
        values : np.ndarray
            Values to fill up the dataframe with. The dimensions of "values" must be 
            equal to len(columns) x len(index)
        index : array-like
            Index that of values. len(index) must be equal to values.shape[1]
        """
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
        return np.asarray(self.values_)[self.mask]
    
    def __repr__(self):
        return str(self.to_pandas())
    
    def __array__(self):
        return self.values
    
    def __len__(self):
        return len(self.values)

    @property
    def shape(self):
        return np.asarray(self.values).shape
    
    def astype(self, type_):
        self.values = self.values.astype(type_)     
    
    def iterrows(self):
        return self.values
    
    def to_numpy(self):
        return self.values

    @property
    def dtype(self):
        return self.values.dtype

    # def __setattr__(self, arg, value):
    #     if arg == "values":
    #         raise AttributeError("Attribute 'values' cannot be modified")
    #     else:
    #         setattr(self, arg, value)
    
    def resample(self, freq):
        if not isinstance(self.index, DateTimeIndex):
            raise TypeError("Index must be a DataTimeIndex.")
        return Resampler(self, freq)
    
    def rolling(self, window):
        return Rolling(self, window)

    def fast_init(self, mask):
        """
        Backdoor of sorts. Allows for a quicker initialization after slicing.

        Parameters
        ----------
        mask : slice
            slice to be used
        """
        frame = self.__new__(self.__class__)
        
        frame.mask = mask
        frame.values_ = self.values_

        frame.index = self.index.fast_init(mask)
        frame.columns = self.columns

        frame.reference = self.reference

        frame.iloc = IntegerLocation(frame)
        frame.loc = Location(frame)

        return frame

    def plot(self, *args, **kwargs):
        """
        Plotting function. Requires matplotlib and Pandas to be installed. All paramters are passed onto pandas.
        """
        return self.to_pandas().plot(*args, **kwargs)


cdef class Series(Frame):
        
    def __init__(self, np.ndarray values, index, name=None, index_type=None):
        self.reference = "S"

        if name is not None:
            self.name = str(name)

        super().__init__(values, index, index_type)

        if np.ndim(values) != 1:
            raise ValueError("Unexpected number of dimensions for values. Expected 1, got {}.".format(np.ndim(values)))

    
    def to_pandas(self):
        return pd.Series(self.values, index=self.index.to_pandas(), name=self.name, dtype=self.dtype)

    """
    MATH
    """
    def _quick_init(self, values):
        return Series(values=values, index=self.index)

    def __mul__(self, other):
        return self._quick_init(self.values * other)

    def __div__(self, other):
        return self._quick_init(self.values / other)

    def __rdiv__(self, other):
        return self._quick_init(other / self.values)

    def __add__(self, other):
        return self._quick_init(self.values + other)

    def __sub__(self, other):
        return self._quick_init(self.values - other)
    
    def __rsub__(self, other):
        return self._quick_init(other - self.values)

    def __gt__(self, other):
        return self._quick_init(self.values > other) 

    def __lt__(self, other):
        return self._quick_init(self.values < other)

    def __ge__(self, other):
        return self._quick_init(self.values >= other)

    def __le__(self, other):
        return self._quick_init(self.values <= other)


cdef class DataFrame(Frame):
        
    @cython.boundscheck(False)  # Deactivate bounds checking
    @cython.wraparound(False)   # Deactivate negative indexing.
    def __init__(self, np.ndarray values, index=None, columns=None, index_type=None):

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
        
        if np.ndim(values) != 2:
            raise ValueError("Unexpected number of dimensions for values. Expected 1, got {}.".format(np.ndim(values)))

        if values.shape[1] != columns.size:
            raise ValueError("Mismatch between Columns length ({}) and Values Width ({})".format(columns.size, values.shape[1]))
                
#         self.loc = Location(self.values, self.index, self.columns)
    
    @classmethod
    def from_pandas(cls, dataframe):
        """
        Class method to convert pandas dataframe to a sloth frame

        Parameters
        ----------
        dataframe : pd.DataFrame
            pd.DataFrame to convert into a sloth DataFrame

        Returns
        -------
        sloth.DataFrame
            The sloth dataframe
        """
        # TODO: Error handling
        return cls(
            values=dataframe.to_numpy(), 
            index=dataframe.index.values, 
            columns=dataframe.columns.values
        )
    
    def to_pandas(self):

        return pd.DataFrame(
            self.values, 
            index=self.index.to_pandas(), 
            columns=self.columns.to_pandas()
        )
    
    # @property
    # def shape(self):
    #     return tuple(self.values.shape)
    
    def __getitem__(self, arg):
        """
        For handling column calls

        Parameters
        ----------
        arg : str or array of strings
            str means that it is a single column name
            array means that it is a list of column names
        """
        if isinstance(arg, str):
            # str means that arg is a column name,
            # thus a series will be returned
            return self._handle_str(arg)
            
        # elif isinstance(arg, slice):
        #     return self._handle_slice(arg)
        
        # Array-like
        # Fancy indexing
        elif isinstance(arg, (list, np.ndarray)):
            return self._handle_array(arg)
        
        elif isinstance(arg, (Series)):
            if arg.dtype == "bool":
                return self._handle_bool_array(arg.values)

        raise TypeError("{} is an incorrect type".format(type(arg)))
    
    cdef DataFrame _handle_bool_array(self, np.ndarray[np.npy_bool, ndim=1] arg):
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
        """
        return self._handle_str(arg)
    
    cdef inline Series _handle_str(self, arg):
        return Series(
            # A 1d numpy array
            values=self.values[:, self.columns.get_item(arg)], 
            index=self.index, 
            name=arg
        )
    
    # cdef inline DataFrame _handle_slice(self, slice arg):
    #     start = self.columns[arg.start]
    #     stop = self.columns[arg.stop]
    #     step = arg.step

    #     cdef DataFrame copied_frame = copy(self)

    #     if arg.start is not None:
    #         start = self.columns[arg.start]
        

        
        # return self.new(self.values[:, start:stop:step], self.index, columns)
    
    cdef inline DataFrame _handle_array(self, arg):
        """
        Parameters
        ----------
        arg : array of strs
            list of column names

        Returns
        -------
        DataFrame
            A modified DataFrame with the selected columns
        """
        cdef np.int64_t length = len(arg)
        cdef np.int64_t[:] args = np.zeros(length, dtype=np.int64)
        cdef np.int64_t i

        for i in range(length):
            args[i] = self.columns.get_item(arg[i])

        return DataFrame(self.values[:, args], index=self.index, columns=arg)

    def __setitem__(self, arg, value):
        if isinstance(value, Series):
            value = value.values

        # You can only set columns
        if arg in self.columns:
            self.values[:, self.columns.get_item(arg)] = value
        else: # column does not exist, thus a new one must be created
            index = np.append(self.columns.keys, arg)
            self.columns = ObjectIndex(index)
            self.values = np.concatenate((self.values, np.transpose([value])), axis=1)
    
    # def __setattr__(self, arg, value):
    #     import warnings
    #     warning.warn("Sloth doesn't allow columns to be created via a new attribute name")
        


    # cdef _handle_tuple(self, tuple arg):
    #     cdef int i
    #     for i in range(len(arg)):

    # def reindex(self):
    #     return self._reindex(self.index, self.columns)

    # cdef _reindex(self, index, columns):
    #     cdef np.ndarray[:, :] reindexed_values = np.zeros(
    #         (
    #             # Dataframe width
    #             len(columns.keys),
    #             # Dataframe length
    #             len(index)
    #         )
    #     )

    #     cdef int target_index, original_index

    #     for target_index in range(len(index)):
    #         for original_index in range(len(self.index.keys)):
    #             if index[target_index] == self.index.keys[original_index]:
    #                 reindexed_values[target_index] = self.values[original_index]
        
        

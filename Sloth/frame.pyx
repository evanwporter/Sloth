# cython: profile=True

cimport numpy as np
import numpy as np
from indexer cimport IntegerLocation, Location
from index cimport DateTimeIndex, _Index, ObjectIndex
cimport cython

import logging

from resample cimport Resampler

import pandas as pd

"""
Public Variables
(Displacement Compliant)
------------------------
  * values
"""

# cdef class FrameView:
#  def __init__(self, FD, 

cdef class Frame:
        
    def __init__(self, np.ndarray values, index, index_type=None):
        """
        Parameters
        ----------
        values : np.ndarray
            Values to fill up the dataframe with. The dimensions of "values" must be 
            equal to len(columns) x len(index)
        index : array-like
            Index that of values. len(index) must be equal to values.shape[1]
        """
        self.values = values.view()
        
        if isinstance(index, _Index):
            # Fast track for creating and index. Allows dataframe to skip over the lengthy
            # process of creating a new index
            self.index = index
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

    def fast_init(self, location: str, displacement: tuple, coordinates: tuple):
        """
        Backdoor of sorts. Allows for a quicker initialization.

        Parameters
        ----------
        location : str
            'C' for columns, or 'I' for index
        displacement : tuple
        coordinates : tuple
        """
        frame = self.__new__(self.__class__)

        # TODO: FIX THIS.
        frame.values = self.values[coordinates[0]: coordinates[1]]
        frame.reference = self.reference

        frame.index = self.index.fast_init(displacement)
        frame.columns = self.columns

        return frame


cdef class Series(Frame):
        
    def __init__(self, np.ndarray values, index, name=None, index_type=None):
        self.reference = "S"

        if name is not None:
            self.name = str(name)

        super().__init__(values, index, index_type)
    
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

cdef class DataFrame(Frame):
        
    @cython.boundscheck(False)  # Deactivate bounds checking
    @cython.wraparound(False)   # Deactivate negative indexing.
    def __init__(self, np.ndarray values, index, columns, index_type=None):

        self.reference = "D"

        # Because columns is a list of strings,
        # it is a ObjectIndex
        if isinstance(columns, ObjectIndex):
            self.columns = columns
        else:
            self.columns = ObjectIndex(columns)
                
        super().__init__(values, index, index_type)

        self.extras = {}
                
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
        
        

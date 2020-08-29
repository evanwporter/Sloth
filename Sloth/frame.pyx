# cython: profile=True

cimport numpy as np
import numpy as np
from indexer cimport IntegerLocation, Location
from index cimport DateTimeIndex, _Index, ObjectIndex
cimport cython

from resample cimport Resampler

import pandas as pd


cdef class Frame:
        
    def __init__(self, np.ndarray values, index, index_type=None):
        self.values_ = values.view()
        
        if isinstance(index, _Index):
            self.index = index
        elif index_type == "datetime" or np.issubdtype(index.dtype, np.datetime64):
            self.index = DateTimeIndex(index)
        else:
            self.index = ObjectIndex(index)
                
        self.iloc = IntegerLocation(self)
        self.loc = Location(self)
    
    def __repr__(self):
        return str(self.to_pandas())
    
    def __array__(self):
        return self.values
    
    def astype(self, type_):
        self.values_ = self.values_.astype(type_)
    
    def iterrows(self):
        return self.values
    
    def to_numpy(self):
        return self.values
    
    def resample(self, freq):
        return Resampler(self, freq)

    def fast_init(self, location: str, displacement: tuple):
        frame = self.__new__(self.__class__)
        frame.values_ = self.values_
        frame.reference = self.reference
        if location == "C":
            frame.columns = self.columns.fast_init(displacement)
            frame.index = self.index
        else:
            frame.index = self.index.fast_init(displacement)
            frame.columns = self.columns
        return frame


cdef class Series(Frame):
        
    def __init__(self, np.ndarray values, index, name, index_type=None):
        self.reference = "S"

        self.name = str(name)

        super().__init__(values, index, index_type)
    
    def to_pandas(self):
        return pd.Series(self.values_, index=self.index.keys_, name=self.name)

cdef class DataFrame(Frame):
        
    @cython.boundscheck(False)  # Deactivate bounds checking
    @cython.wraparound(False)   # Deactivate negative indexing.
    def __init__(self, np.ndarray values, index, columns, index_type=None):

        self.reference = "D"

        if isinstance(columns, ObjectIndex):
            self.columns = columns
        else:
            self.columns = ObjectIndex(columns)
                
        super().__init__(values, index, index_type)
                
#         self.loc = Location(self.values, self.index, self.columns)
    
    @classmethod
    def from_pandas(cls, dataframe):
        return cls(dataframe.to_numpy(), dataframe.index, dataframe.columns)
    
    def to_pandas(self):
        return pd.DataFrame(self.values, index=self.index.keys_, columns=self.columns.keys_)
    
    def __getitem__(self, arg):
        if isinstance(arg, str):
            return self._handle_str(arg)
            
        # elif isinstance(arg, slice):
        #     return self._handle_slice(arg)
        
        # Array-like
        # Fancy indexing
        elif isinstance(arg, (list, np.ndarray)):
            return self._handle_array(arg)

    
    cdef inline Series _handle_str(self, arg):
        return Series(
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
        cdef np.int64_t length = len(arg)
        cdef np.int64_t[:] args = np.zeros(length, dtype=np.int64)
        cdef np.int64_t i

        for i in range(length):
            args[i] = self.columns.get_item(arg[i])

        return DataFrame(self.values[:, args], index=self.index, columns=arg)

    
    @property
    def values(self):
        return self.values_[self.index.FD: self.index.BD]

    # cdef _handle_tuple(self, tuple arg):
    #     cdef int i
    #     for i in range(len(arg)):
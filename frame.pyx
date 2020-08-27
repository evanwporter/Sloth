cimport numpy as np
import numpy as np
from indexer cimport IntegerLocation, Location
from index cimport DateTimeIndex, _Index, ObjectIndex
cimport cython

from resample cimport Resampler

import pandas as pd

cdef class Frame:
        
    def __init__(self, np.ndarray values, index):
        self.values = values.view()
        
        if isinstance(index, _Index):
            self.index = index
        else:
            self.index = DateTimeIndex(index)
                
        self.iloc = IntegerLocation(self)
        self.loc = Location(self)
    
    def __repr__(self):
        return str(self.to_pandas())
    
    def __array__(self):
        return self.values
    
    def astype(self, type_):
        self.values = self.values.astype(type_)
    
    def iterrows(self):
        return self.values
    
    def to_numpy(self):
        return self.values
    
    def resample(self, freq):
        return Resampler(self, freq)


cdef class Series(Frame):
        
    def __init__(self, np.ndarray values, index, name):
        self.reference = "S"

        self.name = str(name)

        super().__init__(values, index)
    
    def to_pandas(self):
        return pd.Series(self.values, index=self.index.keys_, name=self.name)

cdef class DataFrame(Frame):
        
    @cython.boundscheck(False)  # Deactivate bounds checking
    @cython.wraparound(False)   # Deactivate negative indexing.
    def __init__(self, np.ndarray values, index, columns):

        self.reference = "D"

        if isinstance(columns, ObjectIndex):
            self.columns = columns
        else:
            self.columns = ObjectIndex(columns)
                
        super().__init__(values, index)
                
#         self.loc = Location(self.values, self.index, self.columns)
            
    @classmethod
    def new(cls, values, index, column):
        return cls(values, index, column)
    
    @classmethod
    def from_pandas(cls, dataframe):
        return cls(dataframe.to_numpy(), dataframe.index, dataframe.columns)
    
    def to_pandas(self):
        return pd.DataFrame(self.values, index=self.index.keys_, columns=self.columns.keys_)
    
    def __getitem__(self, arg):
        if isinstance(arg, str):
            return self._handle_str(arg, self.columns.get_item(arg))
            
        elif isinstance(arg, slice):
            return self._handle_slice(arg)

        # Tuples to be handled
    
    cdef Series _handle_str(self, arg, int column):
        return Series(
            values=self.values[:, column], 
            index=self.index, 
            name=arg
        )
    
    cdef Frame _handle_slice(self, slice arg):
        start = self.columns[arg.start]
        stop = self.columns[arg.stop]
        step = arg.step
        
        columns = list(self.columns)[start:stop:step]
        
        if len(columns) == 1:
            return self._handle_str(start, columns[0])

        return self.new(self.values[:, start:stop:step], self.index, columns)

    # cdef _handle_tuple(self, tuple arg):
    #     cdef int i
    #     for i in range(len(arg)):
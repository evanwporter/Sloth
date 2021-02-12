# cython: profile=True

cimport numpy as np
import numpy as np

from copy import copy

from index cimport DateTimeIndex
from cpython cimport  str
from frame cimport Frame, Series, DataFrame


cdef class Indexer:
    
    def __init__(self, Frame frame):
        self.frame = frame
        self.index = frame.index
        self.values = frame.values_
        
        self.reference = frame.reference
        
        if self.reference == "D":
            self.columns = frame.columns
        else:
            self.name = frame.name

cdef class IntegerLocation(Indexer):
    
    def __getitem__(self, arg):
        cdef int FD = self.index.FD
        cdef int start
        cdef int stop

        if isinstance(arg, int):
            arg = FD + arg
            return Series(self.values[arg], index=self.columns, name=self.index.keys[arg])            

        # If its not an integer, then is assumes that it is a slice
        if arg.start is not None:
            start = arg.start + FD
        if arg.stop is not None:
            stop = arg.stop + FD

        return self.frame.fast_init(location="I", displacement=(start, stop))

        # if isinstance(arg, int):
            
        #     # 1d
        #     values = self.values[arg]
        #     if isinstance(values, np.ndarray):
        #         return Series(values, index=self.columns, name=list(self.index)[arg])
        #     else:
        #         # Value
        #         return values
                
        # if isinstance(arg, slice):
        #     values = self.values[arg]
        #     index = list(self.index)[arg]
            
        #     if self.values.shape[0] == 1:
        #         return Series(values=values, index=index, name=self.name)
        #     else:
        #         return DataFrame(values=values, columns=self.columns, index=index)

cdef class Location(Indexer):

    def __getitem__(self, arg):
        # if isinstance(arg, np.ndarray):
        #     return self._handle_array(arg)
            
        if isinstance(arg, slice):
            return self._handle_slice(arg)

        else:
            return self._handle_str(arg, self.index.get_item(arg))
                
    cdef inline Series _handle_str(self, arg, int index):
        return Series(
            values=self.values[index], 
            index=self.columns, 
            name=arg
        )
    
    cdef inline Frame _handle_slice(self, slice arg):
        if arg.start is not None:
            start = self.index.get_item(arg.start)
        if arg.stop is not None:
            stop = self.index.get_item(arg.stop)
        
        return self.frame.fast_init("I", (start, stop))

    # cdef inline Frame _handle_array(self, arg):
    #     cdef str i
    #     cdef np.int64_t[:] args = np.zeros_like(arg, dtype=np.int64)
    #     for i in arg:
    #         args[i] = self.index.get_item(i)
    #     return DataFrame(self.values[args], columns=self.columns, index=arg)

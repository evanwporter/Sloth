# cython: profile=True

cimport numpy as np
from index cimport DateTimeIndex
# from cpython cimport list, dict, str
from frame cimport Frame, Series, DataFrame


cdef class Indexer:
    
    def __init__(self, Frame frame):
        # self.frame = frame
        self.values = frame.values
        self.index = frame.index
        
        self.reference = frame.reference
        
        if self.reference == "D":
            self.columns = frame.columns
        else:
            self.name = frame.name

cdef class IntegerLocation(Indexer):
    
    def __getitem__(self, arg):
        index = self.index.keys[arg]

        values = self.values[arg]

        if isinstance(arg, int):
            return Series(values, index=self.columns, name=index)

        # Checks to see if arg is something like [5:6] in which case 
        # an array with only one item is returned
        if len(index) == 1:
            return Series(values[0], index=self.columns, name=index[0])

        return DataFrame(values=values, index=index, columns=self.columns)
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
        if isinstance(arg, str):
            return self._handle_str(arg, self.index[arg])
            
        elif isinstance(arg, slice):
            return self._handle_slice(arg)

        # Tuples to be handled

    cdef Series _handle_str(self, arg, int index):
        return Series(
            values=self.values[index], 
            index=self.columns, 
            name=arg
        )
    
    cdef Frame _handle_slice(self, slice arg):
        start = self.index[arg.start] # int
        stop = self.index[arg.stop]
        step = arg.step
        
        index = self.index.keys[start:stop:step]
        
        if len(index) == 1:
            return self._handle_str(start, index[0])

        return DataFrame(self.values[start:stop:step], index=index, columns=self.columns)

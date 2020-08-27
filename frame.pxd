cimport numpy as np
from cpython cimport list, dict, str
from indexer cimport IntegerLocation, Location
from index cimport DateTimeIndex, _Index, ObjectIndex
cimport cython

cdef class Frame:
    cdef public:
        np.ndarray values
        _Index index
        IntegerLocation iloc
        Location loc
        str reference
        int i
        

cdef class DataFrame(Frame):
    cdef public:
        ObjectIndex columns
    
    cdef Series _handle_str(self, arg, int column)

    cdef Frame _handle_slice(self, slice arg)
        # cdef int start
        # cdef int stop
        # cdef int step
        
        # cdef list columns

cdef class Series(Frame):
    cdef public:
        str name

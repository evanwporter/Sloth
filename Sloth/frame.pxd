cimport numpy as np
from cpython cimport list, dict, str
from indexer cimport IntegerLocation, Location
from index cimport DateTimeIndex, _Index, ObjectIndex
cimport cython

cdef class Frame:
    cdef public:
        np.ndarray values_
        _Index index
        IntegerLocation iloc
        Location loc
        str reference
        int i
        dict extras
        bint extra
        

cdef class DataFrame(Frame):
    cdef public:
        ObjectIndex columns
    
    cdef inline Series _handle_str(self, arg)

    # cdef inline Frame _handle_slice(self, slice arg)
        # cdef int start
        # cdef int stop
        # cdef int step
        
        # cdef list columns
    
    cdef inline DataFrame _handle_array(self, arg)


cdef class Series(Frame):
    cdef public:
        str name
        object values

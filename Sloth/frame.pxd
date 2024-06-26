cimport numpy as np
from cpython cimport list, dict, str, slice
from .indexer cimport IntegerLocation, Location, iAT
from .index cimport DateTimeIndex, _Index, ObjectIndex
cimport cython

from .resample cimport Resampler
from .rolling cimport Rolling


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
        slice mask
        

cdef class DataFrame(Frame):
    cdef public:
        ObjectIndex columns
        iAT iat
    
    cdef inline Series _handle_str(self, arg)

    # cdef inline Frame _handle_slice(self, slice arg)
        # cdef int start
        # cdef int stop
        # cdef int step
        
        # cdef list columns
    
    cdef inline DataFrame _handle_array(self, arg)

    cdef DataFrame _handle_bool_array(self, np.ndarray[np.npy_bool, ndim=1] arg)

cdef class Series(Frame):
    cdef public:
        str name

    # cdef Series _quick_init(self, values)
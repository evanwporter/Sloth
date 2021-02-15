# cython: profile=True

cimport numpy as np 
import numpy as np
cimport cython

from cpython cimport dict

from cykhash.khashmaps cimport Int64to64Map#, Int64to32Map

from util cimport datetime64, indice

"""
Public Variables
(Displacement Compliant)
------------------------
  * keys
"""

cdef class _Index:
    @property
    def keys(self):
        return np.asarray(self.keys_)[self.FD: self.BD]

    def fast_init(self, displacement):
        index = self.__new__(self.__class__)
        index.keys_ = self.keys_
        index.reference = self.reference
        index.index = self.index
        index.FD = displacement[0]
        index.BD = displacement[1]

        return index

    # def __iter__(self):
        # return 
#     def __getitem__(self, arg):
#         return self.index[arg]


cdef class ObjectIndex(_Index):
    def __init__(self, object index):
        # Makes the index a numpy array
        self.keys_ = np.asarray(index)
        self._initialize()
        self.reference = "object"

    @cython.boundscheck(False)  # Deactivate bounds checking
    @cython.wraparound(False)   # Deactivate negative indexing.
    @cython.nonecheck(False)
    cdef inline void _initialize(self):
        cdef indice i
        cdef int length = len(self.keys_)
        
        self.FD = 0
        self.BD = length + 1

        # Because the index is a bunch of python objects
        # it will be stored in a python dictionary
        self.index = {}
        for i in range(length):
            self.index[self.keys_[i]] = i

    def get_item(self, arg):
        # Grabs the exact index location of arg
        ret = self.index[arg]

        # Ensures that the user is unable to access date outside of the
        # current scope of the dataframe
        if self.FD <= ret and ret <= self.BD:
            return ret
        raise KeyError("Invalid key: %s" % arg)

    # def set_item(self, arg, value):


cdef class DateTimeIndex(_Index):
    def __init__(self, index):
        """
        Index must be of type np.ndarray. If coming from a pandas 
        DatetimeIndex you can do index._data._data.
        """
        self.reference = "datetime"

        if isinstance(index, np.ndarray):
            self.keys_ = index.view(np.int64)
        else:
            self.keys_ = index
        self._initialize()

    @cython.boundscheck(False)  # Deactivate bounds checking
    @cython.wraparound(False)   # Deactivate negative indexing.
    @cython.nonecheck(False)
    cdef inline void _initialize(self):
        cdef indice i
        cdef int length = len(self.keys_)

        self.FD = 0
        self.BD = length

        # Use int64
        self.index = Int64to64Map(number_of_elements_hint=length, for_int=True)
        for i in range(length):
            self.index.put_int64(self.keys_[i], i)
    
    def get_item(self, arg):
        if not isinstance(arg, np.int64):
            arg = arg.astype(np.int64)

        ret = self.index[arg]
        if self.FD <= ret and ret <= self.BD:
            return ret
        raise KeyError("Invalid key: %s" % arg)

    # @property
    # def keys(self):
    #     return super().keys.astype("datetime64[ns]")

# cdef class IntervalIndex(_Index):
#     """
#     Using the equation:
#         x = (y - b) / m
#         where:
#             x: index 
#             y: index label
#             b: starting index value
#             m: interval
#     We can figure out the index of the row without having to go through
#     the lengthy process of looking up the key in a dictionary/hash table
#     """
#     def __init__(self, index=None, startIndex=None, interval=None):
#         if index is None and startIndex is None and interval is None:
#             raise TypeError("IntervalIndex needs at least one parameter to be given")
        
#         if startIndex is None:
#             self.startIndex = index[0]
#         if interval is None:
#             self.interval = index[1] - index[0]
    
#     def get_item(self, arg):


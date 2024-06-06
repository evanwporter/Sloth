# cython: profile=True

cimport numpy as np 
import numpy as np
cimport cython

from cpython cimport dict

from cykhash.khashmaps cimport Int64to64Map#, Int64to32Map

from .util cimport datetime64, timedelta64, indice, in_slice, interval_time_frame_to_timedelta

import pandas as pd

"""
Public Variables
(Displacement Compliant)
------------------------
  * keys
"""

cdef class _Index:
    @property
    def keys(self):
        """
        Returns the keys of the index.

        Returns
        -------
        np.ndarray
            Array of keys.

        Examples
        --------
        >>> idx = ObjectIndex(['a', 'b', 'c'])
        >>> idx.keys
        array(['a', 'b', 'c'], dtype='<U1')
        """
        return np.asarray(self.keys_)[self.mask]

    def fast_init(self, mask: slice):
        index = self.__new__(self.__class__)

        index.index = self.index
        index.keys_ = self.keys_

        index.mask = mask

        return index

    @property
    def size(self):
        """
        Returns the size of the index.

        Returns
        -------
        int
            The size of the index.

        Examples
        --------
        >>> idx = ObjectIndex(['a', 'b', 'c'])
        >>> idx.size
        3
        """
        return self.keys.size
    
    # def __setattr__(self, arg, value):
    #     if arg == "FD":
    #         raise AttributeError("Attribute 'FD' cannot be modified")
    #     if arg == "BD":
    #         raise AttributeError("Attribute 'BD' cannot be modified")
    #     setattr(self, arg, value)


    # def __iter__(self):
        # return 
#     def __getitem__(self, arg):
#         return self.index[arg]


cdef class ObjectIndex(_Index):
    """
    Initializes an ObjectIndex with the given index.

    Parameters
    ----------
    index : list
        List of objects to be indexed.

    Examples
    --------
    >>> idx = ObjectIndex(['a', 'b', 'c'])
    >>> idx.keys
    array(['a', 'b', 'c'], dtype='<U1')
    """
    def __init__(self, object index):
        # Makes the index a numpy array
        self.keys_ = np.asarray(index)
        self._initialize()
        self.reference = "object"
        self.mask = slice(0, len(self.keys_), 1)

    @cython.boundscheck(False)  # Deactivate bounds checking
    @cython.wraparound(False)   # Deactivate negative indexing.
    @cython.nonecheck(False)
    cdef inline void _initialize(self):
        cdef indice i
        cdef int length = len(self.keys_)

        # Because the index is a bunch of python objects
        # it will be stored in a python dictionary
        self.index = {}
        for i in range(length):
            self.index[self.keys_[i]] = i

    def get_item(self, arg):
        """
        Retrieves the exact index location of the given argument.

        Parameters
        ----------
        arg : object
            The key to retrieve the index for.

        Returns
        -------
        int
            The index of the key.

        Raises
        ------
        KeyError
            If the key is not found or invalid.

        Examples
        --------
        >>> idx = ObjectIndex(['a', 'b', 'c'])
        >>> idx.get_item('b')
        1
        >>> idx.get_item('d')
        KeyError: 'd is not a member of the index.'
        """
        # Grabs the exact index location of arg
        try:
            ret = self.index[arg]
        except KeyError:
            raise KeyError("%s is not a member of the index." % arg)

        if in_slice(ret, self.mask.start, self.mask.stop, self.mask.step):
            return ret
        raise KeyError("Invalid key: %s" % arg)

    # def set_item(self, arg, value):
    def to_pandas(self):
        return pd.Index(data=self.keys)
    
    def __contains__(self, item):
        return item in self.keys

    def __repr__(self):
        return f"ObjectIndex{repr(self.keys)[5:]}"


cdef class DateTimeIndex(_Index):
    def __init__(self, index):
        """
        Index must be of type np.ndarray. If coming from a pandas 
        DatetimeIndex you can do index._data._data.

        Parameters
        ----------
        index : np.ndarray
            Index array.
        """
        self.reference = "datetime"

        if isinstance(index, np.ndarray):
            self.keys_ = index.astype(np.int64)
        else:
            self.keys_ = index
        self._initialize()
    
    def to_pandas(self):
        return pd.DatetimeIndex(data=self.keys)

    @cython.boundscheck(False)  # Deactivate bounds checking
    @cython.wraparound(False)   # Deactivate negative indexing.
    @cython.nonecheck(False)
    cdef inline void _initialize(self):
        cdef indice i
        cdef int length = len(self.keys_)

        self.mask = slice(0, length, 1)

        # Use int64
        self.index = Int64to64Map(number_of_elements_hint=length, for_int=True)
        for i in range(length):
            self.index.put_int64(self.keys_[i], i)
    
    def get_item(self, arg):
        # Makes sure DateTime64 objects are in int64 format
        if isinstance(arg, np.datetime64):
            arg = np.datetime64(arg, "ns")
        if not isinstance(arg, np.int64):
            arg = np.int64(arg)
        return self.index.get_int64(int(arg))

    def __repr__(self):
        return "DateTimeIndex{}".format(repr(self.keys.astype("datetime64[ns]"))[5:])

cdef class _RangeIndexMixin(_Index):

    def get_item(self, arg):
        if not in_slice(arg, self.start, self.stop, self.step):
            raise KeyError("{} not in slice".format(arg))
        return int((arg - self.start) / self.step)

    @property
    def keys_(self):
        return np.arange(self.start, self.stop, self.step)

    @property
    def size(self):
        return self.stop - self.start

    def fast_init(self, mask: slice):
        index = self.__new__(self.__class__)

        index.start = mask.start
        index.stop = mask.stop
        index.step = mask.step

        return index

cdef class RangeIndex(_RangeIndexMixin):
    """
    Index that is roughly equivalent to numpy.arange().

    RangeIndex class provides ...

    Methods
    -------
    fast_init
        Quickly initializes a RangeIndex object.
    get_item
        Retrieves an item based on its index.
    to_pandas
        Converts the RangeIndex to a pandas Index object.

    Parameters
    ----------
    start : int
        Beginning position.
    stop : int
        End position.
    step : int
        How much to increase the range every step. Must be positive.
    """

    def __init__(self, start=0, stop=1, step=1):

        self.start = start
        self.stop = stop
        self.step = step

    def to_pandas(self):
        return pd.RangeIndex(start=self.start, stop=self.stop, step=self.step)

    def __repr__(self):
        return f"RangeIndex{repr(self.keys)[5:]}"

cdef class PeriodIndex(_RangeIndexMixin):
    """
    Index containing values of time along a regular period of time.

    Parameters
    ----------
    start: datetime-like
        Starting time in a range
    stop: datetime-like
        End time in the range
    freq: str
        How often to create point. ie: '1h', '4W', '200s'
    """
    def __init__(self, start, stop, freq):
        self.start = np.datetime64(start).astype("datetime64[ns]").astype("int64")
        self.stop = np.datetime64(stop).astype("datetime64[ns]").astype("int64")
        self.step = interval_time_frame_to_timedelta(freq)

        if (self.stop - self.start) % self.step != 0:
            raise KeyError("Step doesn't evenly divide start to stop")

    def to_pandas(self):
        return pd.PeriodIndex(data=[self.start, self.stop], freq=self.step)

    @property
    def freq(self):
        return self.step

    def __repr__(self):
        return f"PeriodIndex{repr(self.keys)[5:]}"
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
        """
        Quickly initializes an _Index object with a given mask.

        Parameters
        ----------
        mask : slice
            The mask to apply to the index.

        Returns
        -------
        _Index
            A new _Index object with the mask applied.

        Examples
        --------
        >>> idx = ObjectIndex(['a', 'b', 'c'])
        >>> new_idx = idx.fast_init(slice(1, 3))
        >>> new_idx.keys
        array(['b', 'c'], dtype='<U1')
        """
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
        try:
            ret = self.index[arg]
        except KeyError:
            raise KeyError("%s is not a member of the index." % arg)

        if in_slice(ret, self.mask.start, self.mask.stop, self.mask.step):
            return ret
        raise KeyError("Invalid key: %s" % arg)

    def to_pandas(self):
        """
        Converts the ObjectIndex to a pandas Index object.

        Returns
        -------
        pd.Index
            A pandas Index object.

        Examples
        --------
        >>> idx = ObjectIndex(['a', 'b', 'c'])
        >>> idx.to_pandas()
        Index(['a', 'b', 'c'], dtype='object')
        """
        return pd.Index(data=self.keys)

    def __contains__(self, item):
        """
        Checks if the item is in the index.

        Parameters
        ----------
        item : object
            The item to check.

        Returns
        -------
        bool
            True if the item is in the index, False otherwise.

        Examples
        --------
        >>> idx = ObjectIndex(['a', 'b', 'c'])
        >>> 'b' in idx
        True
        >>> 'd' in idx
        False
        """
        return item in self.keys

    def __repr__(self):
        """
        Returns the string representation of the ObjectIndex.

        Returns
        -------
        str
            The string representation of the ObjectIndex.

        Examples
        --------
        >>> idx = ObjectIndex(['a', 'b', 'c'])
        >>> repr(idx)
        "ObjectIndex(array(['a', 'b', 'c'], dtype='<U1'))"
        """
        return f"ObjectIndex{repr(self.keys)[5:]}"


cdef class DateTimeIndex(_Index):
    """
    Initializes a DateTimeIndex with the given index.

    Parameters
    ----------
    index : np.ndarray
        Index array.

    Examples
    --------
    >>> idx = DateTimeIndex(np.array(['2022-01-01', '2022-01-02', '2022-01-03'], dtype='datetime64'))
    >>> idx.keys
    array(['2022-01-01T00:00:00.000000000', '2022-01-02T00:00:00.000000000',
            '2022-01-03T00:00:00.000000000'], dtype='datetime64[ns]')
    """
    def __init__(self, index):
        self.reference = "datetime"

        if isinstance(index, np.ndarray):
            self.keys_ = index.astype(np.int64)
        else:
            self.keys_ = index
        self._initialize()
    
    def to_pandas(self):
        """
        Converts the DateTimeIndex to a pandas DatetimeIndex object.

        Returns
        -------
        pd.DatetimeIndex
            A pandas DatetimeIndex object.

        Examples
        --------
        >>> idx = DateTimeIndex(np.array(['2022-01-01', '2022-01-02', '2022-01-03'], dtype='datetime64'))
        >>> idx.to_pandas()
        DatetimeIndex(['2022-01-01', '2022-01-02', '2022-01-03'], dtype='datetime64[ns]', freq=None)
        """
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
        """
        Retrieves the exact index location of the given argument.

        Parameters
        ----------
        arg : np.datetime64 or int
            The key to retrieve the index for.

        Returns
        -------
        int
            The index of the key.

        Examples
        --------
        >>> idx = DateTimeIndex(np.array(['2022-01-01', '2022-01-02', '2022-01-03'], dtype='datetime64'))
        >>> idx.get_item(np.datetime64('2022-01-02'))
        1
        """
        if isinstance(arg, np.datetime64):
            arg = np.datetime64(arg, "ns")
        if not isinstance(arg, np.int64):
            arg = np.int64(arg)
        return self.index.get_int64(int(arg))

    def __repr__(self):
        """
        Returns the string representation of the DateTimeIndex.

        Returns
        -------
        str
            The string representation of the DateTimeIndex.

        Examples
        --------
        >>> idx = DateTimeIndex(np.array(['2022-01-01', '2022-01-02', '2022-01-03'], dtype='datetime64'))
        >>> repr(idx)
        "DateTimeIndex(array(['2022-01-01T00:00:00.000000000', '2022-01-02T00:00:00.000000000', '2022-01-03T00:00:00.000000000'], dtype='datetime64[ns]'))"
        """
        return "DateTimeIndex{}".format(repr(self.keys.astype("datetime64[ns]"))[5:])

cdef class _RangeIndexMixin(_Index):

    def get_item(self, arg):
        """
        Retrieves an item based on its index.

        Parameters
        ----------
        arg : int
            The item to retrieve.

        Returns
        -------
        int
            The index of the item.

        Raises
        ------
        KeyError
            If the item is not in the slice.

        Examples
        --------
        >>> idx = RangeIndex(0, 10, 2)
        >>> idx.get_item(4)
        2
        >>> idx.get_item(5)
        KeyError: '5 not in slice'
        """
        if not in_slice(arg, self.start, self.stop, self.step):
            raise KeyError("{} not in slice".format(arg))
        return int((arg - self.start) / self.step)

    @property
    def keys_(self):
        """
        Returns the keys of the range index.

        Returns
        -------
        np.ndarray
            Array of keys.

        Examples
        --------
        >>> idx = RangeIndex(0, 10, 2)
        >>> idx.keys_
        array([0, 2, 4, 6, 8])
        """
        return np.arange(self.start, self.stop, self.step)

    @property
    def size(self):
        """
        Returns the size of the range index.

        Returns
        -------
        int
            The size of the index.

        Examples
        --------
        >>> idx = RangeIndex(0, 10, 2)
        >>> idx.size
        10
        """
        return self.stop - self.start

    def fast_init(self, mask: slice):
        """
        Quickly initializes a RangeIndex object with a given mask.

        Parameters
        ----------
        mask : slice
            The mask to apply to the index.

        Returns
        -------
        _RangeIndexMixin
            A new _RangeIndexMixin object with the mask applied.

        Examples
        --------
        >>> idx = RangeIndex(0, 10, 2)
        >>> new_idx = idx.fast_init(slice(2, 8, 2))
        >>> new_idx.keys_
        array([2, 4, 6])
        """
        index = self.__new__(self.__class__)

        index.start = mask.start
        index.stop = mask.stop
        index.step = mask.step

        return index

cdef class RangeIndex(_RangeIndexMixin):
    """
    Index that is roughly equivalent to numpy.arange().

    Parameters
    ----------
    start : int
        Beginning position.
    stop : int
        End position.
    step : int
        How much to increase the range every step. Must be positive.

    Examples
    --------
    >>> idx = RangeIndex(0, 10, 2)
    >>> idx.keys_
    array([0, 2, 4, 6, 8])
    >>> idx.size
    10
    """

    def __init__(self, start=0, stop=1, step=1):

        self.start = start
        self.stop = stop
        self.step = step

    def to_pandas(self):
        """
        Converts the RangeIndex to a pandas Index object.

        Returns
        -------
        pd.RangeIndex
            A pandas RangeIndex object.

        Examples
        --------
        >>> idx = RangeIndex(0, 10, 2)
        >>> idx.to_pandas()
        RangeIndex(start=0, stop=10, step=2)
        """
        return pd.RangeIndex(start=self.start, stop=self.stop, step=self.step)

    def __repr__(self):
        """
        Returns the string representation of the RangeIndex.

        Returns
        -------
        str
            The string representation of the RangeIndex.

        Examples
        --------
        >>> idx = RangeIndex(0, 10, 2)
        >>> repr(idx)
        "RangeIndex(array([0, 2, 4, 6, 8]))"
        """
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

    Examples
    --------
    >>> idx = PeriodIndex('2022-01-01', '2022-01-10', '1d')
    >>> idx.keys_
    array(['2022-01-01', '2022-01-02', '2022-01-03', '2022-01-04',
           '2022-01-05', '2022-01-06', '2022-01-07', '2022-01-08',
           '2022-01-09'], dtype='datetime64[D]')
    """

    def __init__(self, start, stop, freq):
        self.start = np.datetime64(start).astype("datetime64[ns]").astype("int64")
        self.stop = np.datetime64(stop).astype("datetime64[ns]").astype("int64")
        self.step = interval_time_frame_to_timedelta(freq)

        if (self.stop - self.start) % self.step != 0:
            raise KeyError("Step doesn't evenly divide start to stop")

    def to_pandas(self):
        """
        Converts the PeriodIndex to a pandas PeriodIndex object.

        Returns
        -------
        pd.PeriodIndex
            A pandas PeriodIndex object.

        Examples
        --------
        >>> idx = PeriodIndex('2022-01-01', '2022-01-10', '1d')
        >>> idx.to_pandas()
        PeriodIndex(['2022-01-01', '2022-01-10'], dtype='period[1d]')
        """
        return pd.PeriodIndex(data=[self.start, self.stop], freq=self.step)

    @property
    def freq(self):
        """
        Returns the frequency of the period index.

        Returns
        -------
        int
            The frequency of the period index.

        Examples
        --------
        >>> idx = PeriodIndex('2022-01-01', '2022-01-10', '1d')
        >>> idx.freq
        numpy.timedelta64(86400000000000,'ns')
        """
        return self.step

    def __repr__(self):
        """
        Returns the string representation of the PeriodIndex.

        Returns
        -------
        str
            The string representation of the PeriodIndex.

        Examples
        --------
        >>> idx = PeriodIndex('2022-01-01', '2022-01-10', '1d')
        >>> repr(idx)
        "PeriodIndex(array(['2022-01-01', '2022-01-02', '2022-01-03', '2022-01-04',
                           '2022-01-05', '2022-01-06', '2022-01-07', '2022-01-08',
                           '2022-01-09'], dtype='datetime64[D]'))"
        """
        return f"PeriodIndex{repr(self.keys)[5:]}"

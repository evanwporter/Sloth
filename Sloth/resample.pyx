cimport numpy as np 
import numpy as np

from frame cimport Frame

import datetime
from index cimport DateTimeIndex
from util cimport datetime64, timedelta64


cdef class Resampler:
    def __init__(self, Frame frame, freq):

        self.frame = frame
        self.index = frame.index
        cdef datetime64[:] keys = self.index.keys

        cdef np.int64_t[:] bins = np.arange(keys[0], keys[-1], self._timedelta_to_ns(freq), dtype=np.int64)

        self.groups = np.unique(np.searchsorted(keys, bins))

    cdef timedelta64 _timedelta_to_ns(self, interval):
        """
        Convert timedelta to nanoseconds
        """
        if isinstance(interval, datetime.timedelta):
            # converts seconds to ns
            return interval.total_seconds * 1_000_000_000
        if isinstance(interval, np.timedelta64):
            return interval.astype("timedelta64[ns]").astype(np.int64)
    
    def __iter__(self):
        cdef int group
        for group in range(len(self.groups) - 1):
            ret = self.frame.iloc[self.groups[group]: self.groups[group + 1]]
            if ret.values.size != 0:
                yield ret
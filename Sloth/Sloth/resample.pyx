cimport numpy as np 
import numpy as np

from frame cimport Frame, Series, DataFrame

import datetime
from index cimport DateTimeIndex
from util cimport datetime64, timedelta64, ns_to_days, days_to_ns, weekday

from cpython cimport list


cdef class Resampler:
    def __init__(self, Frame frame, freq):

        self.frame = frame

        self.index, self.split_data = self._resample()
    
    def __iter__(self):
        cdef int group
        for group in range(len(self.groups) - 1):
            ret = self.frame.iloc[self.groups[group]: self.groups[group + 1]]
            if ret.values.size != 0:
                yield ret

    cdef inline _resample(self):
        cdef datetime64[:] index = self.frame.index.keys_
        
        cdef datetime64[:] bins = np.arange(
            start = index[0] - weekday(index[0]), 
            stop = index[-1] + (days_to_ns(7) - weekday(index[-1])), 
            step = np.timedelta64(1, "W").astype("timedelta64[ns]").astype("int64")
        )

        cdef list split_data = np.split(self.frame.Open.values, np.cumsum(
            np.bincount(np.digitize(index, bins, right=False))[1:]
        ))[:-1]

        return bins, split_data

    cdef inline mean(self):
        cdef int length = len(self.split_data)
        cdef double[:] data = np.zeros(length)
        
        for l in range(length):
            data[l] = np.average(self.split_data[l])
        
        return Series(np.asarray(data), index=np.asarray(self.index).astype("datetime64[ns]"))

    def __getattr__(self, arg):
        if arg == "mean":
            return self.mean()
 
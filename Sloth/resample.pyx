cimport numpy as np
import numpy as np

from frame cimport Frame, Series, DataFrame

import datetime
from index cimport DateTimeIndex
from util cimport datetime64, timedelta64, ns_to_days, days_to_ns, ceil_, floor_

from cpython cimport list

cdef class Resampler:
    def __init__(self, Frame frame, freq):
        self.frame = frame
        self.index, self.split_data = self._resample(freq)
    
    def __iter__(self):
        cdef int group
        for group in range(len(self.groups) - 1):
            ret = self.frame.iloc[self.groups[group]: self.groups[group + 1]]
            if ret.values.size != 0:
                yield ret

    cdef inline _resample(self, freq):
        cdef datetime64[:] index = self.frame.index.keys_

        interval = int(freq[:-1])
        timeframe = freq[-1]
        
        cdef datetime64[:] bins = np.arange(
            start=floor_(index[0], timeframe), 
            stop=ceil_(index[-1], timeframe), 
            step=np.timedelta64(interval, timeframe).astype("timedelta64[ns]").astype("int64")
        )

        cdef list split_data = np.split(self.frame.values, np.cumsum(
            np.bincount(np.digitize(index, bins, right=False))[1:]
        ))[:-1]

        return bins, split_data

    cdef inline mean(self):
        cdef int length = len(self.split_data)
        # TODO: Switch to Double[:, :] for consistency in typing
        cdef np.ndarray[np.float64_t, ndim=2] data = np.zeros((length, self.frame.shape[1]))
        cdef int l

        for l in range(length):
            split_data_array = np.asarray(self.split_data[l])

            if split_data_array.ndim == 1:
                # If split_data_array is 1-dimensional, reshape it to 2D for consistent handling
                split_data_array = split_data_array.reshape(1, -1)

            data[l] = np.mean(split_data_array, axis=0)
        
        return DataFrame(np.asarray(data), index=np.asarray(self.index).astype("datetime64[ns]"), columns=self.frame.columns)

    def __getattr__(self, arg):
        if arg == "mean":
            return self.mean()
        raise AttributeError(f"'Resampler' object has no attribute '{arg}'")


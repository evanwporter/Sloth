cimport numpy as np 
from util cimport datetime64, timedelta64, ns_to_days, days_to_ns, weekday

from frame cimport Frame, Series, DataFrame
from index cimport DateTimeIndex
from cpython cimport list


cdef class Resampler:
    cdef public:
        Frame frame
        
        datetime64[:] index
        list split_data
    
    cdef inline _resample(self)
    
    cdef inline mean(self)
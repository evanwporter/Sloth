cimport numpy as np 
from cpython cimport list, str, slice

# from conversions cimport conversions

ctypedef np.int64_t datetime64
ctypedef np.int64_t timedelta64

ctypedef np.uint64_t indice

cdef np.int64_t ns_to_days(np.int64_t ns)

cdef np.int64_t days_to_ns(np.int64_t days)

# cdef np.int64_t weekday(np.int64_t dt)

cdef datetime64 floor_(datetime64 dt, str timeframe)

cdef datetime64 ceil_(datetime64 dt, str timeframe)

# cdef (int, int, int) _normalize_slice(slice s, int length)

cdef bint in_slice(int number, int start, int stop, int step)

cdef timedelta64 interval_time_frame_to_timedelta(str freq)


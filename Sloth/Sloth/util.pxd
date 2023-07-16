cimport numpy as np 


ctypedef np.int64_t datetime64
ctypedef np.int64_t timedelta64

ctypedef np.uint64_t indice

cdef np.int64_t ns_to_days(np.int64_t ns)

cdef np.int64_t days_to_ns(np.int64_t days)

cdef np.int64_t weekday(np.int64_t dt)
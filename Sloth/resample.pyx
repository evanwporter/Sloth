cimport numpy as np
import numpy as np

from .frame cimport Frame, Series, DataFrame
import datetime
from .index cimport DateTimeIndex
from .util cimport datetime64, timedelta64, ns_to_days, days_to_ns, ceil_, floor_
from cpython cimport list

cdef class Resampler:
    """
    A class to resample a DataFrame or Series to a different frequency.
    
    Parameters
    ----------
    frame : Frame
        The frame to be resampled.
    freq : str
        The frequency to resample the data to (e.g., '5T' for 5 minutes).

    Attributes
    ----------
    frame : Frame
        The frame to be resampled.
    index : np.ndarray[datetime64]
        The resampled index.
    split_data : list of np.ndarray
        Data split according to the new frequency.

    Raises
    ------
    ValueError
        If the frequency string is not correctly formatted.

    Examples
    --------
    >>> frame = Frame(data, index=index)
    >>> resampler = Resampler(frame, '5T')
    >>> for group in resampler:
    ...     print(group)
    >>> mean_resampled = resampler.mean()
    >>> sum_resampled = resampler.sum()
    """
    def __init__(self, Frame frame, freq):

        self.frame = frame
        self.index, self.split_data = self._resample(freq)
    
    def __iter__(self):
        """
        Yields the resampled groups.

        Yields
        ------
        Frame
            Slices of the frame corresponding to the resampled groups.
        """
        cdef int group
        for group in range(len(self.groups) - 1):
            ret = self.frame.iloc[self.groups[group]: self.groups[group + 1]]
            if ret.values.size != 0:
                yield ret

    cdef inline _resample(self, freq):
        """
        Resamples the index of the frame to the specified frequency.

        Parameters
        ----------
        freq : str
            The frequency to resample the data to.

        Returns
        -------
        bins : np.ndarray[datetime64]
            The bins for the new resampled index.
        split_data : list of np.ndarray
            Data split according to the new frequency.

        Raises
        ------
        ValueError
            If the frequency string is not correctly formatted.
        """
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
        """
        Computes the mean for each resampled group.

        Returns
        -------
        DataFrame
            DataFrame containing the means of the resampled groups.

        Raises
        ------
        ValueError
            If the computation of mean fails.
        """
        cdef int length = len(self.split_data)
        cdef np.ndarray[np.float64_t, ndim=2] data = np.zeros((length, self.frame.shape[1]))
        cdef int l

        for l in range(length):
            split_data_array = np.asarray(self.split_data[l])

            if split_data_array.ndim == 1:
                # If split_data_array is 1-dimensional, reshape it to 2D for consistent handling
                split_data_array = split_data_array.reshape(1, -1)

            data[l] = np.mean(split_data_array, axis=0)
        
        return DataFrame(np.asarray(data), index=np.asarray(self.index).astype("datetime64[ns]"), columns=self.frame.columns)

    cdef inline sum(self):
        """
        Computes the sum for each resampled group.

        Returns
        -------
        DataFrame
            DataFrame containing the sums of the resampled groups.

        Raises
        ------
        ValueError
            If the computation of sum fails.
        """
        cdef int length = len(self.split_data)
        cdef np.ndarray[np.float64_t, ndim=2] data = np.zeros((length, self.frame.shape[1]))
        cdef int l

        for l in range(length):
            data[l] = np.sum(self.split_data[l], axis=0)

        return DataFrame(np.asarray(data), index=np.asarray(self.index).astype("datetime64[ns]"), columns=self.frame.columns)

    def __getattr__(self, arg):
        """
        Handles attribute access for mean and sum.

        Parameters
        ----------
        arg : str
            The attribute to access.

        Returns
        -------
        method : function
            The corresponding method for 'mean' or 'sum'.

        Raises
        ------
        AttributeError
            If the requested attribute is not 'mean' or 'sum'.
        """
        if arg == "mean":
            return self.mean()
        elif arg == "sum":
            return self.sum()
        raise AttributeError(f"'Resampler' object has no attribute '{arg}'")

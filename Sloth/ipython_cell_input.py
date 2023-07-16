from frame import DataFrame
import pandas as pd
import numpy as np

pdf = pd.read_csv(r"C:\Users\evanw\OneDrive\Desktop\AT\Data\GOOG.csv", index_col=0)
pdf.index = pd.to_datetime(pdf.index)

df = DataFrame.from_pandas(pdf)

def weekday(dt):
    return (dt.astype('datetime64[D]').view('int64') - 3) % 7

def resample(frame):
    x = np.asarray(frame.index.keys_)
    r = x[0]
    start = (r.astype('datetime64[D]').view('int64') - weekday(r)).astype("datetime64[D]")
    
    td = np.timedelta64(1, "W").astype("timedelta64[ns]").astype("int64")
    
    bins = np.arange(start=start, stop=x[-1], step=td)
    d = np.digitize(x.astype(np.int64), bins.astype(np.int64), right=True)
    count = np.bincount(d)[1:]
    s = np.cumsum(count)
    splitted = np.split(frame.Open.values, s)[:-1]
    
    length = len(splitted)
    ret = np.zeros(length)
    for l in range(length):
        ret[l] = np.average(splitted[l])
        
fatso = resample(df)

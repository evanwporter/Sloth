from frame import DataFrame as df

import pandas as pd
import numpy as np

x = r"C:\Users\evanh\Projects\AT\Data\Binance-BTCUSDT.csv"
pddf = pd.read_csv(x, index_col=0)#, parse_dates=True)

data = df(pddf.values, index=pddf.index._data, columns=pddf.columns._data)
print((data.iloc[5:7]))

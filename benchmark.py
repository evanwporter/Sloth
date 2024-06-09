"""
pytest benchmark.py --benchmark-save=benchmark.json
"""

import pandas as pd
import numpy as np
import pytest

import Sloth as sl

pdf = pd.read_csv(r"GOOG.csv", index_col=0, parse_dates=True, infer_datetime_format=True)
sdf = sl.DataFrame.from_pandas(pdf)

@pytest.mark.benchmark(group="iloc")
def test_pandas_iloc(benchmark):
    result = benchmark(lambda: pdf.Open.iloc[10:-10:2].iloc[44:100].iloc[10])
    assert result is not None

@pytest.mark.benchmark(group="iloc")
def test_sloth_iloc(benchmark):
    result = benchmark(lambda: sdf.Open.iloc[10:-10:2].iloc[44:100].iloc[10])
    assert result is not None

@pytest.mark.benchmark(group="rolling mean")
def test_pandas_rolling(benchmark):
    result = benchmark(lambda: pdf.rolling(window=10).mean())
    assert result is not None

@pytest.mark.benchmark(group="rolling mean")
def test_sloth_rolling(benchmark):
    result = benchmark(lambda: sdf.rolling(10).mean())
    assert result is not None

@pytest.mark.benchmark(group="resample mean")
def test_pandas_resample(benchmark):
    result = benchmark(lambda: pdf.resample("1W").sum())
    assert result is not None

@pytest.mark.benchmark(group="resample mean")
def test_sloth_resample(benchmark):
    result = benchmark(lambda: sdf.resample("1W").sum)
    assert result is not None

# @pytest.mark.benchmark(group="mean")
# def test_pandas_mean(benchmark):
#     result = benchmark(lambda: pandas_df['A'].mean())
#     assert result is not None

# @pytest.mark.benchmark(group="mean")
# def test_sloth_mean(benchmark):
#     result = benchmark(lambda: sloth_df['A'].mean())
#     assert result is not None

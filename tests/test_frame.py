import numpy as np
import pandas as pd
import Sloth as sl


def test_series_initialization():
    values = np.array([1, 2, 3])
    index = np.array(["a", "b", "c"])
    series = sl.Series(values, index)
    assert np.array_equal(series.values, values)
    assert series.shape == (3,)


def test_series_operations():
    values = np.array([1, 2, 3])
    series = sl.Series(values, None)
    assert np.array_equal((series + 2).values, [3, 4, 5])
    assert np.array_equal((series - 1).values, [0, 1, 2])
    assert np.array_equal((series * 2).values, [2, 4, 6])
    # assert np.array_equal((series / 2).values, [0.5, 1.0, 1.5])


def test_dataframe_initialization():
    values = np.array([[1, 2], [3, 4]])
    index = ["row1", "row2"]
    columns = ["col1", "col2"]
    df = sl.DataFrame(values, index=index, columns=columns)
    assert np.array_equal(df.values, values)
    assert df.shape == (2, 2)


def test_dataframe_get_item():
    values = np.array([[1, 2], [3, 4]])
    index = ["row1", "row2"]
    columns = ["col1", "col2"]
    df = sl.DataFrame(values, index=index, columns=columns)
    col1 = df["col1"]
    assert np.array_equal(col1.values, [1, 3])
    assert col1.name == "col1"


# def test_dataframe_set_item():
#     values = np.array([[1, 2], [3, 4]])
#     index = ["row1", "row2"]
#     columns = ["col1", "col2"]
#     df = sl.DataFrame(values, index=index, columns=columns)
#     df["col3"] = [5, 6]
#     assert np.array_equal(df.values, [[1, 2, 5], [3, 4, 6]])
#     assert "col3" in df.columns.index


def test_dataframe_to_pandas():
    values = np.array([[1, 2], [3, 4]])
    index = ["row1", "row2"]
    columns = ["col1", "col2"]
    df = sl.DataFrame(values, index=index, columns=columns)
    pandas_df = df.to_pandas()
    expected_df = pd.DataFrame(values, index=index, columns=columns)
    pd.testing.assert_frame_equal(pandas_df, expected_df)


# def test_dataframe_from_pandas():
#     pandas_df = pd.DataFrame({"A": [1, 2], "B": [3, 4]})
#     df = sl.DataFrame.from_pandas(pandas_df)
#     assert np.array_equal(df.values, pandas_df.to_numpy())
#     assert np.array_equal(df.columns.index, pandas_df.columns.to_numpy())

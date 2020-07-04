import os
import numpy as np
import pandas as pd
import statsmodels.api as sm
import matplotlib.pyplot as plt
import math
import traceback

abs_path = os.path.dirname(os.path.abspath(__file__))


def cal_tradeline(code):
    """
    see: https://www.jianshu.com/p/e55a8c9e4b56
    """
    print(f"calculating {code}")
    df = pd.read_csv(f"{abs_path}/../navs/{code}.csv", header=None,
                     usecols=[3, 5, 6],
                     names=['date', 'net_value', 'accumulative_value']
                     )
    df = df.loc[df['accumulative_value'].notnull()]
    df = df.reset_index(drop=True)
    df.head()
    df['new_index'] = df.index
    y = df.accumulative_value
    x = df.new_index
    x = sm.add_constant(x)
    est = sm.OLS(y, x)
    est = est.fit()
    #print(df)
    #print(est.summary())
    #print(est.params)
    indexes = df.index.values
    indexes_values = sm.add_constant(indexes)
    avg_line = est.predict(indexes_values)

    # y = ax + b
    # ax - y + b =0
    # distance = a*x0 - y0 + b / sqrt(a*a + 1)
    pos_count = 0
    pos_x_sum = 0.0
    pos_y_sum = 0.0
    neg_count = 0
    neg_x_sum = 0.0
    neg_y_sum = 0.0

    for index, row in df.iterrows():
        distance = (est.params.new_index * row['new_index'] - row['accumulative_value']
                    + est.params.const)
        if distance >= 0:
            pos_count += 1
            pos_x_sum += row['new_index']
            pos_y_sum += row['accumulative_value']
        else:
            neg_count += 1
            neg_x_sum += row['new_index']
            neg_y_sum += row['accumulative_value']

    # ax_pct + b2 = y_pct
    print(f"a: {est.params.new_index}")
    print(f"b: {est.params.const}")
    print(f"pos_count: {pos_count}")
    print(f"neg_count: {neg_count}")
    pct_80_x = pos_x_sum / pos_count
    pct_80_y = pos_y_sum / pos_count
    pct_20_x = neg_x_sum / neg_count
    pct_20_y = neg_y_sum / neg_count
    print(f"pct_80_x: {pct_80_x}")
    print(f"pct_80_y: {pct_80_y}")
    print(f"pct_20_x: {pct_20_x}")
    print(f"pct_20_y: {pct_20_y}")

    b_80 = pct_80_y - pct_80_x * est.params.new_index
    b_80_delta = b_80 - est.params.const
    b_20 = pct_20_y - pct_20_x * est.params.new_index
    b_20_delta = b_20 - est.params.const

    pct_80_line = [(v + b_80_delta) for v in avg_line]
    pct_20_line = [(v + b_20_delta) for v in avg_line]

    with open(f"{abs_path}/../anav_stats/{code}.csv", 'w') as fp:
        for index, row in df.iterrows():
            date = row['date']
            write_row = "%s,%.6f,%.6f,%.6f" % (date,
                                               avg_line[index],
                                               pct_80_line[index],
                                               pct_20_line[index])
            fp.write(write_row + "\n")


def main():
    print("hahah")
    with open(f"{abs_path}/watch_funds.txt", "r") as fp:
        for line in fp:
            line = line.strip()
            if not line:
                continue
            try:
                cal_tradeline(line)
            except:
                traceback.print_exc()


if __name__ == "__main__":
    main()

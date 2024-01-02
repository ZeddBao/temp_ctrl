import pandas as pd
import matplotlib.pyplot as plt

# 获取 ./output_files 目录下所有的 csv 文件列表
import glob
csv_files = glob.glob('./output_files/*.csv')
# 获得文件名列表（去掉.csv以及父目录路径）
csv_files = [csv_files[i] for i in [6]]

for i, csv_file in enumerate(csv_files):
    data = []
    with open(csv_file, 'r') as f:
        lines = f.readlines()
        for line in lines:
            columns = line.rstrip('\n').split(',')  # 根据逗号分割，如有需要请调整分隔符
            data.append(columns)

    # 转换为 DataFrame
    df = pd.DataFrame(data)

    # 确保数据是数值类型
    df = df.apply(pd.to_numeric, errors='coerce')

    # 提取第一列和第二列数据，注意：Python 的索引是从 0 开始的，所以这里用 0 和 1 代替原来的 1 和 2
    t = df[0][7:120]
    y = df[1][7:120]

    plt.plot(t, y)
    plt.xlabel('time')
    plt.ylabel('temperature')
    # 显示图形
    # plt.show()
    # 保存图片

plt.savefig(f'./result/30-40')
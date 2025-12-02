# -*- coding: utf-8 -*-

# python3 main.py ../../fixtures/4-保定标卡1020_filtered-no-r.csv 5 6 7 8 9 10 11 12 13 14

import csv
import sys
import os

def melt_csv_columns(input_path, melt_col_indices, output_path=None):
    if not os.path.isfile(input_path):
        print(f"错误：文件 '{input_path}' 不存在。", file=sys.stderr)
        sys.exit(1)

    # 去重并保持顺序
    melt_col_indices = list(dict.fromkeys(melt_col_indices))
    if not melt_col_indices:
        print("错误：至少需要指定一个要打散的列序号。", file=sys.stderr)
        sys.exit(1)

    if output_path is None:
        base, ext = os.path.splitext(input_path)
        output_path = f"{base}_melted{ext}"

    with open(input_path, 'r', newline='', encoding='utf-8') as infile, \
         open(output_path, 'w', newline='', encoding='utf-8') as outfile:

        reader = csv.reader(infile)
        writer = csv.writer(outfile)

        header = next(reader)  # 读取表头

        # 验证列索引是否有效
        max_idx = len(header) - 1
        for idx in melt_col_indices:
            if idx < 0 or idx > max_idx:
                print(f"错误：列序号 {idx} 超出范围（有效范围：0-{max_idx}）", file=sys.stderr)
                sys.exit(1)

        # 确定保留的列（非打散列）
        keep_indices = [i for i in range(len(header)) if i not in melt_col_indices]

        # 写出新表头
        new_header = [header[i] for i in keep_indices] + ['k', 'v']
        writer.writerow(new_header)

        # 处理每一行数据
        for row in reader:
            # 补齐行长度（防止某些行列数不足）
            while len(row) < len(header):
                row.append('')
            # 如果行太长，截断（可选）
            if len(row) > len(header):
                row = row[:len(header)]

            keep_values = [row[i] for i in keep_indices]

            for idx in melt_col_indices:
                k = header[idx]
                v = row[idx]
                writer.writerow(keep_values + [k, v])

    print(f"✅ 已生成打散后的 CSV: {output_path}")

def main():
    if len(sys.argv) < 3:
        print("用法: python melt_csv_columns.py <csv文件路径> <列序号1> <列序号2> ...")
        print("示例: python melt_csv_columns.py data.csv 3 4 5")
        sys.exit(1)

    input_file = sys.argv[1]
    try:
        col_indices = [int(x) for x in sys.argv[2:]]
    except ValueError:
        print("错误：列序号必须是整数。", file=sys.stderr)
        sys.exit(1)

    melt_csv_columns(input_file, col_indices)

if __name__ == "__main__":
    main()
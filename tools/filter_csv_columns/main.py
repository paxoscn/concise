# -*- coding: utf-8 -*-

# python3 main.py ../../fixtures/4-保定标卡1020.csv 0 1 2 3 12 19 20 21 22 23 24 25 26 27 28

import csv
import sys
import os

def filter_csv_columns(input_path, col_indices, output_path=None):
    if not os.path.isfile(input_path):
        print(f"错误：文件 '{input_path}' 不存在。", file=sys.stderr)
        sys.exit(1)

    # 排序并去重列索引（可选，保持顺序按用户输入）
    col_indices = list(dict.fromkeys(col_indices))  # 保留输入顺序去重

    if output_path is None:
        base, ext = os.path.splitext(input_path)
        output_path = f"{base}_filtered{ext}"

    with open(input_path, 'r', newline='', encoding='utf-8') as infile, \
         open(output_path, 'w', newline='', encoding='utf-8') as outfile:

        reader = csv.reader(infile)
        writer = csv.writer(outfile)

        for row_num, row in enumerate(reader, start=1):
            # 检查列索引是否超出范围
            max_col = len(row) - 1
            for idx in col_indices:
                if idx < 0 or idx > max_col:
                    print(f"警告：第 {row_num} 行没有第 {idx} 列（该行共 {len(row)} 列），跳过该列。", file=sys.stderr)
            
            # 只保留有效列
            filtered_row = [row[i] for i in col_indices if 0 <= i < len(row)]
            writer.writerow(filtered_row)

    print(f"✅ 已保存筛选后的 CSV 到: {output_path}")

def main():
    if len(sys.argv) < 3:
        print("用法: python filter_csv_columns.py <csv文件路径> <列序号1> <列序号2> ...")
        print("示例: python filter_csv_columns.py data.csv 0 2 4")
        sys.exit(1)

    input_file = sys.argv[1]
    try:
        col_indices = [int(x) for x in sys.argv[2:]]
    except ValueError:
        print("错误：列序号必须是整数。", file=sys.stderr)
        sys.exit(1)

    if not col_indices:
        print("错误：至少需要指定一个列序号。", file=sys.stderr)
        sys.exit(1)

    filter_csv_columns(input_file, col_indices)

if __name__ == "__main__":
    main()
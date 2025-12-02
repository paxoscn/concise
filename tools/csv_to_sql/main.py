# -*- coding: utf-8 -*-

# python3 main.py ../../fixtures/dwd_store_common_commodity_di_1d.csv dwd_store_common_commodity_di_1d 20251130 ../../fixtures/dwd_store_common_commodity_di_1d.sql

import csv
import sys
import os

def escape_sql_value(value):
    """对字符串值进行基本SQL转义（仅处理单引号）"""
    if value is None:
        return 'NULL'
    if isinstance(value, str):
        value = value[:255]
        # 转义单引号：' → ''
        return "'" + value.replace("'", "''") + "'"
    else:
        return "'" + str(value).replace("'", "''") + "'"

def csv_to_insert_sql(csv_file_path, table_name, dt_value=None, output_file=None):
    """
    将CSV文件转换为INSERT SQL语句
    
    :param csv_file_path: CSV文件路径
    :param table_name: 目标表名
    :param dt_value: 可选，分区字段 dt 的值（如 '2025-11-30'）
    :param output_file: 输出SQL文件路径，若为None则打印到stdout
    """
    with open(csv_file_path, 'r', encoding='utf-8-sig') as f:
        # reader = csv.reader(f, delimiter='\t')
        reader = csv.reader(f)

        lines = []
        for row in reader:
            # 处理空行
            if not row:
                continue
            if dt_value is not None:
                row.append(dt_value)

            values = [escape_sql_value(cell) for cell in row]
            values_str = 'DEFAULT, ' + ', '.join(values)
            sql = f"INSERT INTO {table_name} VALUES ({values_str});"
            lines.append(sql)

        output_content = '\n'.join(lines) + '\n'

        if output_file:
            with open(output_file, 'w', encoding='utf-8') as out_f:
                out_f.write(output_content)
            print(f"✅ 已生成 {len(lines)} 条 INSERT 语句，保存至: {output_file}")
        else:
            print(output_content)

def main():
    if len(sys.argv) < 3:
        print("用法: python3 csv_to_insert_sql.py <csv文件路径> <表名> [dt值] [输出sql文件路径]")
        print("示例: python3 csv_to_insert_sql.py data.csv product_channel_info 2025-11-30 output.sql")
        sys.exit(1)

    csv_file = sys.argv[1]
    table_name = sys.argv[2]
    dt_value = sys.argv[3] if len(sys.argv) > 3 else None
    output_file = sys.argv[4] if len(sys.argv) > 4 else None

    if not os.path.isfile(csv_file):
        print(f"❌ 错误: CSV文件不存在 - {csv_file}")
        sys.exit(1)

    csv_to_insert_sql(csv_file, table_name, dt_value, output_file)

if __name__ == '__main__':
    main()
#!/bin/bash

# 测试数据上传接口
# 使用方法: ./test_upload_data.sh <data_table_id> <excel_file_path> [partition_field1=value1] [partition_field2=value2] ...

# 检查参数
if [ $# -lt 2 ]; then
    echo "Usage: $0 <data_table_id> <excel_file_path> [partition_field1=value1] [partition_field2=value2] ..."
    echo "Example: $0 table-123 data.xlsx week=2024-W01 region=north"
    exit 1
fi

DATA_TABLE_ID=$1
EXCEL_FILE=$2
shift 2

# 检查文件是否存在
if [ ! -f "$EXCEL_FILE" ]; then
    echo "Error: File '$EXCEL_FILE' not found"
    exit 1
fi

# 构建 curl 命令
CURL_CMD="curl -X POST http://localhost:8080/api/v1/data-tables/${DATA_TABLE_ID}/upload"
CURL_CMD="$CURL_CMD -F \"file=@${EXCEL_FILE}\""

# 添加分区字段参数
for partition in "$@"; do
    # 解析 field=value 格式
    if [[ $partition =~ ^([^=]+)=(.+)$ ]]; then
        field="${BASH_REMATCH[1]}"
        value="${BASH_REMATCH[2]}"
        CURL_CMD="$CURL_CMD -F \"partition_${field}=${value}\""
    else
        echo "Warning: Invalid partition format '$partition', expected 'field=value'"
    fi
done

# 执行请求
echo "Uploading data to table: $DATA_TABLE_ID"
echo "File: $EXCEL_FILE"
echo "Command: $CURL_CMD"
echo ""

eval $CURL_CMD

echo ""
echo "Upload complete"

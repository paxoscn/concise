实现一个数据湖仓. 包含后端和前端代码. 后端使用Rust单实例, 不要拆分微服务, 数据库使用mysql.

实体包括:
结构化数据源: 包含名称, 数据库类型和数据库连接常用属性;
数据存储: 包含名称, 类型, 上传域名, 下载域名和认证信息;
任务: 任务不需要存储数据库, 有外部的任务中心负责维护任务, 本系统只需通过reqwest访问其接口实现任务增删改查即可.
用户: 包含昵称, 密码;

提供接口包括:
任务执行接口: 接收任务类型和任务元数据, 能够根据任务类型选择执行器进行执行. 执行器上下文可以对所有结构化数据源和数据存储进行访问. 执行结束后根据任务元数据中的依赖信息执行下一步动作.
认证接口: 传入昵称和密码, 认证成功后在token中附带用户ID及昵称.
结构化数据源增删改查接口.
数据存储增删改查接口.

执行器包括:
SQL执行器: 执行SQL语句;
Excel执行器: 将Excel文件内容写入指定数据源中的数据表, 每个sheet写一张表.

数据库访问层需要使用SeaORM. 业务逻辑严格限制在领域层.

前端需要能管理结构化数据源和数据存储, 能管理任务.
前端还需提供苹果风格的首页, 包含基本的登录表单.

后端推荐依赖:
# Web framework
axum = { version = "0.8.5", features = ["multipart"] }
tokio = { version = "1.0", features = ["full"] }
tower = "0.5"
tower-http = { version = "0.6", features = ["cors", "trace", "fs"] }
http = "1.0"
# Database and ORM
sea-orm = { version = "1.1.17", features = ["sqlx-mysql", "runtime-tokio-rustls", "macros", "debug-print"] }
sea-orm-migration = "1.1.17"
# Redis
redis = { version = "0.21", features = ["tokio-comp"] }
# Serialization
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
# UUID and time
uuid = { version = "1.0", features = ["v4", "serde"] }
chrono = { version = "0.4", features = ["serde"] }
url = "2.4"
# Error handling
thiserror = "1.0"
# Async traits
async-trait = "0.1"
futures = "0.3"
# HTTP client
reqwest = { version = "0.11", default_features = false, features = ["json", "stream", "rustls-tls"] }
bytes = "1.0"
# Configuration
config = "0.13"
# Logging
log = "0.4"
tklog = "0.3.0"
# Authentication
bcrypt = "0.15"
jsonwebtoken = "9.3"

---

(tongyi)
写一个python脚本, 将输入的csv转成insert sql语句

---

(tongyi)
根据这个CSV表头生成mysql建表语句, 表头文字放到COMMENT中. ID外的所有数据字段类型均为VARCHAR(255) NOT NULL, 再追加一个分区字段dt, 不需要索引:
门店名称	门店编码	海博门店id	商品名称	海博商品ID	商品编码	条形码	规格	单位	京东秒送渠道售价	美团渠道售价	饿了么渠道售价	会员价	线上可售库存	前台类目	京东秒送售卖状态	美团售卖状态	饿了么售卖状态	全渠道永久停售状态	无库存可售	商品级别	0	线下品售卖状态	是否清单商品	美团起购数	饿了么起购数	京东秒送起购数	京东秒送起购数	商品标签	30日日均销量	14日日均销量	7日日均销量	3日日均销量	30日总销量	14日总销量	7日总销量	3日总销量	创建时间	最新更新时间	美团门店商品名称	饿了么门店商品名称	SPUID	毛重	美团毛重	图片	自定义商品属性	有无图文描述	引用美团标库	副标题

---

(tongyi)
根据这个CSV表头生成mysql建表语句, 表头文字放到COMMENT中. ID外的所有数据字段类型均为VARCHAR(255) NOT NULL, 再追加一个分区字段dt, 不需要索引:
商品名称	海博商品ID	商品编码	条形码	活动渠道	门店名称	活动名称	ERP促销单号	线下原售价	起购数	促销加价率	促销价	活动开始时间	活动结束时间	循环周期	活动状态	京东秒送限购	美团限购	饿了么限购	抖音限购	淘宝买菜限购

---

(tongyi)
根据这个CSV表头生成mysql建表语句, 表头文字放到COMMENT中. ID外的所有数据字段类型均为VARCHAR(255) NOT NULL, 再追加一个分区字段dt, 不需要索引:
大类	一级类目	三级类目	一级分类	二级分类	商品名称	规格	sku_id	商品ID	upc码	现价	原价	商品预估价	活动价	到手价	商品折扣	优惠券	商品月售	库存	包装费	起订	店铺名称	日期	交易额	补贴额	参考货值

---

(tongyi)
根据这个CSV表头生成mysql建表语句, 表头文字放到COMMENT中. ID外的所有数据字段类型均为VARCHAR(255) NOT NULL, 再追加一个分区字段dt, 不需要索引:
海博商品ID	商品编码	城市商品名称	规格	一级类目	二级类目	三级类目	是否计算在途	门店-最低安全库存数	门店-箱规	门店-最小起订量	门店-起订单位	UPC	负责人	是否进大仓	是否组合商品（如果是组合商品中的母商品填写子商品sku，子商品填是，其他情况填否）	商品级别	建品日期	商品效期	是否新品	实际上线时间	大仓-是否可退	门店-否可退	采销负责人	品牌	SPU	商品大类	下线商品标签	是否需要二类医疗资质	售价	供应链级别（0代表厂商，1代表1级经销，2代表二批，3代表线上）	预计店均月销量（必填）	三级类目级别	是否秋冬三级类目	是否秋冬重点商品

---

(tongyi)
根据这个CSV表头生成mysql建表语句, 表头文字放到COMMENT中. ID外的所有数据字段类型均为VARCHAR(255) NOT NULL, 再追加一个分区字段dt, 不需要索引:
日期	门店分组	门店名称	品牌	渠道名称	二级类目	标签	仓店商品编码	商品名称	相关订单量	渠道店订单量	订单渗透率	商品原价金额	商品数量	商品商家补贴	商品活动成本占比	商品毛利额	商品毛利率	商品净利额	商品净利率	佣金	订单营收	订单毛利额	订单毛利率	订单配送成本	订单配送成本占比	商家活动成本	商家活动成本占比	订单客单价	其他费用

---

(tongyi)
根据这个CSV表头生成mysql建表语句, 表头文字放到COMMENT中. ID外的所有数据字段类型均为VARCHAR(255) NOT NULL, 再追加一个分区字段dt, 不需要索引:
一级类目名称	二级类目名称	三级类目名称	三级类目id	必填销售属性	可选销售属性	可选销售属性的使用数量上限	是否支持生产日期

---

(tongyi)
写一个python脚本, 输入csv路径和需要保留的多个列序号, 输出只保留指定序列号的csv

---

(tongyi)
写一个python脚本, 输入csv路径和多个列序号, 将这些列的列名和数据打散到每一行的结尾.
例如:
输入csv:
a,b,c,d1,d2,d3
1,2,3,10,20,30
输入列序号:
3 4 5
输出csv:
a,b,c,k,v
1,2,3,d1,10
1,2,3,d2,20
1,2,3,d3,30

---

增加一个数据查询接口, 接收json请求, 根据json中的view属性选择对应的策略来输入json请求中的spec对象并输出处理后的json, 每个策略放到一个rust文件中.
每个策略都需要接收该租户下所有数据源名称到sqlx数据库连接的hashmap, 租户ID以及json请求中的params和spec对象.
租户ID来自该接口请求的header, 该接口不需要认证.

请求示例:
header: tenant_id=1
body: {
    "view": "comparable_card",
    "params": {
        "start": "20250101",
        "end": "20250201"
    },
    "spec": {
        "xxx": "yyy"
    }
}

---

在QueryContext中增加一个方法, 根据spec中的sql属性和params中的所有参数生成sqlx的Query.
例如:
spec.sql:
```sql
SELECT 
    IF(s.shop_name = '', 'self', s.shop_name) merchant_name,
    SUM(COLLAPSE(s.transaction_amount, 0)) transaction_amount
FROM
    default_datasource.dwd_rival_stats_distincted_di_1d s
WHERE
    s.date_str BETWEEN {start} AND {end}
    AND s.category_level1 = {category_level1}
    <shop_names:AND s.shop_name IN {shop_names}>
GROUP BY
    s.shop_name
```
"<foo:bar>"表示当参数foo存在时才包含内容bar.

params示例1:
```json
{
    "start": "20250101",
    "end": "20250201",
    "category_level1": "1"
}
```
生成的Query示例1:
```rust
sqlx::query(r#"
        SELECT 
            IF(s.shop_name = '', 'self', s.shop_name) merchant_name,
            SUM(COLLAPSE(s.transaction_amount, 0)) transaction_amount
        FROM
            default_datasource.dwd_rival_stats_distincted_di_1d s
        WHERE
            s.date_str BETWEEN ? AND ?
            AND s.category_level1 = ?
        GROUP BY
            s.shop_name
    "#;)
    .bind(start)
    .bind(end)
    .bind(category_level1)
```
params示例2:
```json
{
    "start": "20250101",
    "end": "20250201",
    "category_level1": "1",
    "shop_names": [ "1", "2", "3" ]
}
```
生成的Query示例2:
```rust
sqlx::query(r#"
        SELECT 
            IF(s.shop_name = '', 'self', s.shop_name) merchant_name,
            SUM(COLLAPSE(s.transaction_amount, 0)) transaction_amount
        FROM
            default_datasource.dwd_rival_stats_distincted_di_1d s
        WHERE
            s.date_str BETWEEN ? AND ?
            AND s.category_level1 = ?
            AND s.shop_name IN ?
        GROUP BY
            s.shop_name
    "#;)
    .bind(start)
    .bind(end)
    .bind(category_level1)
    .bind(shop_names)
```

---

增加一个实体: view. 包含以下属性:
tenant_id: 租户ID
view_code: view的唯一编码
view_type: view的类型. 如comparable_card等
view_sql: view的查询SQL

---

(tongyi)
postgres将以下数据:

aaa,w1,111
aaa,w2,222
bbb,w1,333
bbb,w2,444

转成:

aaa,{w1:{v:111,delta:0},w2:{v:222,delta:111}}
bbb,{w1:{v:333,delta:0},w2:{v:444,delta:111}}

---

(tongyi)
postgres生成一张表, 列分别是date_str, date_index, week_index, month_index, 分别填入日期, 此日期距离当天的天数, 此日期距离当天的周数, 此日期距离当天的月数, 一共生成180行. 例如: 假定今天是20251231星期三, 则生成数据如下:

20251231,0,0,0
20251230,1,0,0
20251229,2,0,0
20251228,3,1,0
20251227,4,1,0
20251226,5,1,0
20251225,6,1,0
20251224,7,1,0
20251223,8,1,0
...


---

(tongyi)
写一段rust代码, 需要能将以下json:

```json
{
    "data": {
        "rows": [
            {
                "available_commodity_count": 647,
                "category_large": "耐用品",
                "category_level1": "彩妆香水",
                "metrics_by_period": "{ \"p0\": { \"product_original_amount\": 1036.7, \"product_original_amount_last\": 1070.5, \"product_original_amount_delta\": -33.80005, \"product_original_amount_wow\": -0.031574078 }, \"p1\": { \"product_original_amount\": 1070.5, \"product_original_amount_last\": 1511.3999, \"product_original_amount_delta\": -440.8999, \"product_original_amount_wow\": -0.29171625 }, \"p2\": { \"product_original_amount\": 1511.3999, \"product_original_amount_last\": 1790.5, \"product_original_amount_delta\": -279.1001, \"product_original_amount_wow\": -0.1558783 }, \"p3\": { \"product_original_amount\": 1790.5, \"product_original_amount_last\": 389.6, \"product_original_amount_delta\": 1400.9, \"product_original_amount_wow\": 3.5957391 }, \"p4\": { \"product_original_amount\": 389.6, \"product_original_amount_last\": 389.6, \"product_original_amount_delta\": 0, \"product_original_amount_wow\": 0 } }",
                "metrics_by_shop": "{ \"乐购达超市(复兴路店)\": { \"available_commodity_count\": 163, \"available_commodity_count_delta\": 484, \"sold_commodity_count\": 140, \"sold_commodity_count_delta\": 288, \"transaction_amount\": 9278.85, \"transaction_amount_delta\": 16048.172, \"transaction_share\": 0.36636162, \"subsidy_rate\": 0.20988053 }, \"乐心宜超市(复兴中路店)\": { \"available_commodity_count\": 293, \"available_commodity_count_delta\": 354, \"sold_commodity_count\": 119, \"sold_commodity_count_delta\": 309, \"transaction_amount\": 5769.898, \"transaction_amount_delta\": 19557.123, \"transaction_share\": 0.22781587, \"subsidy_rate\": 0.20925328 }, \"犀牛百货(保定店)\": { \"available_commodity_count\": 193, \"available_commodity_count_delta\": 454, \"sold_commodity_count\": 171, \"sold_commodity_count_delta\": 257, \"transaction_amount\": 10278.262, \"transaction_amount_delta\": 15048.76, \"transaction_share\": 0.40582195, \"subsidy_rate\": 0.28760496 } }",
                "sold_commodity_count": 428,
                "sold_commodity_rate": 0.6615146831530139,
                "subsidy_rate": 0.24127981066703796,
                "transaction_amount": 25327.029296875,
                "transaction_share": 1.000000238418579
            }
        ]
    }
}
```

转换成以下格式:

```json
{
    "data": {
        "columns": [
            "category_level1",
            "category_large",
            "available_commodity_count",
            "available_commodity_count_delta_乐购达超市(复兴路店)",
            "available_commodity_count_delta_乐心宜超市(复兴中路店)",
            "available_commodity_count_delta_犀牛百货(保定店)",
            "sold_commodity_count",
            "sold_commodity_count_delta_乐购达超市(复兴路店)",
            "sold_commodity_count_delta_乐心宜超市(复兴中路店)",
            "sold_commodity_count_delta_犀牛百货(保定店)",
            "transaction_amount",
            "transaction_amount_delta_乐购达超市(复兴路店)",
            "transaction_amount_delta_乐心宜超市(复兴中路店)",
            "transaction_amount_delta_犀牛百货(保定店)",
            "transaction_amount_p0",
            "transaction_amount_p1",
            "transaction_amount_p2",
            "transaction_amount_p3",
            "transaction_amount_p4",
            "transaction_share",
            "subsidy_rate",
            "product_original_amount_wow_p0",
            "product_original_amount_wow_p1",
            "product_original_amount_wow_p2",
            "product_original_amount_wow_p3",
            "product_original_amount_wow_p4"
        ],
        "rows": [
            [
                "彩妆香水",
                "耐用品",
                { "value": "647", "乐购达超市(复兴路店)": "163", "乐心宜超市(复兴中路店)": "293", "犀牛百货(保定店)": "193" },
                "484",
                "354",
                "454",
                { "value": "428", "sold_commodity_rate": "0.6615146831530139" },
                "288",
                "309",
                "257",
                { "value": "25327.029296875", "乐购达超市(复兴路店)": "9278.85", "乐心宜超市(复兴中路店)": "5769.898", "犀牛百货(保定店)": "10278.262" },
                "16048.172",
                "19557.123",
                "15048.76",
                "1036.7",
                "1070.5",
                "1511.3999",
                "1790.5",
                "389.6",
                { "value": "1.000000238418579", "乐购达超市(复兴路店)": "0.36636162", "乐心宜超市(复兴中路店)": "0.22781587", "犀牛百货(保定店)": "0.40582195" },
                { "value": "0.24127981066703796", "乐购达超市(复兴路店)": "0.20988053", "乐心宜超市(复兴中路店)": "0.20925328", "犀牛百货(保定店)": "0.28760496" },
                "-0.031574078",
                "-0.29171625",
                "-0.1558783",
                "3.5957391",
                "0"
            ]
        ]
    }
}
```

---

增加以下实体:

# data_table 数据表
tenant_id: 租户ID
data_source_id: 数据源ID
name: 数据表名称
desc: 数据表描述

# data_table_column 数据表字段
data_table_id: 数据表ID
column_index: 字段在数据表中的序号(从0开始)
name: 字段名称
desc: 字段描述
date_type: 字段数据类型
nullable: 字段是否允许为空
default_value: 字段默认值
partitioner: 是否分区字段

# data_table_usage 数据表统计
data_table_id: 数据表ID
row_count: 行数
partition_count: 分区数
storage_size: 存储占用(Byte)
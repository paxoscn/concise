/*
curl -v http://concise-dev:8080/api/v1/views/card_tx_amount/query \
-H 'Content-Type: application/json' \
-H 'tenant_id: 1' \
-d '
{
    "params": {
        "start": "20250101",
        "end": "20251231"
    }
}
'
*/
INSERT INTO views VALUES (
    'card_tx_amount',
    '1',
    'card_tx_amount',
    'comparable_card',
    $$
    SELECT
        'self' merchant_name,
        SUM(CAST(COALESCE(s.transaction_amount, '0') AS REAL)) transaction_amount
    FROM
        dwd_rival_stats_distincted_di_1d s
    WHERE
        CASE WHEN LENGTH(s.date_str) < 8 THEN CONCAT('2025', s.date_str) ELSE s.date_str END BETWEEN {start} AND {end}
        [category_level1:AND s.category_level1 = {category_level1}]
        [shop_names:AND s.shop_name IN {shop_names}]
    UNION ALL
    SELECT
        s.shop_name merchant_name,
        SUM(CAST(COALESCE(s.transaction_amount, '0') AS REAL)) transaction_amount
    FROM
        dwd_rival_stats_distincted_di_1d s
    WHERE
        CASE WHEN LENGTH(s.date_str) < 8 THEN CONCAT('2025', s.date_str) ELSE s.date_str END BETWEEN {start} AND {end}
        [category_level1:AND s.category_level1 = {category_level1}]
    GROUP BY s.shop_name
    $$,
    DEFAULT,
    DEFAULT
)
ON CONFLICT (tenant_id, view_code) DO UPDATE
SET view_sql = EXCLUDED.view_sql;



/*
curl -v http://concise-dev:8080/api/v1/views/card_tx_share/query \
-H 'Content-Type: application/json' \
-H 'tenant_id: 1' \
-d '
{
    "params": {
        "start": "20250101",
        "end": "20251231"
    }
}
'
*/
INSERT INTO views VALUES (
    'card_tx_share',
    '1',
    'card_tx_share',
    'comparable_card',
    $$
    SELECT
        n.merchant_name,
        n.transaction_amount / d.transaction_amount transaction_share
    FROM (
        SELECT
            SUM(CAST(COALESCE(s.transaction_amount, '0') AS REAL)) transaction_amount
        FROM
            dwd_rival_stats_distincted_di_1d s
        WHERE
            CASE WHEN LENGTH(s.date_str) < 8 THEN CONCAT('2025', s.date_str) ELSE s.date_str END BETWEEN {start} AND {end}
            [category_level1:AND s.category_level1 = {category_level1}]
    ) d,
    (
        SELECT
            'self' merchant_name,
            SUM(CAST(COALESCE(s.transaction_amount, '0') AS REAL)) transaction_amount
        FROM
            dwd_rival_stats_distincted_di_1d s
        WHERE
            CASE WHEN LENGTH(s.date_str) < 8 THEN CONCAT('2025', s.date_str) ELSE s.date_str END BETWEEN {start} AND {end}
            [category_level1:AND s.category_level1 = {category_level1}]
            [shop_names:AND s.shop_name IN {shop_names}]
        UNION ALL
        SELECT
            s.shop_name merchant_name,
            SUM(CAST(COALESCE(s.transaction_amount, '0') AS REAL)) transaction_amount
        FROM
            dwd_rival_stats_distincted_di_1d s
        WHERE
            CASE WHEN LENGTH(s.date_str) < 8 THEN CONCAT('2025', s.date_str) ELSE s.date_str END BETWEEN {start} AND {end}
            [category_level1:AND s.category_level1 = {category_level1}]
        GROUP BY s.shop_name
    ) n
    $$,
    DEFAULT,
    DEFAULT
)
ON CONFLICT (tenant_id, view_code) DO UPDATE
SET view_sql = EXCLUDED.view_sql;



/*
curl -v http://concise-dev:8080/api/v1/views/card_available_commodity_count/query \
-H 'Content-Type: application/json' \
-H 'tenant_id: 1' \
-d '
{
    "params": {
        "start": "20250101",
        "end": "20251231"
    }
}
'
*/
INSERT INTO views VALUES (
    'card_available_commodity_count',
    '1',
    'card_available_commodity_count',
    'comparable_card',
    $$
    SELECT
        'self' merchant_name,
        COUNT(DISTINCT COALESCE(s.product_name, '')) available_commodity_count
    FROM
        dwd_rival_stats_distincted_di_1d s
    WHERE
        CASE WHEN LENGTH(s.date_str) < 8 THEN CONCAT('2025', s.date_str) ELSE s.date_str END BETWEEN {start} AND {end}
        [category_level1:AND s.category_level1 = {category_level1}]
        [shop_names:AND s.shop_name IN {shop_names}]
    UNION ALL
    SELECT
        s.shop_name merchant_name,
        COUNT(DISTINCT COALESCE(s.product_name, '')) available_commodity_count
    FROM
        dwd_rival_stats_distincted_di_1d s
    WHERE
        CASE WHEN LENGTH(s.date_str) < 8 THEN CONCAT('2025', s.date_str) ELSE s.date_str END BETWEEN {start} AND {end}
        [category_level1:AND s.category_level1 = {category_level1}]
    GROUP BY s.shop_name
    $$,
    DEFAULT,
    DEFAULT
)
ON CONFLICT (tenant_id, view_code) DO UPDATE
SET view_sql = EXCLUDED.view_sql;
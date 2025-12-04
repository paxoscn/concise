/*
curl -v http://concise-dev:8080/api/v1/views/card_tx_amount_of_category_level1/query \
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
    'card_tx_amount_of_category_level1',
    '1',
    'card_tx_amount_of_category_level1',
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
curl -v http://concise-dev:8080/api/v1/views/card_tx_share_of_category_level1/query \
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
    'card_tx_share_of_category_level1',
    '1',
    'card_tx_share_of_category_level1',
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
curl -v http://concise-dev:8080/api/v1/views/card_available_commodity_count_of_category_level1/query \
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
    'card_available_commodity_count_of_category_level1',
    '1',
    'card_available_commodity_count_of_category_level1',
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



/*
curl -v http://concise-dev:8080/api/v1/views/card_subsidy_rate_of_category_level1/query \
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
    'card_subsidy_rate_of_category_level1',
    '1',
    'card_subsidy_rate_of_category_level1',
    'comparable_card',
    $$
    SELECT
        'self' merchant_name,
        COALESCE(SUM(CAST(COALESCE(s.subsidy_amount, '0') AS REAL)) / NULLIF(SUM(CAST(COALESCE(s.transaction_amount, '0') AS REAL)), 0), 0) subsidy_rate
    FROM
        dwd_rival_stats_distincted_di_1d s
    WHERE
        CASE WHEN LENGTH(s.date_str) < 8 THEN CONCAT('2025', s.date_str) ELSE s.date_str END BETWEEN {start} AND {end}
        [category_level1:AND s.category_level1 = {category_level1}]
        [shop_names:AND s.shop_name IN {shop_names}]
    UNION ALL
    SELECT
        s.shop_name merchant_name,
        COALESCE(SUM(CAST(COALESCE(s.subsidy_amount, '0') AS REAL)) / NULLIF(SUM(CAST(COALESCE(s.transaction_amount, '0') AS REAL)), 0), 0) subsidy_rate
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
curl -v http://concise-dev:8080/api/v1/views/table_of_category_level1/query \
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
    'table_of_category_level1',
    '1',
    'table_of_category_level1',
    'comparable_card',
    $$
    WITH
    shops AS (
        SELECT DISTINCT shop_name
        FROM dwd_rival_stats_distincted_di_1d
    ),
    category_level1_and_shops AS (
        SELECT DISTINCT category_level1, sh.shop_name
        FROM dwd_rival_stats_distincted_di_1d, shops sh
        [category_level1:WHERE category_level1 = {category_level1}]
    ),
    weeks AS (
        SELECT DISTINCT week_name
        FROM dwd_store_common_week_di_1d
        WHERE dt = {end}
        ORDER BY week_name
    ),
    category_level1_and_weeks AS (
        SELECT DISTINCT category_level1, w.week_name
        FROM dwd_rival_stats_distincted_di_1d, weeks w
        [category_level1:WHERE category_level1 = {category_level1}]
    ),
    date_to_week AS (
        SELECT CONCAT(SUBSTRING(date_str, 1, 4), SUBSTRING(date_str, 6, 2), SUBSTRING(date_str, 9, 2)) date_str, MAX(week_name) week_name
        FROM dwd_store_common_week_di_1d
        WHERE dt = {end}
        GROUP BY date_str
    )
    SELECT
        m.category_level1,
        m.category_large,
        m.available_commodity_count,
        m.sold_commodity_count,
        m.sold_commodity_rate,
        m.transaction_amount,
        r.metrics_by_shop,
        w.metrics_by_week
    FROM (
        SELECT
            category_level1,
            MAX(category_large) category_large,
            COUNT(DISTINCT COALESCE(product_name, '')) available_commodity_count,
            COUNT(DISTINCT CASE WHEN CAST(COALESCE(monthly_sales, '0') AS REAL) > 0 THEN COALESCE(product_name, '') ELSE NULL END) sold_commodity_count,
            COALESCE(CAST(COUNT(DISTINCT CASE WHEN CAST(COALESCE(monthly_sales, '0') AS REAL) > 0 THEN COALESCE(product_name, '') ELSE NULL END) AS REAL) / NULLIF(COUNT(DISTINCT COALESCE(product_name, '')), 0), 0) sold_commodity_rate,
            SUM(CAST(COALESCE(transaction_amount, '0') AS REAL)) transaction_amount
        FROM
            dwd_rival_stats_distincted_di_1d
        WHERE
            CASE WHEN LENGTH(date_str) < 8 THEN CONCAT('2025', date_str) ELSE date_str END BETWEEN {start} AND {end}
            [category_level1:AND category_level1 = {category_level1}]
            [shop_names:AND shop_name IN {shop_names}]
        GROUP BY
            category_level1
    ) m
    LEFT JOIN (
        SELECT
            t.category_level1,
            CONCAT('{ ', STRING_AGG(CONCAT('"', t.shop_name, '": { "available_commodity_count": ', t.available_commodity_count, ', "available_commodity_count_delta": ', t.available_commodity_count_delta, ', "sold_commodity_count": ', t.sold_commodity_count, ', "sold_commodity_count_delta": ', t.sold_commodity_count_delta, ', "transaction_amount": ', t.transaction_amount, ', "transaction_amount_delta": ', t.transaction_amount_delta, ' }'), ', ' ORDER BY t.shop_name), ' }') metrics_by_shop
        FROM (
            SELECT
                cs.category_level1,
                cs.shop_name,
                COALESCE(by_shop.available_commodity_count, 0) available_commodity_count,
                ca.available_commodity_count - COALESCE(by_shop.available_commodity_count, 0) available_commodity_count_delta,
                COALESCE(by_shop.sold_commodity_count, 0) sold_commodity_count,
                ca.sold_commodity_count - COALESCE(by_shop.sold_commodity_count, 0) sold_commodity_count_delta,
                COALESCE(by_shop.transaction_amount, 0) transaction_amount,
                ca.transaction_amount - COALESCE(by_shop.transaction_amount, 0) transaction_amount_delta
            FROM category_level1_and_shops cs
            LEFT JOIN (
                SELECT
                    category_level1,
                    COUNT(DISTINCT COALESCE(product_name, '')) available_commodity_count,
                    COUNT(DISTINCT CASE WHEN CAST(COALESCE(monthly_sales, '0') AS REAL) > 0 THEN COALESCE(product_name, '') ELSE NULL END) sold_commodity_count,
                    SUM(CAST(COALESCE(transaction_amount, '0') AS REAL)) transaction_amount
                FROM dwd_rival_stats_distincted_di_1d
                WHERE
                    CASE WHEN LENGTH(date_str) < 8 THEN CONCAT('2025', date_str) ELSE date_str END BETWEEN {start} AND {end}
                    [category_level1:AND category_level1 = {category_level1}]
                GROUP BY
                    category_level1
            ) ca
            ON cs.category_level1 = ca.category_level1
            LEFT JOIN (
                SELECT
                    category_level1,
                    shop_name,
                    COUNT(DISTINCT COALESCE(product_name, '')) available_commodity_count,
                    COUNT(DISTINCT CASE WHEN CAST(COALESCE(monthly_sales, '0') AS REAL) > 0 THEN COALESCE(product_name, '') ELSE NULL END) sold_commodity_count,
                    SUM(CAST(COALESCE(transaction_amount, '0') AS REAL)) transaction_amount
                FROM
                    dwd_rival_stats_distincted_di_1d
                WHERE
                    CASE WHEN LENGTH(date_str) < 8 THEN CONCAT('2025', date_str) ELSE date_str END BETWEEN {start} AND {end}
                    [category_level1:AND category_level1 = {category_level1}]
                GROUP BY
                    category_level1,
                    shop_name
            ) by_shop
            ON
                cs.shop_name = by_shop.shop_name
                AND cs.category_level1 = by_shop.category_level1
        ) t
        GROUP BY
            t.category_level1
    ) r
    ON m.category_level1 = r.category_level1
    LEFT JOIN (
        SELECT
            cw.category_level1,
            CONCAT('{ ', STRING_AGG(CONCAT('"', cw.week_name, '": { "product_original_amount": ', COALESCE(cs.product_original_amount, 0), ', "product_original_amount_last": ', COALESCE(cs.product_original_amount_last, 0), ', "product_original_amount_delta": ', COALESCE(cs.product_original_amount, 0) - COALESCE(cs.product_original_amount_last, 0), ', "product_original_amount_wow": ', COALESCE((COALESCE(cs.product_original_amount, 0) - COALESCE(cs.product_original_amount_last, 0)) / NULLIF(COALESCE(cs.product_original_amount_last, 0), 0), 0), ' }'), ', ' ORDER BY cw.week_name), ' }') metrics_by_week
        FROM category_level1_and_weeks cw
        LEFT JOIN (
            SELECT
                cs.category_level1,
                cs.week_name,
                cs.product_original_amount,
                COALESCE(LAG(cs.product_original_amount) OVER (PARTITION BY cs.category_level1 ORDER BY cs.week_name), cs.product_original_amount) AS product_original_amount_last
            FROM (
                SELECT
                    cs.category_level1,
                    dw.week_name,
                    SUM(cs.product_original_amount) product_original_amount
                FROM (
                    SELECT
                        commodity_code_to_category_level1.category_level1,
                        CONCAT(SUBSTRING(cs.date_str, 1, 4), SUBSTRING(cs.date_str, 6, 2), SUBSTRING(cs.date_str, 9, 2)) date_str,
                        SUM(CAST(COALESCE(product_original_amount, '0') AS REAL)) product_original_amount
                    FROM dwd_store_sales_commodity_stats_di_1d cs
                    LEFT JOIN (
                        SELECT
                            product_code,
                            MAX(category_level1) category_level1
                        FROM dwd_store_common_commodity_extra_di_1d
                        GROUP BY
                            product_code
                    ) commodity_code_to_category_level1
                    ON cs.warehouse_store_sku_code = commodity_code_to_category_level1.product_code
                    WHERE
                        CONCAT(SUBSTRING(cs.date_str, 1, 4), SUBSTRING(cs.date_str, 6, 2), SUBSTRING(cs.date_str, 9, 2)) BETWEEN {start} AND {end}
                        [category_level1:AND commodity_code_to_category_level1.category_level1 = {category_level1}]
                        [shop_names:AND cs.store_name IN {shop_names}]
                    GROUP BY commodity_code_to_category_level1.category_level1, cs.date_str
                ) cs
                LEFT JOIN date_to_week dw
                ON cs.date_str = dw.date_str
                GROUP BY cs.category_level1, dw.week_name
            ) cs
        ) cs
        ON cw.category_level1 = cs.category_level1 AND cw.week_name = cs.week_name
        GROUP BY
            cw.category_level1
    ) w
    ON m.category_level1 = w.category_level1        
    $$,
    DEFAULT,
    DEFAULT
)
ON CONFLICT (tenant_id, view_code) DO UPDATE
SET view_sql = EXCLUDED.view_sql;
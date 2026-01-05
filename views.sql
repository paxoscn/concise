/*
TARGET=http://concise-dev:8080
TARGET=https://platform-test.agentcool.cn/concise
*/
/*
curl -v "$TARGET/api/v1/views/dropdown_shops/query" \
-H 'Content-Type: application/json' \
-H 'tenant_id: 1' \
-d '
{
    "params": {
        "start": "20250101",
        "end": "20251231",
        "shop_owner": "竞对"
    }
}
'
*/
INSERT INTO views VALUES (
    'dropdown_shops',
    '1',
    'dropdown_shops',
    'comparable_card',
    $$
    SELECT
        DISTINCT
        shop_name option_key,
        shop_name option_value
    FROM
        dwd_rival_stats_distincted_di_1d s
    WHERE
        CASE WHEN LENGTH(s.date_str) < 8 THEN CONCAT('2025', s.date_str) ELSE s.date_str END BETWEEN {start} AND {end}
        [shop_owner:AND shop_owner = {shop_owner}]
    ORDER BY shop_name
    $$,
    DEFAULT,
    DEFAULT
)
ON CONFLICT (tenant_id, view_code) DO UPDATE
SET view_sql = EXCLUDED.view_sql;




/*
curl -v "$TARGET/api/v1/views/dropdown_level1_categories/query" \
-H 'Content-Type: application/json' \
-H 'tenant_id: 1' \
-d '
{
    "params": {
        "start": "20250101",
        "end": "20251231",
        "shop_owner": "竞对"
    }
}
'
*/
INSERT INTO views VALUES (
    'dropdown_level1_categories',
    '1',
    'dropdown_level1_categories',
    'comparable_card',
    $$
    SELECT
        DISTINCT
        category_level1 option_key,
        category_level1 option_value
    FROM
        dwd_rival_stats_distincted_di_1d s
    WHERE
        CASE WHEN LENGTH(s.date_str) < 8 THEN CONCAT('2025', s.date_str) ELSE s.date_str END BETWEEN {start} AND {end}
    ORDER BY category_level1
    $$,
    DEFAULT,
    DEFAULT
)
ON CONFLICT (tenant_id, view_code) DO UPDATE
SET view_sql = EXCLUDED.view_sql;



/*
curl -v "$TARGET/api/v1/views/card_tx_amount_of_category_level1/query" \
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
        'self' amount_key,
        CONCAT('¥', COALESCE(ROUND(SUM(CAST(COALESCE(s.transaction_amount, '0') AS REAL))::NUMERIC, 2), '0.00')::VARCHAR) amount_value
    FROM
        dwd_rival_stats_distincted_di_1d s
    WHERE
        CASE WHEN LENGTH(s.date_str) < 8 THEN CONCAT('2025', s.date_str) ELSE s.date_str END BETWEEN {start} AND {end}
        [category_level1:AND s.category_level1 LIKE {category_level1}]
        [shop_names:AND REPLACE(REPLACE(s.shop_name, '（', '('), '）', ')') = ANY({shop_names})]
    UNION ALL
    SELECT
        REPLACE(REPLACE(s.shop_name, '（', '('), '）', ')') amount_key,
        CONCAT('¥', COALESCE(ROUND(SUM(CAST(COALESCE(s.transaction_amount, '0') AS REAL))::NUMERIC, 2), '0.00')::VARCHAR) amount_value
    FROM
        dwd_rival_stats_distincted_di_1d s
    WHERE
        shop_owner = '竞对'
        AND CASE WHEN LENGTH(s.date_str) < 8 THEN CONCAT('2025', s.date_str) ELSE s.date_str END BETWEEN {start} AND {end}
        [category_level1:AND s.category_level1 LIKE {category_level1}]
    GROUP BY s.shop_name
    $$,
    DEFAULT,
    DEFAULT
)
ON CONFLICT (tenant_id, view_code) DO UPDATE
SET view_sql = EXCLUDED.view_sql;



/*
curl -v "$TARGET/api/v1/views/card_tx_share_of_category_level1/query" \
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
        n.merchant_name amount_key,
        CONCAT(COALESCE(ROUND((100 * n.transaction_amount / d.transaction_amount)::NUMERIC, 2), '0.00')::VARCHAR, '%') amount_value
    FROM (
        SELECT
            SUM(CAST(COALESCE(s.transaction_amount, '0') AS REAL)) transaction_amount
        FROM
            dwd_rival_stats_distincted_di_1d s
        WHERE
            CASE WHEN LENGTH(s.date_str) < 8 THEN CONCAT('2025', s.date_str) ELSE s.date_str END BETWEEN {start} AND {end}
            [category_level1:AND s.category_level1 LIKE {category_level1}]
    ) d,
    (
        SELECT
            'self' merchant_name,
            SUM(CAST(COALESCE(s.transaction_amount, '0') AS REAL)) transaction_amount
        FROM
            dwd_rival_stats_distincted_di_1d s
        WHERE
            CASE WHEN LENGTH(s.date_str) < 8 THEN CONCAT('2025', s.date_str) ELSE s.date_str END BETWEEN {start} AND {end}
            [category_level1:AND s.category_level1 LIKE {category_level1}]
            [shop_names:AND REPLACE(REPLACE(s.shop_name, '（', '('), '）', ')') = ANY({shop_names})]
        UNION ALL
        SELECT
            s.shop_name merchant_name,
            SUM(CAST(COALESCE(s.transaction_amount, '0') AS REAL)) transaction_amount
        FROM
            dwd_rival_stats_distincted_di_1d s
        WHERE
            shop_owner = '竞对'
            AND CASE WHEN LENGTH(s.date_str) < 8 THEN CONCAT('2025', s.date_str) ELSE s.date_str END BETWEEN {start} AND {end}
            [category_level1:AND s.category_level1 LIKE {category_level1}]
        GROUP BY s.shop_name
    ) n
    $$,
    DEFAULT,
    DEFAULT
)
ON CONFLICT (tenant_id, view_code) DO UPDATE
SET view_sql = EXCLUDED.view_sql;



/*
curl -v "$TARGET/api/v1/views/card_available_commodity_count_of_category_level1/query" \
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
        'self' amount_key,
        ROUND(COUNT(DISTINCT COALESCE(s.product_name, ''))::NUMERIC, 0)::VARCHAR amount_value
    FROM
        dwd_rival_stats_distincted_di_1d s
    WHERE
        CASE WHEN LENGTH(s.date_str) < 8 THEN CONCAT('2025', s.date_str) ELSE s.date_str END BETWEEN {start} AND {end}
        [category_level1:AND s.category_level1 LIKE {category_level1}]
        [shop_names:AND REPLACE(REPLACE(s.shop_name, '（', '('), '）', ')') = ANY({shop_names})]
    UNION ALL
    SELECT
        REPLACE(REPLACE(s.shop_name, '（', '('), '）', ')') amount_key,
        ROUND(COUNT(DISTINCT COALESCE(s.product_name, ''))::NUMERIC, 0)::VARCHAR amount_value
    FROM
        dwd_rival_stats_distincted_di_1d s
    WHERE
        shop_owner = '竞对'
        AND CASE WHEN LENGTH(s.date_str) < 8 THEN CONCAT('2025', s.date_str) ELSE s.date_str END BETWEEN {start} AND {end}
        [category_level1:AND s.category_level1 LIKE {category_level1}]
    GROUP BY s.shop_name
    $$,
    DEFAULT,
    DEFAULT
)
ON CONFLICT (tenant_id, view_code) DO UPDATE
SET view_sql = EXCLUDED.view_sql;



/*
curl -v "$TARGET/api/v1/views/card_subsidy_rate_of_category_level1/query" \
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
        'self' amount_key,
        CONCAT(ROUND((COALESCE(100 * SUM(CAST(COALESCE(s.subsidy_amount, '0') AS REAL)) / NULLIF(SUM(CAST(COALESCE(s.transaction_amount, '0') AS REAL)), 0), 0))::NUMERIC, 2)::VARCHAR, '%') amount_value
    FROM
        dwd_rival_stats_distincted_di_1d s
    WHERE
        CASE WHEN LENGTH(s.date_str) < 8 THEN CONCAT('2025', s.date_str) ELSE s.date_str END BETWEEN {start} AND {end}
        [category_level1:AND s.category_level1 LIKE {category_level1}]
        [shop_names:AND REPLACE(REPLACE(s.shop_name, '（', '('), '）', ')') = ANY({shop_names})]
    UNION ALL
    SELECT
        REPLACE(REPLACE(s.shop_name, '（', '('), '）', ')') amount_key,
        CONCAT(ROUND((COALESCE(100 * SUM(CAST(COALESCE(s.subsidy_amount, '0') AS REAL)) / NULLIF(SUM(CAST(COALESCE(s.transaction_amount, '0') AS REAL)), 0), 0))::NUMERIC, 2)::VARCHAR, '%') amount_value
    FROM
        dwd_rival_stats_distincted_di_1d s
    WHERE
        shop_owner = '竞对'
        AND CASE WHEN LENGTH(s.date_str) < 8 THEN CONCAT('2025', s.date_str) ELSE s.date_str END BETWEEN {start} AND {end}
        [category_level1:AND s.category_level1 LIKE {category_level1}]
    GROUP BY s.shop_name
    $$,
    DEFAULT,
    DEFAULT
)
ON CONFLICT (tenant_id, view_code) DO UPDATE
SET view_sql = EXCLUDED.view_sql;



/*
curl -v "$TARGET/api/v1/views/table_of_category_level1/query" \
-H 'Content-Type: application/json' \
-H 'tenant_id: 1' \
-d '
{
    "params": {
        "start": "20250101",
        "end": "20251026",
        "period_type": "week",
        "max_period_distance": "5"
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
        SELECT DISTINCT REPLACE(REPLACE(shop_name, '（', '('), '）', ')') shop_name
        FROM dwd_rival_stats_distincted_di_1d
        WHERE shop_owner = '竞对'
    ),
    category_level1_and_shops AS (
        SELECT DISTINCT category_level1, REPLACE(REPLACE(sh.shop_name, '（', '('), '）', ')') shop_name
        FROM dwd_rival_stats_distincted_di_1d, shops sh
        [category_level1:WHERE category_level1 LIKE {category_level1}]
    ),
    periods AS (
        SELECT CONCAT('p', period_index) period_name
        FROM (
            SELECT generate_series(0, {max_period_distance}::INT - 1) period_index
        ) t
    ),
    category_level1_and_periods AS (
        SELECT DISTINCT category_level1, p.period_name
        FROM dwd_rival_stats_distincted_di_1d, periods p
        [category_level1:WHERE category_level1 LIKE {category_level1}]
    ),
    date_to_period AS (
        SELECT t.date_str, CONCAT('p', t.period_index) period_name
        FROM (
            WITH
                date_ref AS (SELECT CONCAT(SUBSTRING({end}, 1, 4), '-', SUBSTRING({end}, 5, 2), '-', SUBSTRING({end}, 7, 2))::DATE AS today),
                dates AS (
                    SELECT 
                        date_ref.today - n AS d,
                        date_ref.today
                    FROM date_ref, generate_series(0, 179) AS n
                )
            SELECT
                'day' period_type,
                TO_CHAR(d, 'YYYYMMDD') AS date_str,
                (today - d)::int AS period_index
            FROM dates
            UNION ALL
            SELECT
                'week' period_type,
                TO_CHAR(d, 'YYYYMMDD') AS date_str,
                ((DATE_TRUNC('week', today)::date - DATE_TRUNC('week', d)::date) / 7) AS period_index
            FROM dates
            UNION ALL
            SELECT
                'month' period_type,
                TO_CHAR(d, 'YYYYMMDD') AS date_str,
                (
                    EXTRACT(YEAR FROM today)::int - EXTRACT(YEAR FROM d)::int
                ) * 12 
                + 
                (
                    EXTRACT(MONTH FROM today)::int - EXTRACT(MONTH FROM d)::int
                ) AS period_index
            FROM dates
        ) t
        WHERE t.period_index < {max_period_distance}::INT AND t.period_type = {period_type}
    )
    SELECT
        m.category_level1,
        m.category_large,
        m.available_commodity_count,
        m.sold_commodity_count,
        m.sold_commodity_rate,
        m.transaction_amount,
        COALESCE(COALESCE(m.transaction_amount, 0) / NULLIF(COALESCE(r.total_transaction_amount, 0), 0), 0) transaction_share,
        COALESCE(COALESCE(m.subsidy_amount, 0) / NULLIF(COALESCE(m.transaction_amount, 0), 0), 0) subsidy_rate,
        r.metrics_by_shop,
        p.metrics_by_period
    FROM (
        SELECT
            category_level1,
            MAX(category_large) category_large,
            COUNT(DISTINCT COALESCE(product_name, '')) available_commodity_count,
            COUNT(DISTINCT CASE WHEN CAST(COALESCE(monthly_sales, '0') AS REAL) > 0 THEN COALESCE(product_name, '') ELSE NULL END) sold_commodity_count,
            COALESCE(CAST(COUNT(DISTINCT CASE WHEN CAST(COALESCE(monthly_sales, '0') AS REAL) > 0 THEN COALESCE(product_name, '') ELSE NULL END) AS REAL) / NULLIF(COUNT(DISTINCT COALESCE(product_name, '')), 0), 0) sold_commodity_rate,
            SUM(CAST(COALESCE(transaction_amount, '0') AS REAL)) transaction_amount,
            SUM(CAST(COALESCE(subsidy_amount, '0') AS REAL)) subsidy_amount
        FROM
            dwd_rival_stats_distincted_di_1d
        WHERE
            CASE WHEN LENGTH(date_str) < 8 THEN CONCAT('2025', date_str) ELSE date_str END BETWEEN {start} AND {end}
            [category_level1:AND category_level1 LIKE {category_level1}]
            [shop_names:AND REPLACE(REPLACE(shop_name, '（', '('), '）', ')') = ANY({shop_names})]
        GROUP BY
            category_level1
    ) m
    LEFT JOIN (
        SELECT
            t.category_level1,
            MAX(t.total_transaction_amount) total_transaction_amount,
            CONCAT('{ ', STRING_AGG(CONCAT('"', t.shop_name, '": { "available_commodity_count": ', t.available_commodity_count, ', "available_commodity_count_delta": ', t.available_commodity_count_delta, ', "sold_commodity_count": ', t.sold_commodity_count, ', "sold_commodity_count_delta": ', t.sold_commodity_count_delta, ', "transaction_amount": ', t.transaction_amount, ', "transaction_amount_delta": ', t.transaction_amount_delta, ', "transaction_share": ', COALESCE(COALESCE(t.transaction_amount, 0) / NULLIF(COALESCE(t.total_transaction_amount, 0), 0), 0), ', "subsidy_rate": ', COALESCE(COALESCE(t.subsidy_amount, 0) / NULLIF(COALESCE(t.transaction_amount, 0), 0), 0), ' }'), ', ' ORDER BY t.shop_name), ' }') metrics_by_shop
        FROM (
            SELECT
                cs.category_level1,
                cs.shop_name,
                COALESCE(by_shop.available_commodity_count, 0) available_commodity_count,
                ct.available_commodity_count - COALESCE(by_shop.available_commodity_count, 0) available_commodity_count_delta,
                COALESCE(by_shop.sold_commodity_count, 0) sold_commodity_count,
                ct.sold_commodity_count - COALESCE(by_shop.sold_commodity_count, 0) sold_commodity_count_delta,
                COALESCE(by_shop.transaction_amount, 0) transaction_amount,
                ct.transaction_amount - COALESCE(by_shop.transaction_amount, 0) transaction_amount_delta,
                COALESCE(by_shop.subsidy_amount, 0) subsidy_amount,
                ca.transaction_amount total_transaction_amount
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
                    [category_level1:AND category_level1 LIKE {category_level1}]
                GROUP BY
                    category_level1
            ) ca
            ON cs.category_level1 = ca.category_level1
            LEFT JOIN (
                SELECT
                    category_level1,
                    COUNT(DISTINCT COALESCE(product_name, '')) available_commodity_count,
                    COUNT(DISTINCT CASE WHEN CAST(COALESCE(monthly_sales, '0') AS REAL) > 0 THEN COALESCE(product_name, '') ELSE NULL END) sold_commodity_count,
                    SUM(CAST(COALESCE(transaction_amount, '0') AS REAL)) transaction_amount,
                    SUM(CAST(COALESCE(subsidy_amount, '0') AS REAL)) subsidy_amount
                FROM dwd_rival_stats_distincted_di_1d
                WHERE
                    CASE WHEN LENGTH(date_str) < 8 THEN CONCAT('2025', date_str) ELSE date_str END BETWEEN {start} AND {end}
                    [category_level1:AND category_level1 LIKE {category_level1}]
                    [shop_names:AND REPLACE(REPLACE(shop_name, '（', '('), '）', ')') = ANY({shop_names})]
                GROUP BY
                    category_level1
            ) ct
            ON cs.category_level1 = ct.category_level1
            LEFT JOIN (
                SELECT
                    category_level1,
                    REPLACE(REPLACE(shop_name, '（', '('), '）', ')') shop_name,
                    COUNT(DISTINCT COALESCE(product_name, '')) available_commodity_count,
                    COUNT(DISTINCT CASE WHEN CAST(COALESCE(monthly_sales, '0') AS REAL) > 0 THEN COALESCE(product_name, '') ELSE NULL END) sold_commodity_count,
                    SUM(CAST(COALESCE(transaction_amount, '0') AS REAL)) transaction_amount,
                    SUM(CAST(COALESCE(subsidy_amount, '0') AS REAL)) subsidy_amount
                FROM
                    dwd_rival_stats_distincted_di_1d
                WHERE
                    CASE WHEN LENGTH(date_str) < 8 THEN CONCAT('2025', date_str) ELSE date_str END BETWEEN {start} AND {end}
                    [category_level1:AND category_level1 LIKE {category_level1}]
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
            cp.category_level1,
            CONCAT('{ ', STRING_AGG(CONCAT('"', cp.period_name, '": { "product_original_amount": ', COALESCE(cs.product_original_amount, 0), ', "product_original_amount_last": ', COALESCE(cs.product_original_amount_last, 0), ', "product_original_amount_delta": ', COALESCE(cs.product_original_amount, 0) - COALESCE(cs.product_original_amount_last, 0), ', "product_original_amount_wow": ', COALESCE((COALESCE(cs.product_original_amount, 0) - COALESCE(cs.product_original_amount_last, 0)) / NULLIF(COALESCE(cs.product_original_amount_last, 0), 0), 0), ' }'), ', ' ORDER BY cp.period_name), ' }') metrics_by_period
        FROM category_level1_and_periods cp
        LEFT JOIN (
            SELECT
                cs.category_level1,
                cs.period_name,
                cs.product_original_amount,
                COALESCE(LAG(cs.product_original_amount) OVER (PARTITION BY cs.category_level1 ORDER BY cs.period_name DESC), cs.product_original_amount) AS product_original_amount_last
            FROM (
                SELECT
                    cs.category_level1,
                    dp.period_name,
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
                        [category_level1:AND commodity_code_to_category_level1.category_level1 LIKE {category_level1}]
                        [shop_names:AND REPLACE(REPLACE(cs.store_name, '（', '('), '）', ')') = ANY({shop_names})]
                    GROUP BY commodity_code_to_category_level1.category_level1, cs.date_str
                ) cs
                LEFT JOIN date_to_period dp
                ON cs.date_str = dp.date_str
                GROUP BY cs.category_level1, dp.period_name
            ) cs
        ) cs
        ON cp.category_level1 = cs.category_level1 AND cp.period_name = cs.period_name
        GROUP BY
            cp.category_level1
    ) p
    ON m.category_level1 = p.category_level1
    $$,
    DEFAULT,
    DEFAULT
)
ON CONFLICT (tenant_id, view_code) DO UPDATE
SET view_sql = EXCLUDED.view_sql;



/*
curl -v "$TARGET/api/v1/views/bar_of_category_level1/query" \
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
    'bar_of_category_level1',
    '1',
    'bar_of_category_level1',
    'comparable_card',
    $$
    WITH
    shops AS (
        SELECT DISTINCT REPLACE(REPLACE(shop_name, '（', '('), '）', ')') shop_name
        FROM dwd_rival_stats_distincted_di_1d
        WHERE shop_owner = '竞对'
    ),
    category_level1_and_shops AS (
        SELECT DISTINCT category_level1, REPLACE(REPLACE(sh.shop_name, '（', '('), '）', ')') shop_name
        FROM dwd_rival_stats_distincted_di_1d, shops sh
        [category_level1:WHERE category_level1 LIKE {category_level1}]
    )
    SELECT
        m.category_level1,
        m.transaction_amount,
        r.metrics_by_shop
    FROM (
        SELECT
            category_level1,
            SUM(CAST(COALESCE(transaction_amount, '0') AS REAL)) transaction_amount
        FROM
            dwd_rival_stats_distincted_di_1d
        WHERE
            CASE WHEN LENGTH(date_str) < 8 THEN CONCAT('2025', date_str) ELSE date_str END BETWEEN {start} AND {end}
            [category_level1:AND category_level1 LIKE {category_level1}]
            [shop_names:AND REPLACE(REPLACE(shop_name, '（', '('), '）', ')') = ANY({shop_names})]
        GROUP BY
            category_level1
    ) m
    LEFT JOIN (
        SELECT
            t.category_level1,
            CONCAT('{ ', STRING_AGG(CONCAT('"', t.shop_name, '": { "transaction_amount": ', t.transaction_amount, ' }'), ', ' ORDER BY t.shop_name), ' }') metrics_by_shop
        FROM (
            SELECT
                cs.category_level1,
                cs.shop_name,
                COALESCE(by_shop.transaction_amount, 0) transaction_amount
            FROM category_level1_and_shops cs
            LEFT JOIN (
                SELECT
                    category_level1,
                    REPLACE(REPLACE(shop_name, '（', '('), '）', ')') shop_name,
                    SUM(CAST(COALESCE(transaction_amount, '0') AS REAL)) transaction_amount
                FROM
                    dwd_rival_stats_distincted_di_1d
                WHERE
                    shop_owner = '竞对'
                    AND CASE WHEN LENGTH(date_str) < 8 THEN CONCAT('2025', date_str) ELSE date_str END BETWEEN {start} AND {end}
                    [category_level1:AND category_level1 LIKE {category_level1}]
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
    $$,
    DEFAULT,
    DEFAULT
)
ON CONFLICT (tenant_id, view_code) DO UPDATE
SET view_sql = EXCLUDED.view_sql;



/*
curl -v "$TARGET/api/v1/views/pie_of_category_level1/query" \
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
    'pie_of_category_level1',
    '1',
    'pie_of_category_level1',
    'comparable_card',
    $$
    WITH
    shops AS (
        SELECT DISTINCT REPLACE(REPLACE(shop_name, '（', '('), '）', ')') shop_name
        FROM dwd_rival_stats_distincted_di_1d
        WHERE shop_owner = '竞对'
    )
    SELECT
        m.transaction_amount,
        COALESCE(m.transaction_amount / NULLIF(r.transaction_amount_total, 0), 0) transaction_share,
        r.metrics_by_shop
    FROM (
        SELECT
            SUM(CAST(COALESCE(transaction_amount, '0') AS REAL)) transaction_amount
        FROM
            dwd_rival_stats_distincted_di_1d
        WHERE
            CASE WHEN LENGTH(date_str) < 8 THEN CONCAT('2025', date_str) ELSE date_str END BETWEEN {start} AND {end}
            [category_level1:AND category_level1 LIKE {category_level1}]
            [shop_names:AND REPLACE(REPLACE(shop_name, '（', '('), '）', ')') = ANY({shop_names})]
    ) m,
    (
        SELECT
            MAX(t.transaction_amount) transaction_amount_total,
            CONCAT('{ ', STRING_AGG(CONCAT('"', s.shop_name, '": { "transaction_amount": ', s.transaction_amount, ', "transaction_share": ', COALESCE(s.transaction_amount / NULLIF(t.transaction_amount, 0), 0), ' }'), ', ' ORDER BY s.shop_name), ' }') metrics_by_shop
        FROM (
            SELECT
                sh.shop_name,
                COALESCE(by_shop.transaction_amount, 0) transaction_amount
            FROM shops sh
            LEFT JOIN (
                SELECT
                    REPLACE(REPLACE(shop_name, '（', '('), '）', ')') shop_name,
                    SUM(CAST(COALESCE(transaction_amount, '0') AS REAL)) transaction_amount
                FROM
                    dwd_rival_stats_distincted_di_1d
                WHERE
                    shop_owner = '竞对'
                    AND CASE WHEN LENGTH(date_str) < 8 THEN CONCAT('2025', date_str) ELSE date_str END BETWEEN {start} AND {end}
                    [category_level1:AND category_level1 LIKE {category_level1}]
                GROUP BY
                    shop_name
            ) by_shop
            ON
                sh.shop_name = by_shop.shop_name
        ) s,
        (
            SELECT
                SUM(CAST(COALESCE(transaction_amount, '0') AS REAL)) transaction_amount
            FROM dwd_rival_stats_distincted_di_1d
            WHERE
                CASE WHEN LENGTH(date_str) < 8 THEN CONCAT('2025', date_str) ELSE date_str END BETWEEN {start} AND {end}
                [category_level1:AND category_level1 LIKE {category_level1}]
        ) t
    ) r
    $$,
    DEFAULT,
    DEFAULT
)
ON CONFLICT (tenant_id, view_code) DO UPDATE
SET view_sql = EXCLUDED.view_sql;



/*
curl -v "$TARGET/api/v1/views/trend_of_category_level1/query" \
-H 'Content-Type: application/json' \
-H 'tenant_id: 1' \
-d '
{
    "params": {
        "start": "20250101",
        "end": "20251026",
        "period_type": "week",
        "max_period_distance": "5"
    }
}
'
*/
INSERT INTO views VALUES (
    'trend_of_category_level1',
    '1',
    'trend_of_category_level1',
    'comparable_card',
    $$
    WITH
    shops AS (
        SELECT DISTINCT REPLACE(REPLACE(shop_name, '（', '('), '）', ')') shop_name
        FROM dwd_rival_stats_distincted_di_1d
    ),
    periods AS (
        SELECT CONCAT('p', period_index) period_name
        FROM (
            SELECT generate_series(0, {max_period_distance}::INT - 1) period_index
        ) t
    ),
    category_level1_and_shops_and_periods AS (
        SELECT DISTINCT category_level1, REPLACE(REPLACE(sh.shop_name, '（', '('), '）', ')') shop_name, p.period_name
        FROM dwd_rival_stats_distincted_di_1d, shops sh, periods p
        [category_level1:WHERE category_level1 LIKE {category_level1}]
    ),
    date_to_period AS (
        SELECT t.date_str, CONCAT('p', t.period_index) period_name
        FROM (
            WITH
                date_ref AS (SELECT CONCAT(SUBSTRING({end}, 1, 4), '-', SUBSTRING({end}, 5, 2), '-', SUBSTRING({end}, 7, 2))::DATE AS today),
                dates AS (
                    SELECT 
                        date_ref.today - n AS d,
                        date_ref.today
                    FROM date_ref, generate_series(0, 179) AS n
                )
            SELECT
                'day' period_type,
                TO_CHAR(d, 'YYYYMMDD') AS date_str,
                (today - d)::int AS period_index
            FROM dates
            UNION ALL
            SELECT
                'week' period_type,
                TO_CHAR(d, 'YYYYMMDD') AS date_str,
                ((DATE_TRUNC('week', today)::date - DATE_TRUNC('week', d)::date) / 7) AS period_index
            FROM dates
            UNION ALL
            SELECT
                'month' period_type,
                TO_CHAR(d, 'YYYYMMDD') AS date_str,
                (
                    EXTRACT(YEAR FROM today)::int - EXTRACT(YEAR FROM d)::int
                ) * 12 
                + 
                (
                    EXTRACT(MONTH FROM today)::int - EXTRACT(MONTH FROM d)::int
                ) AS period_index
            FROM dates
        ) t
        WHERE t.period_index < {max_period_distance}::INT AND t.period_type = {period_type}
    )
    SELECT
        cp.category_level1,
        cp.shop_name,
        cp.period_name,
        COALESCE(cs.product_original_amount, 0.0) product_original_amount
    FROM category_level1_and_shops_and_periods cp
    LEFT JOIN (
        SELECT
            cs.category_level1,
            cs.shop_name,
            dp.period_name,
            SUM(cs.product_original_amount) product_original_amount
        FROM (
            SELECT
                cs.category_level1,
                REPLACE(REPLACE(cs.shop_name, '（', '('), '）', ')') shop_name,
                CASE WHEN LENGTH(date_str) < 8 THEN CONCAT('2025', date_str) ELSE date_str END date_str,
                SUM(CAST(COALESCE(transaction_amount, '0') AS REAL)) product_original_amount
            FROM
                dwd_rival_stats_distincted_di_1d cs
            WHERE
                CASE WHEN LENGTH(date_str) < 8 THEN CONCAT('2025', date_str) ELSE date_str END BETWEEN {start} AND {end}
                [category_level1:AND category_level1 LIKE {category_level1}]
                [shop_names:AND REPLACE(REPLACE(shop_name, '（', '('), '）', ')') = ANY({shop_names})]
            GROUP BY cs.category_level1, cs.shop_name, cs.date_str
            -- SELECT
            --     commodity_code_to_category_level1.category_level1,
            --     REPLACE(REPLACE(cs.store_name, '（', '('), '）', ')') shop_name,
            --     CONCAT(SUBSTRING(cs.date_str, 1, 4), SUBSTRING(cs.date_str, 6, 2), SUBSTRING(cs.date_str, 9, 2)) date_str,
            --     SUM(CAST(COALESCE(product_original_amount, '0') AS REAL)) product_original_amount
            -- FROM dwd_store_sales_commodity_stats_di_1d cs
            -- LEFT JOIN (
            --     SELECT
            --         product_code,
            --         MAX(category_level1) category_level1
            --     FROM dwd_store_common_commodity_extra_di_1d
            --     GROUP BY
            --         product_code
            -- ) commodity_code_to_category_level1
            -- ON cs.warehouse_store_sku_code = commodity_code_to_category_level1.product_code
            -- WHERE
            --     CONCAT(SUBSTRING(cs.date_str, 1, 4), SUBSTRING(cs.date_str, 6, 2), SUBSTRING(cs.date_str, 9, 2)) BETWEEN {start} AND {end}
            --     [category_level1:AND commodity_code_to_category_level1.category_level1 LIKE {category_level1}]
            --     [shop_names:AND REPLACE(REPLACE(cs.store_name, '（', '('), '）', ')') = ANY({shop_names})]
            -- GROUP BY commodity_code_to_category_level1.category_level1, cs.store_name, cs.date_str
        ) cs
        LEFT JOIN date_to_period dp
        ON cs.date_str = dp.date_str
        GROUP BY cs.category_level1, cs.shop_name, dp.period_name
    ) cs
    ON cp.category_level1 = cs.category_level1 AND cp.shop_name = cs.shop_name AND cp.period_name = cs.period_name
    $$,
    DEFAULT,
    DEFAULT
)
ON CONFLICT (tenant_id, view_code) DO UPDATE
SET view_sql = EXCLUDED.view_sql;



/*
curl -v "$TARGET/api/v1/views/table_of_category_level3/query" \
-H 'Content-Type: application/json' \
-H 'tenant_id: 1' \
-d '
{
    "params": {
        "start": "20250101",
        "end": "20251026",
        "period_type": "week",
        "max_period_distance": "5",
        "category_level1": "数码家电"
    }
}
'
*/
INSERT INTO views VALUES (
    'table_of_category_level3',
    '1',
    'table_of_category_level3',
    'comparable_card',
    $$
    WITH
    shops AS (
        SELECT DISTINCT REPLACE(REPLACE(shop_name, '（', '('), '）', ')') shop_name
        FROM dwd_rival_stats_distincted_di_1d
    ),
    category_level3_and_shops AS (
        SELECT category_level3, MAX(category_level1) category_level1, REPLACE(REPLACE(sh.shop_name, '（', '('), '）', ')') shop_name
        FROM dwd_rival_stats_distincted_di_1d, shops sh
        WHERE 1 = 1
        [category_level1:AND category_level1 = {category_level1}]
        [category_level3:AND category_level3 LIKE {category_level3}]
        GROUP BY category_level3, sh.shop_name
    ),
    periods AS (
        SELECT CONCAT('p', period_index) period_name
        FROM (
            SELECT generate_series(0, {max_period_distance}::INT - 1) period_index
        ) t
    ),
    category_level3_and_periods AS (
        SELECT DISTINCT category_level3, MAX(category_level1) category_level1, p.period_name
        FROM dwd_rival_stats_distincted_di_1d, periods p
        WHERE 1 = 1
        [category_level1:AND category_level1 = {category_level1}]
        [category_level3:AND category_level3 LIKE {category_level3}]
        GROUP BY category_level3, p.period_name
    ),
    date_to_period AS (
        SELECT t.date_str, CONCAT('p', t.period_index) period_name
        FROM (
            WITH
                date_ref AS (SELECT CONCAT(SUBSTRING({end}, 1, 4), '-', SUBSTRING({end}, 5, 2), '-', SUBSTRING({end}, 7, 2))::DATE AS today),
                dates AS (
                    SELECT 
                        date_ref.today - n AS d,
                        date_ref.today
                    FROM date_ref, generate_series(0, 179) AS n
                )
            SELECT
                'day' period_type,
                TO_CHAR(d, 'YYYYMMDD') AS date_str,
                (today - d)::int AS period_index
            FROM dates
            UNION ALL
            SELECT
                'week' period_type,
                TO_CHAR(d, 'YYYYMMDD') AS date_str,
                ((DATE_TRUNC('week', today)::date - DATE_TRUNC('week', d)::date) / 7) AS period_index
            FROM dates
            UNION ALL
            SELECT
                'month' period_type,
                TO_CHAR(d, 'YYYYMMDD') AS date_str,
                (
                    EXTRACT(YEAR FROM today)::int - EXTRACT(YEAR FROM d)::int
                ) * 12 
                + 
                (
                    EXTRACT(MONTH FROM today)::int - EXTRACT(MONTH FROM d)::int
                ) AS period_index
            FROM dates
        ) t
        WHERE t.period_index < {max_period_distance}::INT AND t.period_type = {period_type}
    )
    SELECT
        m.category_level3,
        m.category_large,
        m.category_level1,
        m.available_commodity_count,
        m.sold_commodity_count,
        m.sold_commodity_rate,
        m.transaction_amount,
        COALESCE(COALESCE(m.transaction_amount, 0) / NULLIF(COALESCE(r.total_transaction_amount, 0), 0), 0) transaction_share,
        COALESCE(COALESCE(m.subsidy_amount, 0) / NULLIF(COALESCE(m.transaction_amount, 0), 0), 0) subsidy_rate,
        r.metrics_by_shop,
        p.metrics_by_period
    FROM (
        SELECT
            category_level3,
            MAX(category_large) category_large,
            MAX(category_level1) category_level1,
            COUNT(DISTINCT COALESCE(product_name, '')) available_commodity_count,
            COUNT(DISTINCT CASE WHEN CAST(COALESCE(monthly_sales, '0') AS REAL) > 0 THEN COALESCE(product_name, '') ELSE NULL END) sold_commodity_count,
            COALESCE(CAST(COUNT(DISTINCT CASE WHEN CAST(COALESCE(monthly_sales, '0') AS REAL) > 0 THEN COALESCE(product_name, '') ELSE NULL END) AS REAL) / NULLIF(COUNT(DISTINCT COALESCE(product_name, '')), 0), 0) sold_commodity_rate,
            SUM(CAST(COALESCE(transaction_amount, '0') AS REAL)) transaction_amount,
            SUM(CAST(COALESCE(subsidy_amount, '0') AS REAL)) subsidy_amount
        FROM
            dwd_rival_stats_distincted_di_1d
        WHERE
            CASE WHEN LENGTH(date_str) < 8 THEN CONCAT('2025', date_str) ELSE date_str END BETWEEN {start} AND {end}
            [category_level1:AND category_level1 = {category_level1}]
            [category_level3:AND category_level3 LIKE {category_level3}]
            [shop_names:AND REPLACE(REPLACE(shop_name, '（', '('), '）', ')') = ANY({shop_names})]
        GROUP BY
            category_level3
    ) m
    LEFT JOIN (
        SELECT
            t.category_level3,
            t.category_level1,
            MAX(t.total_transaction_amount) total_transaction_amount,
            CONCAT('{ ', STRING_AGG(CONCAT('"', t.shop_name, '": { "available_commodity_count": ', t.available_commodity_count, ', "available_commodity_count_delta": ', t.available_commodity_count_delta, ', "sold_commodity_count": ', t.sold_commodity_count, ', "sold_commodity_count_delta": ', t.sold_commodity_count_delta, ', "transaction_amount": ', t.transaction_amount, ', "transaction_amount_delta": ', t.transaction_amount_delta, ', "transaction_share": ', COALESCE(COALESCE(t.transaction_amount, 0) / NULLIF(COALESCE(t.total_transaction_amount, 0), 0), 0), ', "subsidy_rate": ', COALESCE(COALESCE(t.subsidy_amount, 0) / NULLIF(COALESCE(t.transaction_amount, 0), 0), 0), ' }'), ', ' ORDER BY t.shop_name), ' }') metrics_by_shop
        FROM (
            SELECT
                cs.category_level3,
                cs.category_level1,
                cs.shop_name,
                COALESCE(by_shop.available_commodity_count, 0) available_commodity_count,
                ct.available_commodity_count - COALESCE(by_shop.available_commodity_count, 0) available_commodity_count_delta,
                COALESCE(by_shop.sold_commodity_count, 0) sold_commodity_count,
                ct.sold_commodity_count - COALESCE(by_shop.sold_commodity_count, 0) sold_commodity_count_delta,
                COALESCE(by_shop.transaction_amount, 0) transaction_amount,
                ct.transaction_amount - COALESCE(by_shop.transaction_amount, 0) transaction_amount_delta,
                COALESCE(by_shop.subsidy_amount, 0) subsidy_amount,
                ca.transaction_amount total_transaction_amount
            FROM category_level3_and_shops cs
            LEFT JOIN (
                SELECT
                    category_level3, MAX(category_level1) category_level1,
                    COUNT(DISTINCT COALESCE(product_name, '')) available_commodity_count,
                    COUNT(DISTINCT CASE WHEN CAST(COALESCE(monthly_sales, '0') AS REAL) > 0 THEN COALESCE(product_name, '') ELSE NULL END) sold_commodity_count,
                    SUM(CAST(COALESCE(transaction_amount, '0') AS REAL)) transaction_amount
                FROM dwd_rival_stats_distincted_di_1d
                WHERE
                    CASE WHEN LENGTH(date_str) < 8 THEN CONCAT('2025', date_str) ELSE date_str END BETWEEN {start} AND {end}
                    [category_level1:AND category_level1 = {category_level1}]
                    [category_level3:AND category_level3 LIKE {category_level3}]
                GROUP BY
                    category_level3
            ) ca
            ON cs.category_level3 = ca.category_level3 AND cs.category_level1 = ca.category_level1
            LEFT JOIN (
                SELECT
                    category_level3, MAX(category_level1) category_level1,
                    COUNT(DISTINCT COALESCE(product_name, '')) available_commodity_count,
                    COUNT(DISTINCT CASE WHEN CAST(COALESCE(monthly_sales, '0') AS REAL) > 0 THEN COALESCE(product_name, '') ELSE NULL END) sold_commodity_count,
                    SUM(CAST(COALESCE(transaction_amount, '0') AS REAL)) transaction_amount,
                    SUM(CAST(COALESCE(subsidy_amount, '0') AS REAL)) subsidy_amount
                FROM dwd_rival_stats_distincted_di_1d
                WHERE
                    CASE WHEN LENGTH(date_str) < 8 THEN CONCAT('2025', date_str) ELSE date_str END BETWEEN {start} AND {end}
                    [category_level1:AND category_level1 = {category_level1}]
                    [category_level3:AND category_level3 LIKE {category_level3}]
                    [shop_names:AND REPLACE(REPLACE(shop_name, '（', '('), '）', ')') = ANY({shop_names})]
                GROUP BY
                    category_level3
            ) ct
            ON cs.category_level3 = ct.category_level3 AND cs.category_level1 = ct.category_level1
            LEFT JOIN (
                SELECT
                    category_level3,
                    MAX(category_level1) category_level1,
                    REPLACE(REPLACE(shop_name, '（', '('), '）', ')') shop_name,
                    COUNT(DISTINCT COALESCE(product_name, '')) available_commodity_count,
                    COUNT(DISTINCT CASE WHEN CAST(COALESCE(monthly_sales, '0') AS REAL) > 0 THEN COALESCE(product_name, '') ELSE NULL END) sold_commodity_count,
                    SUM(CAST(COALESCE(transaction_amount, '0') AS REAL)) transaction_amount,
                    SUM(CAST(COALESCE(subsidy_amount, '0') AS REAL)) subsidy_amount
                FROM
                    dwd_rival_stats_distincted_di_1d
                WHERE
                    CASE WHEN LENGTH(date_str) < 8 THEN CONCAT('2025', date_str) ELSE date_str END BETWEEN {start} AND {end}
                    [category_level1:AND category_level1 = {category_level1}]
                    [category_level3:AND category_level3 LIKE {category_level3}]
                GROUP BY
                    category_level3,
                    shop_name
            ) by_shop
            ON
                cs.shop_name = by_shop.shop_name
                AND cs.category_level3 = by_shop.category_level3
                AND cs.category_level1 = by_shop.category_level1
        ) t
        GROUP BY
            t.category_level3, t.category_level1
    ) r
    ON m.category_level3 = r.category_level3 AND m.category_level1 = r.category_level1
    LEFT JOIN (
        SELECT
            cp.category_level3,
            cp.category_level1,
            CONCAT('{ ', STRING_AGG(CONCAT('"', cp.period_name, '": { "product_original_amount": ', COALESCE(cs.product_original_amount, 0), ', "product_original_amount_last": ', COALESCE(cs.product_original_amount_last, 0), ', "product_original_amount_delta": ', COALESCE(cs.product_original_amount, 0) - COALESCE(cs.product_original_amount_last, 0), ', "product_original_amount_wow": ', COALESCE((COALESCE(cs.product_original_amount, 0) - COALESCE(cs.product_original_amount_last, 0)) / NULLIF(COALESCE(cs.product_original_amount_last, 0), 0), 0), ' }'), ', ' ORDER BY cp.period_name), ' }') metrics_by_period
        FROM category_level3_and_periods cp
        LEFT JOIN (
            SELECT
                cs.category_level3,
                cs.category_level1,
                cs.period_name,
                cs.product_original_amount,
                COALESCE(LAG(cs.product_original_amount) OVER (PARTITION BY cs.category_level3, cs.category_level1 ORDER BY cs.period_name DESC), cs.product_original_amount) AS product_original_amount_last
            FROM (
                SELECT
                    cs.category_level3,
                    cs.category_level1,
                    dp.period_name,
                    SUM(cs.product_original_amount) product_original_amount
                FROM (
                    SELECT
                        commodity_code_to_category_level3.category_level3,
                        commodity_code_to_category_level3.category_level1,
                        CONCAT(SUBSTRING(cs.date_str, 1, 4), SUBSTRING(cs.date_str, 6, 2), SUBSTRING(cs.date_str, 9, 2)) date_str,
                        SUM(CAST(COALESCE(product_original_amount, '0') AS REAL)) product_original_amount
                    FROM dwd_store_sales_commodity_stats_di_1d cs
                    LEFT JOIN (
                        SELECT
                            product_code,
                            MAX(category_level3) category_level3,
                            MAX(category_level1) category_level1
                        FROM dwd_store_common_commodity_extra_di_1d
                        GROUP BY
                            product_code
                    ) commodity_code_to_category_level3
                    ON cs.warehouse_store_sku_code = commodity_code_to_category_level3.product_code
                    WHERE
                        CONCAT(SUBSTRING(cs.date_str, 1, 4), SUBSTRING(cs.date_str, 6, 2), SUBSTRING(cs.date_str, 9, 2)) BETWEEN {start} AND {end}
                        [category_level1:AND commodity_code_to_category_level3.category_level1 = {category_level1}]
                        [category_level3:AND commodity_code_to_category_level3.category_level3 LIKE {category_level3}]
                        [shop_names:AND REPLACE(REPLACE(cs.store_name, '（', '('), '）', ')') = ANY({shop_names})]
                    GROUP BY commodity_code_to_category_level3.category_level3, commodity_code_to_category_level3.category_level1, cs.date_str
                ) cs
                LEFT JOIN date_to_period dp
                ON cs.date_str = dp.date_str
                GROUP BY cs.category_level3, cs.category_level1, dp.period_name
            ) cs
        ) cs
        ON cp.category_level3 = cs.category_level3 AND cp.category_level1 = cs.category_level1 AND cp.period_name = cs.period_name
        GROUP BY
            cp.category_level3, cp.category_level1
    ) p
    ON m.category_level3 = p.category_level3 AND m.category_level1 = p.category_level1
    $$,
    DEFAULT,
    DEFAULT
)
ON CONFLICT (tenant_id, view_code) DO UPDATE
SET view_sql = EXCLUDED.view_sql;



/*
curl -v "$TARGET/api/v1/views/scatter_share_of_category_level3/query" \
-H 'Content-Type: application/json' \
-H 'tenant_id: 1' \
-d '
{
    "params": {
        "start": "20250101",
        "end": "20251026",
        "period_type": "week",
        "max_period_distance": "5",
        "category_level1": "数码家电"
    }
}
'
*/
INSERT INTO views VALUES (
    'scatter_share_of_category_level3',
    '1',
    'scatter_share_of_category_level3',
    'comparable_card',
    $$
    WITH
    categories_level3 AS (
        SELECT category_level3, MAX(category_level1) category_level1
        FROM dwd_rival_stats_distincted_di_1d
        WHERE
            CASE WHEN LENGTH(date_str) < 8 THEN CONCAT('2025', date_str) ELSE date_str END BETWEEN {start} AND {end}
            [category_level1:AND category_level1 = {category_level1}]
            [category_level3:AND category_level3 LIKE {category_level3}]
            [shop_names:AND REPLACE(REPLACE(shop_name, '（', '('), '）', ')') = ANY({shop_names})]
        GROUP BY category_level3
    )
    SELECT
        m.category_level3,
        m.category_level1,
        m.transaction_amount,
        COALESCE(m.transaction_amount / NULLIF(r.transaction_amount, 0), 0) transaction_share,
        COALESCE(COALESCE(m.subsidy_amount, 0) / NULLIF(COALESCE(m.transaction_amount, 0), 0), 0) subsidy_rate
    FROM (
        SELECT
            c.category_level3,
            c.category_level1,
            COALESCE(t.transaction_amount, 0) transaction_amount,
            COALESCE(t.subsidy_amount, 0) subsidy_amount
        FROM categories_level3 c
        LEFT JOIN (
            SELECT
                category_level3,
                MAX(category_level1) category_level1,
                SUM(CAST(COALESCE(transaction_amount, '0') AS REAL)) transaction_amount,
                SUM(CAST(COALESCE(subsidy_amount, '0') AS REAL)) subsidy_amount
            FROM
                dwd_rival_stats_distincted_di_1d
            WHERE
                CASE WHEN LENGTH(date_str) < 8 THEN CONCAT('2025', date_str) ELSE date_str END BETWEEN {start} AND {end}
                [category_level1:AND category_level1 = {category_level1}]
                [category_level3:AND category_level3 LIKE {category_level3}]
                [shop_names:AND REPLACE(REPLACE(shop_name, '（', '('), '）', ')') = ANY({shop_names})]
            GROUP BY category_level3
        ) t
        ON c.category_level3 = t.category_level3 AND c.category_level1 = t.category_level1
    ) m,
    (
        SELECT
            SUM(CAST(COALESCE(transaction_amount, '0') AS REAL)) transaction_amount
        FROM
            dwd_rival_stats_distincted_di_1d
        WHERE
            CASE WHEN LENGTH(date_str) < 8 THEN CONCAT('2025', date_str) ELSE date_str END BETWEEN {start} AND {end}
            [category_level1:AND category_level1 = {category_level1}]
            [shop_names:AND REPLACE(REPLACE(shop_name, '（', '('), '）', ')') = ANY({shop_names})]
    ) r
    $$,
    DEFAULT,
    DEFAULT
)
ON CONFLICT (tenant_id, view_code) DO UPDATE
SET view_sql = EXCLUDED.view_sql;



/*
curl -v "$TARGET/api/v1/views/scatter_delta_of_category_level3/query" \
-H 'Content-Type: application/json' \
-H 'tenant_id: 1' \
-d '
{
    "params": {
        "start": "20250101",
        "end": "20251026",
        "period_type": "week",
        "max_period_distance": "5",
        "category_level1": "数码家电"
    }
}
'
*/
INSERT INTO views VALUES (
    'scatter_delta_of_category_level3',
    '1',
    'scatter_delta_of_category_level3',
    'comparable_card',
    $$
    WITH
    periods AS (
        SELECT CONCAT('p', period_index) period_name
        FROM (
            SELECT generate_series(0, {max_period_distance}::INT - 1) period_index
        ) t
    ),
    category_level3_and_periods AS (
        SELECT DISTINCT category_level3, MAX(category_level1) category_level1, p.period_name
        FROM dwd_rival_stats_distincted_di_1d, periods p
        WHERE 1 = 1
        [category_level1:AND category_level1 = {category_level1}]
        [category_level3:AND category_level3 LIKE {category_level3}]
        GROUP BY category_level3, p.period_name
    ),
    date_to_period AS (
        SELECT t.date_str, CONCAT('p', t.period_index) period_name
        FROM (
            WITH
                date_ref AS (SELECT CONCAT(SUBSTRING({end}, 1, 4), '-', SUBSTRING({end}, 5, 2), '-', SUBSTRING({end}, 7, 2))::DATE AS today),
                dates AS (
                    SELECT 
                        date_ref.today - n AS d,
                        date_ref.today
                    FROM date_ref, generate_series(0, 179) AS n
                )
            SELECT
                'day' period_type,
                TO_CHAR(d, 'YYYYMMDD') AS date_str,
                (today - d)::int AS period_index
            FROM dates
            UNION ALL
            SELECT
                'week' period_type,
                TO_CHAR(d, 'YYYYMMDD') AS date_str,
                ((DATE_TRUNC('week', today)::date - DATE_TRUNC('week', d)::date) / 7) AS period_index
            FROM dates
            UNION ALL
            SELECT
                'month' period_type,
                TO_CHAR(d, 'YYYYMMDD') AS date_str,
                (
                    EXTRACT(YEAR FROM today)::int - EXTRACT(YEAR FROM d)::int
                ) * 12 
                + 
                (
                    EXTRACT(MONTH FROM today)::int - EXTRACT(MONTH FROM d)::int
                ) AS period_index
            FROM dates
        ) t
        WHERE t.period_index < {max_period_distance}::INT AND t.period_type = {period_type}
    ),
    categories_level3 AS (
        SELECT category_level3, MAX(category_level1) category_level1
        FROM dwd_rival_stats_distincted_di_1d
        WHERE
            CASE WHEN LENGTH(date_str) < 8 THEN CONCAT('2025', date_str) ELSE date_str END BETWEEN {start} AND {end}
            [category_level1:AND category_level1 = {category_level1}]
            [category_level3:AND category_level3 LIKE {category_level3}]
            [shop_names:AND REPLACE(REPLACE(shop_name, '（', '('), '）', ')') = ANY({shop_names})]
        GROUP BY category_level3
    )
    SELECT
        c.category_level3,
        c.category_level1,
        COALESCE(t.transaction_amount, 0) transaction_amount,
        COALESCE(t.subsidy_amount, 0) subsidy_amount,
        COALESCE(COALESCE(t.subsidy_amount, 0) / NULLIF(COALESCE(t.transaction_amount, 0), 0), 0) subsidy_rate,
        COALESCE((COALESCE(t.transaction_amount, 0) - COALESCE(t.transaction_amount_last, 0)) / NULLIF(COALESCE(t.transaction_amount_last, 0), 0), 0) transaction_amount_wow
    FROM categories_level3 c
    LEFT JOIN (
        SELECT
            cs.category_level3,
            cs.category_level1,
            cs.period_name,
            cs.transaction_amount,
            cs.subsidy_amount,
            COALESCE(LAG(cs.transaction_amount) OVER (PARTITION BY cs.category_level3, cs.category_level1 ORDER BY cs.period_name DESC), cs.transaction_amount) AS transaction_amount_last
        FROM (
            SELECT
                cs.category_level3,
                cs.category_level1,
                dp.period_name,
                SUM(cs.transaction_amount) transaction_amount,
                SUM(cs.subsidy_amount) subsidy_amount
            FROM (
                SELECT
                    cs.category_level3,
                    cs.category_level1,
                    CASE WHEN LENGTH(date_str) < 8 THEN CONCAT('2025', date_str) ELSE date_str END date_str,
                    SUM(CAST(COALESCE(transaction_amount, '0') AS REAL)) transaction_amount,
                    SUM(CAST(COALESCE(subsidy_amount, '0') AS REAL)) subsidy_amount
                FROM dwd_rival_stats_distincted_di_1d cs
                WHERE
                    CASE WHEN LENGTH(date_str) < 8 THEN CONCAT('2025', date_str) ELSE date_str END BETWEEN {start} AND {end}
                    [category_level1:AND category_level1 = {category_level1}]
                    [category_level3:AND category_level3 LIKE {category_level3}]
                    [shop_names:AND REPLACE(REPLACE(cs.shop_name, '（', '('), '）', ')') = ANY({shop_names})]
                GROUP BY category_level3, category_level1, date_str
            ) cs
            LEFT JOIN date_to_period dp
            ON cs.date_str = dp.date_str
            GROUP BY cs.category_level3, cs.category_level1, dp.period_name
        ) cs
    ) t
    ON c.category_level3 = t.category_level3 AND c.category_level1 = t.category_level1 AND t.period_name = 'p0'
    $$,
    DEFAULT,
    DEFAULT
)
ON CONFLICT (tenant_id, view_code) DO UPDATE
SET view_sql = EXCLUDED.view_sql;
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
        "end": "20251026",
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
        dwd_rival_stats_distincted_di_1d
    WHERE
        CASE WHEN LENGTH(date_str) < 8 THEN CONCAT('2025', date_str) ELSE date_str END = {end}
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
        CASE WHEN LENGTH(s.date_str) < 8 THEN CONCAT('2025', s.date_str) ELSE s.date_str END = {end}
    ORDER BY category_level1
    $$,
    DEFAULT,
    DEFAULT
)
ON CONFLICT (tenant_id, view_code) DO UPDATE
SET view_sql = EXCLUDED.view_sql;




INSERT INTO views VALUES (
    'dropdown_level3_categories',
    '1',
    'dropdown_level3_categories',
    'comparable_card',
    $$
    SELECT
        DISTINCT
        category_level3 option_key,
        category_level3 option_value
    FROM
        dwd_rival_stats_distincted_di_1d s
    WHERE
        CASE WHEN LENGTH(s.date_str) < 8 THEN CONCAT('2025', s.date_str) ELSE s.date_str END = {end}
        AND s.category_level1 = {category_level1}
    ORDER BY category_level3
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
        CONCAT('¥', COALESCE(ROUND(SUM(CAST(COALESCE(s.transaction_amount, '0') AS DECIMAL(18,4)))::NUMERIC, 2), '0.00')::VARCHAR) amount_value
    FROM
        dwd_rival_stats_distincted_di_1d s
    WHERE
        CASE WHEN LENGTH(s.date_str) < 8 THEN CONCAT('2025', s.date_str) ELSE s.date_str END BETWEEN {start} AND {end}
        [category_level1:AND s.category_level1 LIKE {category_level1}]
        [shop_names:AND REPLACE(REPLACE(s.shop_name, '（', '('), '）', ')') = ANY({shop_names})]
    UNION ALL
    SELECT
        REPLACE(REPLACE(s.shop_name, '（', '('), '）', ')') amount_key,
        CONCAT('¥', COALESCE(ROUND(SUM(CAST(COALESCE(s.transaction_amount, '0') AS DECIMAL(18,4)))::NUMERIC, 2), '0.00')::VARCHAR) amount_value
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
            SUM(CAST(COALESCE(s.transaction_amount, '0') AS DECIMAL(18,4))) transaction_amount
        FROM
            dwd_rival_stats_distincted_di_1d s
        WHERE
            CASE WHEN LENGTH(s.date_str) < 8 THEN CONCAT('2025', s.date_str) ELSE s.date_str END BETWEEN {start} AND {end}
            [category_level1:AND s.category_level1 LIKE {category_level1}]
    ) d,
    (
        SELECT
            'self' merchant_name,
            SUM(CAST(COALESCE(s.transaction_amount, '0') AS DECIMAL(18,4))) transaction_amount
        FROM
            dwd_rival_stats_distincted_di_1d s
        WHERE
            CASE WHEN LENGTH(s.date_str) < 8 THEN CONCAT('2025', s.date_str) ELSE s.date_str END BETWEEN {start} AND {end}
            [category_level1:AND s.category_level1 LIKE {category_level1}]
            [shop_names:AND REPLACE(REPLACE(s.shop_name, '（', '('), '）', ')') = ANY({shop_names})]
        UNION ALL
        SELECT
            s.shop_name merchant_name,
            SUM(CAST(COALESCE(s.transaction_amount, '0') AS DECIMAL(18,4))) transaction_amount
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
        CONCAT(ROUND((COALESCE(100 * SUM(CAST(COALESCE(s.subsidy_amount, '0') AS DECIMAL(18,4))) / NULLIF(SUM(CAST(COALESCE(s.transaction_amount, '0') AS DECIMAL(18,4))), 0), 0))::NUMERIC, 2)::VARCHAR, '%') amount_value
    FROM
        dwd_rival_stats_distincted_di_1d s
    WHERE
        CASE WHEN LENGTH(s.date_str) < 8 THEN CONCAT('2025', s.date_str) ELSE s.date_str END BETWEEN {start} AND {end}
        [category_level1:AND s.category_level1 LIKE {category_level1}]
        [shop_names:AND REPLACE(REPLACE(s.shop_name, '（', '('), '）', ')') = ANY({shop_names})]
    UNION ALL
    SELECT
        REPLACE(REPLACE(s.shop_name, '（', '('), '）', ')') amount_key,
        CONCAT(ROUND((COALESCE(100 * SUM(CAST(COALESCE(s.subsidy_amount, '0') AS DECIMAL(18,4))) / NULLIF(SUM(CAST(COALESCE(s.transaction_amount, '0') AS DECIMAL(18,4))), 0), 0))::NUMERIC, 2)::VARCHAR, '%') amount_value
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
        WHERE
            CASE WHEN LENGTH(date_str) < 8 THEN CONCAT('2025', date_str) ELSE date_str END = {end}
            AND shop_owner = '竞对'
            AND REPLACE(REPLACE(shop_name, '（', '('), '）', ')') = ANY({rival_shop_names})
    ),
    category_level1_and_shops AS (
        SELECT category_level1, sh.shop_name
        FROM dwd_rival_stats_distincted_di_1d, shops sh
        WHERE
            CASE WHEN LENGTH(date_str) < 8 THEN CONCAT('2025', date_str) ELSE date_str END = {end}
            [category_level1:AND category_level1 LIKE {category_level1}]
        GROUP BY category_level1, sh.shop_name
    ),
    date_ref AS (SELECT CONCAT(SUBSTRING({end}, 1, 4), '-', SUBSTRING({end}, 5, 2), '-', SUBSTRING({end}, 7, 2))::DATE AS today),
    date_offsets AS (
        SELECT
            date_ref.today - n AS d,
            date_ref.today
        FROM date_ref, generate_series(0, 179) AS n
    ),
    date_to_period_raw AS (
        SELECT
            TO_CHAR(d, 'YYYYMMDD') AS date_str,
            (today - d)::INT AS day_index,
            ((DATE_TRUNC('week', today)::DATE - DATE_TRUNC('week', d)::DATE) / 7) AS week_index,
            (
                EXTRACT(YEAR FROM today)::INT - EXTRACT(YEAR FROM d)::INT
            ) * 12 
            + 
            (
                EXTRACT(MONTH FROM today)::INT - EXTRACT(MONTH FROM d)::INT
            ) AS month_index
        FROM date_offsets
    ),
    date_to_period AS (
        SELECT n.*, e.month_index weekend_month_index
        FROM date_to_period_raw n
        LEFT JOIN date_to_period_raw e
        ON DATE_TRUNC('week', CONCAT(SUBSTRING(n.date_str, 1, 4), '-', SUBSTRING(n.date_str, 5, 2), '-', SUBSTRING(n.date_str, 7, 2))::DATE + 7)::DATE - 1 = e.date_str::DATE
    ),
    category_level1_and_weeks AS (
        SELECT DISTINCT category_level1, dp.week_index
        FROM dwd_rival_stats_distincted_di_1d rd, date_to_period dp
        WHERE
            CASE WHEN LENGTH(rd.date_str) < 8 THEN CONCAT('2025', rd.date_str) ELSE rd.date_str END = {end}
            AND dp.weekend_month_index = 0
            [category_level1:AND category_level1 LIKE {category_level1}]
        GROUP BY category_level1, dp.week_index
    ),
    category_level1_and_days AS (
        SELECT DISTINCT category_level1, dp.day_index
        FROM dwd_rival_stats_distincted_di_1d rd, date_to_period dp
        WHERE
            CASE WHEN LENGTH(rd.date_str) < 8 THEN CONCAT('2025', rd.date_str) ELSE rd.date_str END = {end}
            AND dp.day_index < 14
            [category_level1:AND category_level1 LIKE {category_level1}]
        GROUP BY category_level1, dp.day_index
    ),
    self_monthly_from_rival_stats_distincted AS ( 
        SELECT
            category_level1,
            MAX(category_large) category_large,
            SUM(CAST(COALESCE(transaction_amount, '0') AS REAL)) transaction_amount,
            SUM(CAST(COALESCE(subsidy_amount, '0') AS REAL)) subsidy_amount
        FROM
            dwd_rival_stats_distincted_di_1d
        WHERE
            CASE WHEN LENGTH(date_str) < 8 THEN CONCAT('2025', date_str) ELSE date_str END = {end}
            AND REPLACE(REPLACE(shop_name, '（', '('), '）', ')') = {self_shop_name}
            [category_level1:AND category_level1 LIKE {category_level1}]
        GROUP BY
            category_level1
    ),
    self_monthly_from_store_common_commodity_extra AS ( 
        SELECT
            e.category_level1,
            COUNT(a.product_code) available_commodity_count,
            COUNT(s.product_code) sold_commodity_count
        FROM
            dwd_store_common_commodity_extra_di_1d e
        LEFT JOIN
            dwd_store_common_commodity_di_1d c
        ON
            c.dt = {end}
            AND e.product_code = c.product_code
        LEFT JOIN
            dwd_store_sales_commodity_availability_di_1d a
        ON
            a.dt = {end}
            AND e.product_code = a.product_code
            AND a.store_name = {self_shop_name}
            AND a.availability = '上线'
        LEFT JOIN (
            SELECT
                warehouse_store_sku_code product_code,
                SUM(product_quantity::INT) product_quantity
            FROM
                dwd_store_sales_commodity_stats_di_1d s
            WHERE
                dt = {end}
                AND store_name = {self_shop_name}
                AND date_str::DATE BETWEEN
                    CONCAT(SUBSTRING({end}, 1, 4), '-', SUBSTRING({end}, 5, 2), '-', SUBSTRING({end}, 7, 2))::DATE - 35
                    AND CONCAT(SUBSTRING({end}, 1, 4), '-', SUBSTRING({end}, 5, 2), '-', SUBSTRING({end}, 7, 2))::DATE
            GROUP BY
                warehouse_store_sku_code
        ) s
        ON
            a.product_code = s.product_code
            AND s.product_quantity > 0
        WHERE
            e.dt = {end}
            [category_level1:AND e.category_level1 LIKE {category_level1}]
        GROUP BY
            e.category_level1
    ),
    rivals_monthly_distincted AS (
        SELECT
            category_level1,
            shop_owner,
            REPLACE(REPLACE(shop_name, '（', '('), '）', ')') shop_name,
            COUNT(COALESCE(product_name, '')) available_commodity_count_distincted,
            SUM(CAST(COALESCE(transaction_amount, '0') AS REAL)) transaction_amount,
            SUM(CAST(COALESCE(subsidy_amount, '0') AS REAL)) subsidy_amount
        FROM
            dwd_rival_stats_distincted_di_1d
        WHERE
            CASE WHEN LENGTH(date_str) < 8 THEN CONCAT('2025', date_str) ELSE date_str END = {end}
            AND REPLACE(REPLACE(shop_name, '（', '('), '）', ')') = ANY({rival_shop_names})
            [category_level1:AND category_level1 LIKE {category_level1}]
        GROUP BY
            category_level1,
            shop_owner,
            shop_name
    ),
    rivals_monthly AS (
        SELECT
            category_level1,
            REPLACE(REPLACE(shop_name, '（', '('), '）', ')') shop_name,
            COUNT(COALESCE(product_name, '')) available_commodity_count,
            COUNT(CASE WHEN COALESCE(monthly_sales, '0')::INT > 0 THEN 1 ELSE NULL END) sold_commodity_count
        FROM
            dwd_rival_stats_di_1d
        WHERE
            CASE WHEN LENGTH(date_str) < 8 THEN CONCAT('2025', date_str) ELSE date_str END = {end}
            AND REPLACE(REPLACE(shop_name, '（', '('), '）', ')') = ANY({rival_shop_names})
            [category_level1:AND category_level1 LIKE {category_level1}]
        GROUP BY
            category_level1,
            shop_name
    ),
    self_by_week AS (
        SELECT
            cs.category_level1,
            CONCAT('{ ', STRING_AGG(CONCAT('"', CONCAT('p', cs.week_index), '": { "product_original_amount": ', COALESCE(cs.product_original_amount, 0), ', "product_original_amount_last": ', COALESCE(cs.product_original_amount_last, 0), ', "product_original_amount_delta": ', COALESCE(cs.product_original_amount, 0) - COALESCE(cs.product_original_amount_last, 0), ', "product_original_amount_wow": ', COALESCE((COALESCE(cs.product_original_amount, 0) - COALESCE(cs.product_original_amount_last, 0)) / NULLIF(COALESCE(cs.product_original_amount_last, 0), 0), 0), ' }'), ', ' ORDER BY cs.week_index), ' }') metrics_by_period
        FROM (
            SELECT
                cw.category_level1,
                cw.week_index,
                COALESCE(cs.product_original_amount, 0) product_original_amount,
                COALESCE(cs.product_original_amount_last, 0) product_original_amount_last
            FROM category_level1_and_weeks cw
            LEFT JOIN (
                SELECT
                    cs.category_level1,
                    cs.week_index,
                    cs.product_original_amount,
                    COALESCE(LAG(cs.product_original_amount) OVER (PARTITION BY cs.category_level1 ORDER BY cs.week_index DESC), cs.product_original_amount) AS product_original_amount_last
                FROM (
                    SELECT
                        cs.category_level1,
                        dp.week_index,
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
                            WHERE
                                dt = {end}
                            GROUP BY
                                product_code
                        ) commodity_code_to_category_level1
                        ON cs.warehouse_store_sku_code = commodity_code_to_category_level1.product_code
                        WHERE
                            cs.store_name = {self_shop_name}
                            AND cs.date_str::DATE BETWEEN
                                CONCAT(SUBSTRING({end}, 1, 4), '-', SUBSTRING({end}, 5, 2), '-', SUBSTRING({end}, 7, 2))::DATE - 35
                                AND CONCAT(SUBSTRING({end}, 1, 4), '-', SUBSTRING({end}, 5, 2), '-', SUBSTRING({end}, 7, 2))::DATE
                            [category_level1:AND commodity_code_to_category_level1.category_level1 LIKE {category_level1}]
                        GROUP BY commodity_code_to_category_level1.category_level1, cs.date_str
                    ) cs
                    JOIN date_to_period dp
                    ON
                        cs.date_str = dp.date_str
                        AND dp.weekend_month_index = 0
                    GROUP BY cs.category_level1, dp.week_index
                ) cs
            ) cs
            ON
                cw.category_level1 = cs.category_level1
                AND cw.week_index = cs.week_index
        ) cs
        GROUP BY
            cs.category_level1
    ),
    self_by_day AS (
        SELECT
            cs.category_level1,
            CONCAT('{ ', STRING_AGG(CONCAT('"', CONCAT('p', cs.day_index), '": { "product_original_amount": ', COALESCE(cs.product_original_amount, 0), ', "product_original_amount_last": ', COALESCE(cs.product_original_amount_last, 0), ', "product_original_amount_delta": ', COALESCE(cs.product_original_amount, 0) - COALESCE(cs.product_original_amount_last, 0), ', "product_original_amount_wow": ', COALESCE((COALESCE(cs.product_original_amount, 0) - COALESCE(cs.product_original_amount_last, 0)) / NULLIF(COALESCE(cs.product_original_amount_last, 0), 0), 0), ' }'), ', ' ORDER BY cs.day_index), ' }') metrics_by_period
        FROM (
            SELECT
                cd.category_level1,
                cd.day_index,
                COALESCE(cs.product_original_amount, 0) product_original_amount,
                COALESCE(cs.product_original_amount_last, 0) product_original_amount_last
            FROM category_level1_and_days cd
            LEFT JOIN (
                SELECT
                    cs.category_level1,
                    cs.day_index,
                    cs.product_original_amount,
                    COALESCE(LAG(cs.product_original_amount) OVER (PARTITION BY cs.category_level1 ORDER BY cs.day_index DESC), cs.product_original_amount) AS product_original_amount_last
                FROM (
                    SELECT
                        cs.category_level1,
                        dp.day_index,
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
                            WHERE
                                dt = {end}
                            GROUP BY
                                product_code
                        ) commodity_code_to_category_level1
                        ON cs.warehouse_store_sku_code = commodity_code_to_category_level1.product_code
                        WHERE
                            cs.store_name = {self_shop_name}
                            AND cs.date_str::DATE BETWEEN
                                CONCAT(SUBSTRING({end}, 1, 4), '-', SUBSTRING({end}, 5, 2), '-', SUBSTRING({end}, 7, 2))::DATE - 13
                                AND CONCAT(SUBSTRING({end}, 1, 4), '-', SUBSTRING({end}, 5, 2), '-', SUBSTRING({end}, 7, 2))::DATE
                            [category_level1:AND commodity_code_to_category_level1.category_level1 LIKE {category_level1}]
                        GROUP BY commodity_code_to_category_level1.category_level1, cs.date_str
                    ) cs
                    LEFT JOIN date_to_period dp
                    ON
                        cs.date_str = dp.date_str
                    GROUP BY cs.category_level1, dp.day_index
                ) cs
            ) cs
            ON
                cd.category_level1 = cs.category_level1
                AND cd.day_index = cs.day_index
        ) cs
        GROUP BY
            cs.category_level1
    ),
    total AS (
        SELECT
            category_level1,
            SUM(CAST(COALESCE(transaction_amount, '0') AS REAL)) total_transaction_amount
        FROM
            dwd_rival_stats_distincted_di_1d
        WHERE
            CASE WHEN LENGTH(date_str) < 8 THEN CONCAT('2025', date_str) ELSE date_str END = {end}
            AND (
                REPLACE(REPLACE(shop_name, '（', '('), '）', ')') = {self_shop_name}
                OR REPLACE(REPLACE(shop_name, '（', '('), '）', ')') = ANY({rival_shop_names})
            )
            [category_level1:AND category_level1 LIKE {category_level1}]
        GROUP BY
            category_level1
    )
    SELECT
        smr.category_level1,
        smr.category_large,
        smr.transaction_amount,
        smr.subsidy_amount,
        COALESCE(sme.available_commodity_count, 0) available_commodity_count,
        COALESCE(sme.sold_commodity_count, 0) sold_commodity_count,
        COALESCE(COALESCE(smr.transaction_amount, 0) / NULLIF(COALESCE(t.total_transaction_amount, 0), 0), 0) transaction_share,
        COALESCE(COALESCE(smr.subsidy_amount, 0) / NULLIF(COALESCE(smr.transaction_amount, 0), 0), 0) subsidy_rate,
        COALESCE(r.metrics_by_shop, '{}') metrics_by_shop,
        COALESCE(sw.metrics_by_period, '{}') metrics_by_week,
        COALESCE(sd.metrics_by_period, '{}') metrics_by_day
    FROM
        self_monthly_from_rival_stats_distincted smr
    LEFT JOIN
        self_monthly_from_store_common_commodity_extra sme
    ON
        smr.category_level1 = sme.category_level1
    LEFT JOIN
        total t
    ON
        smr.category_level1 = t.category_level1
    LEFT JOIN (
        SELECT
            r.category_level1,
            CONCAT('{ ', STRING_AGG(CONCAT(
                '"', r.shop_name,
                '": ',
                '{ "available_commodity_count_distincted": ', r.available_commodity_count_distincted,
                ', "available_commodity_count": ', r.available_commodity_count,
                ', "sold_commodity_count": ', r.sold_commodity_count,
                ', "transaction_amount": ', r.transaction_amount,
                ', "transaction_amount_diff": ', COALESCE(r.self_transaction_amount, 0) - r.transaction_amount,
                ', "transaction_share": ', r.transaction_share,
                ', "subsidy_amount": ', r.subsidy_amount,
                ', "subsidy_rate": ', r.subsidy_rate,
                ' }'), ', ' ORDER BY r.shop_name), ' }') metrics_by_shop
        FROM (
            SELECT
                cs.category_level1,
                cs.shop_name,
                COALESCE(r.available_commodity_count_distincted, 0) available_commodity_count_distincted,
                COALESCE(r.transaction_amount, 0) transaction_amount,
                COALESCE(r.subsidy_amount, 0) subsidy_amount,
                COALESCE(r.available_commodity_count, 0) available_commodity_count,
                COALESCE(r.sold_commodity_count, 0) sold_commodity_count,
                COALESCE(r.transaction_share, 0) transaction_share,
                COALESCE(r.subsidy_rate, 0) subsidy_rate,
                COALESCE(r.self_transaction_amount, 0) self_transaction_amount
            FROM category_level1_and_shops cs
            LEFT JOIN (
                SELECT
                    rd.category_level1,
                    REPLACE(REPLACE(rd.shop_name, '（', '('), '）', ')') shop_name,
                    rd.available_commodity_count_distincted,
                    rd.transaction_amount,
                    rd.subsidy_amount,
                    r.available_commodity_count,
                    r.sold_commodity_count,
                    COALESCE(COALESCE(rd.transaction_amount, 0) / NULLIF(COALESCE(t.total_transaction_amount, 0), 0), 0) transaction_share,
                    COALESCE(COALESCE(rd.subsidy_amount, 0) / NULLIF(COALESCE(rd.transaction_amount, 0), 0), 0) subsidy_rate,
                    smr.transaction_amount self_transaction_amount
                FROM
                    rivals_monthly_distincted rd
                LEFT JOIN
                    rivals_monthly r
                ON
                    rd.category_level1 = r.category_level1
                    AND rd.shop_name = r.shop_name
                LEFT JOIN
                    total t
                ON
                    rd.category_level1 = t.category_level1
                LEFT JOIN
                    self_monthly_from_rival_stats_distincted smr
                ON
                    rd.category_level1 = smr.category_level1
                WHERE
                    rd.shop_owner = '竞对'
            ) r
            ON
                cs.category_level1 = r.category_level1
                AND cs.shop_name = r.shop_name
        ) r
        GROUP BY
            r.category_level1
    ) r
    ON
        smr.category_level1 = r.category_level1
    LEFT JOIN 
        self_by_week sw
    ON
        smr.category_level1 = sw.category_level1
    LEFT JOIN 
        self_by_day sd
    ON
        smr.category_level1 = sd.category_level1
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
                (today - d)::INT AS period_index
            FROM dates
            UNION ALL
            SELECT
                'week' period_type,
                TO_CHAR(d, 'YYYYMMDD') AS date_str,
                ((DATE_TRUNC('week', today)::DATE - DATE_TRUNC('week', d)::DATE) / 7) AS period_index
            FROM dates
            UNION ALL
            SELECT
                'month' period_type,
                TO_CHAR(d, 'YYYYMMDD') AS date_str,
                (
                    EXTRACT(YEAR FROM today)::INT - EXTRACT(YEAR FROM d)::INT
                ) * 12 
                + 
                (
                    EXTRACT(MONTH FROM today)::INT - EXTRACT(MONTH FROM d)::INT
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
        WHERE
            CASE WHEN LENGTH(date_str) < 8 THEN CONCAT('2025', date_str) ELSE date_str END = {end}
            AND shop_owner = '竞对'
            AND REPLACE(REPLACE(shop_name, '（', '('), '）', ')') = ANY({rival_shop_names})
    ),
    category_level3_and_shops AS (
        SELECT category_level3, MAX(category_level1) category_level1, sh.shop_name
        FROM dwd_rival_stats_distincted_di_1d, shops sh
        WHERE
            CASE WHEN LENGTH(date_str) < 8 THEN CONCAT('2025', date_str) ELSE date_str END = {end}
            [category_level1:AND category_level1 = {category_level1}]
            [category_level3:AND category_level3 LIKE {category_level3}]
        GROUP BY category_level3, sh.shop_name
    ),
    date_ref AS (SELECT CONCAT(SUBSTRING({end}, 1, 4), '-', SUBSTRING({end}, 5, 2), '-', SUBSTRING({end}, 7, 2))::DATE AS today),
    date_offsets AS (
        SELECT
            date_ref.today - n AS d,
            date_ref.today
        FROM date_ref, generate_series(0, 179) AS n
    ),
    date_to_period_raw AS (
        SELECT
            TO_CHAR(d, 'YYYYMMDD') AS date_str,
            (today - d)::INT AS day_index,
            ((DATE_TRUNC('week', today)::DATE - DATE_TRUNC('week', d)::DATE) / 7) AS week_index,
            (
                EXTRACT(YEAR FROM today)::INT - EXTRACT(YEAR FROM d)::INT
            ) * 12 
            + 
            (
                EXTRACT(MONTH FROM today)::INT - EXTRACT(MONTH FROM d)::INT
            ) AS month_index
        FROM date_offsets
    ),
    date_to_period AS (
        SELECT n.*, e.month_index weekend_month_index
        FROM date_to_period_raw n
        LEFT JOIN date_to_period_raw e
        ON DATE_TRUNC('week', CONCAT(SUBSTRING(n.date_str, 1, 4), '-', SUBSTRING(n.date_str, 5, 2), '-', SUBSTRING(n.date_str, 7, 2))::DATE + 7)::DATE - 1 = e.date_str::DATE
    ),
    category_level3_and_weeks AS (
        SELECT DISTINCT category_level3, MAX(category_level1) category_level1, dp.week_index
        FROM dwd_rival_stats_distincted_di_1d rd, date_to_period dp
        WHERE
            CASE WHEN LENGTH(rd.date_str) < 8 THEN CONCAT('2025', rd.date_str) ELSE rd.date_str END = {end}
            AND dp.weekend_month_index = 0
            [category_level1:AND category_level1 = {category_level1}]
            [category_level3:AND category_level3 LIKE {category_level3}]
        GROUP BY category_level3, dp.week_index
    ),
    category_level3_and_days AS (
        SELECT DISTINCT category_level3, MAX(category_level1) category_level1, dp.day_index
        FROM dwd_rival_stats_distincted_di_1d rd, date_to_period dp
        WHERE
            CASE WHEN LENGTH(rd.date_str) < 8 THEN CONCAT('2025', rd.date_str) ELSE rd.date_str END = {end}
            AND dp.day_index < 14
            [category_level1:AND category_level1 = {category_level1}]
            [category_level3:AND category_level3 LIKE {category_level3}]
        GROUP BY category_level3, dp.day_index
    ),
    self_monthly_from_rival_stats_distincted AS ( 
        SELECT
            category_level3,
            MAX(category_level1) category_level1,
            MAX(category_large) category_large,
            SUM(CAST(COALESCE(transaction_amount, '0') AS REAL)) transaction_amount,
            SUM(CAST(COALESCE(subsidy_amount, '0') AS REAL)) subsidy_amount
        FROM
            dwd_rival_stats_distincted_di_1d
        WHERE
            CASE WHEN LENGTH(date_str) < 8 THEN CONCAT('2025', date_str) ELSE date_str END = {end}
            AND REPLACE(REPLACE(shop_name, '（', '('), '）', ')') = {self_shop_name}
            [category_level1:AND category_level1 = {category_level1}]
            [category_level3:AND category_level3 LIKE {category_level3}]
        GROUP BY
            category_level3
    ),
    self_monthly_from_store_common_commodity_extra AS ( 
        SELECT
            e.category_level3,
            MAX(e.category_level1) category_level1,
            COUNT(a.product_code) available_commodity_count,
            COUNT(s.product_code) sold_commodity_count
        FROM
            dwd_store_common_commodity_extra_di_1d e
        LEFT JOIN
            dwd_store_common_commodity_di_1d c
        ON
            c.dt = {end}
            AND e.product_code = c.product_code
        LEFT JOIN
            dwd_store_sales_commodity_availability_di_1d a
        ON
            a.dt = {end}
            AND e.product_code = a.product_code
            AND a.store_name = {self_shop_name}
            AND a.availability = '上线'
        LEFT JOIN (
            SELECT
                warehouse_store_sku_code product_code,
                SUM(product_quantity::INT) product_quantity
            FROM
                dwd_store_sales_commodity_stats_di_1d s
            WHERE
                dt = {end}
                AND store_name = {self_shop_name}
                AND date_str::DATE BETWEEN
                    CONCAT(SUBSTRING({end}, 1, 4), '-', SUBSTRING({end}, 5, 2), '-', SUBSTRING({end}, 7, 2))::DATE - 35
                    AND CONCAT(SUBSTRING({end}, 1, 4), '-', SUBSTRING({end}, 5, 2), '-', SUBSTRING({end}, 7, 2))::DATE
            GROUP BY
                warehouse_store_sku_code
        ) s
        ON
            a.product_code = s.product_code
            AND s.product_quantity > 0
        WHERE
            e.dt = {end}
            [category_level1:AND e.category_level1 = {category_level1}]
            [category_level3:AND e.category_level3 LIKE {category_level3}]
        GROUP BY
            e.category_level3
    ),
    rivals_monthly_distincted AS (
        SELECT
            category_level3,
            MAX(category_level1) category_level1,
            shop_owner,
            REPLACE(REPLACE(shop_name, '（', '('), '）', ')') shop_name,
            COUNT(COALESCE(product_name, '')) available_commodity_count_distincted,
            SUM(CAST(COALESCE(transaction_amount, '0') AS REAL)) transaction_amount,
            SUM(CAST(COALESCE(subsidy_amount, '0') AS REAL)) subsidy_amount
        FROM
            dwd_rival_stats_distincted_di_1d
        WHERE
            CASE WHEN LENGTH(date_str) < 8 THEN CONCAT('2025', date_str) ELSE date_str END = {end}
            AND REPLACE(REPLACE(shop_name, '（', '('), '）', ')') = ANY({rival_shop_names})
            [category_level1:AND category_level1 = {category_level1}]
            [category_level3:AND category_level3 LIKE {category_level3}]
        GROUP BY
            category_level3,
            shop_owner,
            shop_name
    ),
    rivals_monthly AS (
        SELECT
            category_level3,
            MAX(category_level1) category_level1,
            REPLACE(REPLACE(shop_name, '（', '('), '）', ')') shop_name,
            COUNT(COALESCE(product_name, '')) available_commodity_count,
            COUNT(CASE WHEN COALESCE(monthly_sales, '0')::INT > 0 THEN 1 ELSE NULL END) sold_commodity_count
        FROM
            dwd_rival_stats_di_1d
        WHERE
            CASE WHEN LENGTH(date_str) < 8 THEN CONCAT('2025', date_str) ELSE date_str END = {end}
            AND REPLACE(REPLACE(shop_name, '（', '('), '）', ')') = ANY({rival_shop_names})
            [category_level1:AND category_level1 = {category_level1}]
            [category_level3:AND category_level3 LIKE {category_level3}]
        GROUP BY
            category_level3,
            shop_name
    ),
    self_by_week AS (
        SELECT
            cs.category_level3,
            cs.category_level1,
            CONCAT('{ ', STRING_AGG(CONCAT('"', CONCAT('p', cs.week_index), '": { "product_original_amount": ', COALESCE(cs.product_original_amount, 0), ', "product_original_amount_last": ', COALESCE(cs.product_original_amount_last, 0), ', "product_original_amount_delta": ', COALESCE(cs.product_original_amount, 0) - COALESCE(cs.product_original_amount_last, 0), ', "product_original_amount_wow": ', COALESCE((COALESCE(cs.product_original_amount, 0) - COALESCE(cs.product_original_amount_last, 0)) / NULLIF(COALESCE(cs.product_original_amount_last, 0), 0), 0), ' }'), ', ' ORDER BY cs.week_index), ' }') metrics_by_period
        FROM (
            SELECT
                cw.category_level3,
                cw.category_level1,
                cw.week_index,
                COALESCE(cs.product_original_amount, 0) product_original_amount,
                COALESCE(cs.product_original_amount_last, 0) product_original_amount_last
            FROM category_level3_and_weeks cw
            LEFT JOIN (
                SELECT
                    cs.category_level3,
                    cs.category_level1,
                    cs.week_index,
                    cs.product_original_amount,
                    COALESCE(LAG(cs.product_original_amount) OVER (PARTITION BY cs.category_level3, cs.category_level1 ORDER BY cs.week_index DESC), cs.product_original_amount) AS product_original_amount_last
                FROM (
                    SELECT
                        cs.category_level3,
                        cs.category_level1,
                        dp.week_index,
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
                                MAX(category_level1) category_level1,
                                MAX(category_level3) category_level3
                            FROM dwd_store_common_commodity_extra_di_1d
                            WHERE
                                dt = {end}
                            GROUP BY
                                product_code
                        ) commodity_code_to_category_level3
                        ON cs.warehouse_store_sku_code = commodity_code_to_category_level3.product_code
                        WHERE
                            cs.store_name = {self_shop_name}
                            AND cs.date_str::DATE BETWEEN
                                CONCAT(SUBSTRING({end}, 1, 4), '-', SUBSTRING({end}, 5, 2), '-', SUBSTRING({end}, 7, 2))::DATE - 35
                                AND CONCAT(SUBSTRING({end}, 1, 4), '-', SUBSTRING({end}, 5, 2), '-', SUBSTRING({end}, 7, 2))::DATE
                            [category_level1:AND commodity_code_to_category_level3.category_level1 = {category_level1}]
                            [category_level3:AND commodity_code_to_category_level3.category_level3 LIKE {category_level3}]
                        GROUP BY commodity_code_to_category_level3.category_level3, commodity_code_to_category_level3.category_level1, cs.date_str
                    ) cs
                    JOIN date_to_period dp
                    ON
                        cs.date_str = dp.date_str
                        AND dp.weekend_month_index = 0
                    GROUP BY cs.category_level3, cs.category_level1, dp.week_index
                ) cs
            ) cs
            ON
                cw.category_level3 = cs.category_level3
                AND cw.category_level1 = cs.category_level1
                AND cw.week_index = cs.week_index
        ) cs
        GROUP BY
            cs.category_level3,
            cs.category_level1
    ),
    self_by_day AS (
        SELECT
            cs.category_level3,
            cs.category_level1,
            CONCAT('{ ', STRING_AGG(CONCAT('"', CONCAT('p', cs.day_index), '": { "product_original_amount": ', COALESCE(cs.product_original_amount, 0), ', "product_original_amount_last": ', COALESCE(cs.product_original_amount_last, 0), ', "product_original_amount_delta": ', COALESCE(cs.product_original_amount, 0) - COALESCE(cs.product_original_amount_last, 0), ', "product_original_amount_wow": ', COALESCE((COALESCE(cs.product_original_amount, 0) - COALESCE(cs.product_original_amount_last, 0)) / NULLIF(COALESCE(cs.product_original_amount_last, 0), 0), 0), ' }'), ', ' ORDER BY cs.day_index), ' }') metrics_by_period
        FROM (
            SELECT
                cd.category_level3,
                cd.category_level1,
                cd.day_index,
                COALESCE(cs.product_original_amount, 0) product_original_amount,
                COALESCE(cs.product_original_amount_last, 0) product_original_amount_last
            FROM category_level3_and_days cd
            LEFT JOIN (
                SELECT
                    cs.category_level3,
                    cs.category_level1,
                    cs.day_index,
                    cs.product_original_amount,
                    COALESCE(LAG(cs.product_original_amount) OVER (PARTITION BY cs.category_level3, cs.category_level1 ORDER BY cs.day_index DESC), cs.product_original_amount) AS product_original_amount_last
                FROM (
                    SELECT
                        cs.category_level3,
                        cs.category_level1,
                        dp.day_index,
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
                            WHERE
                                dt = {end}
                            GROUP BY
                                product_code
                        ) commodity_code_to_category_level3
                        ON cs.warehouse_store_sku_code = commodity_code_to_category_level3.product_code
                        WHERE
                            cs.store_name = {self_shop_name}
                            AND cs.date_str::DATE BETWEEN
                                CONCAT(SUBSTRING({end}, 1, 4), '-', SUBSTRING({end}, 5, 2), '-', SUBSTRING({end}, 7, 2))::DATE - 13
                                AND CONCAT(SUBSTRING({end}, 1, 4), '-', SUBSTRING({end}, 5, 2), '-', SUBSTRING({end}, 7, 2))::DATE
                            [category_level1:AND commodity_code_to_category_level3.category_level1 = {category_level1}]
                            [category_level3:AND commodity_code_to_category_level3.category_level3 LIKE {category_level3}]
                        GROUP BY commodity_code_to_category_level3.category_level3, commodity_code_to_category_level3.category_level1, cs.date_str
                    ) cs
                    LEFT JOIN date_to_period dp
                    ON
                        cs.date_str = dp.date_str
                    GROUP BY cs.category_level3, cs.category_level1, dp.day_index
                ) cs
            ) cs
            ON
                cd.category_level3 = cs.category_level3
                AND cd.category_level1 = cs.category_level1
                AND cd.day_index = cs.day_index
        ) cs
        GROUP BY
            cs.category_level3,
            cs.category_level1
    ),
    total AS (
        SELECT
            category_level3,
            MAX(category_level1) category_level1,
            SUM(CAST(COALESCE(transaction_amount, '0') AS REAL)) total_transaction_amount
        FROM
            dwd_rival_stats_distincted_di_1d
        WHERE
            CASE WHEN LENGTH(date_str) < 8 THEN CONCAT('2025', date_str) ELSE date_str END = {end}
            AND (
                REPLACE(REPLACE(shop_name, '（', '('), '）', ')') = {self_shop_name}
                OR REPLACE(REPLACE(shop_name, '（', '('), '）', ')') = ANY({rival_shop_names})
            )
            [category_level1:AND category_level1 = {category_level1}]
            [category_level3:AND category_level3 LIKE {category_level3}]
        GROUP BY
            category_level3
    )
    SELECT
        smr.category_level3,
        smr.category_level1,
        smr.category_large,
        smr.transaction_amount,
        smr.subsidy_amount,
        COALESCE(sme.available_commodity_count, 0) available_commodity_count,
        COALESCE(sme.sold_commodity_count, 0) sold_commodity_count,
        COALESCE(COALESCE(smr.transaction_amount, 0) / NULLIF(COALESCE(t.total_transaction_amount, 0), 0), 0) transaction_share,
        COALESCE(COALESCE(smr.subsidy_amount, 0) / NULLIF(COALESCE(smr.transaction_amount, 0), 0), 0) subsidy_rate,
        COALESCE(r.metrics_by_shop, '{}') metrics_by_shop,
        COALESCE(sw.metrics_by_period, '{}') metrics_by_week,
        COALESCE(sd.metrics_by_period, '{}') metrics_by_day
    FROM
        self_monthly_from_rival_stats_distincted smr
    LEFT JOIN
        self_monthly_from_store_common_commodity_extra sme
    ON
        smr.category_level3 = sme.category_level3
        AND smr.category_level1 = sme.category_level1
    LEFT JOIN
        total t
    ON
        smr.category_level3 = t.category_level3
        AND smr.category_level1 = t.category_level1
    LEFT JOIN (
        SELECT
            r.category_level3,
            r.category_level1,
            CONCAT('{ ', STRING_AGG(CONCAT(
                '"', r.shop_name,
                '": ',
                '{ "available_commodity_count_distincted": ', r.available_commodity_count_distincted,
                ', "available_commodity_count": ', r.available_commodity_count,
                ', "sold_commodity_count": ', r.sold_commodity_count,
                ', "transaction_amount": ', r.transaction_amount,
                ', "transaction_amount_diff": ', COALESCE(r.self_transaction_amount, 0) - r.transaction_amount,
                ', "transaction_share": ', r.transaction_share,
                ', "subsidy_amount": ', r.subsidy_amount,
                ', "subsidy_rate": ', r.subsidy_rate,
                ' }'), ', ' ORDER BY r.shop_name), ' }') metrics_by_shop
        FROM (
            SELECT
                cs.category_level3,
                cs.category_level1,
                cs.shop_name,
                COALESCE(r.available_commodity_count_distincted, 0) available_commodity_count_distincted,
                COALESCE(r.transaction_amount, 0) transaction_amount,
                COALESCE(r.subsidy_amount, 0) subsidy_amount,
                COALESCE(r.available_commodity_count, 0) available_commodity_count,
                COALESCE(r.sold_commodity_count, 0) sold_commodity_count,
                COALESCE(r.transaction_share, 0) transaction_share,
                COALESCE(r.subsidy_rate, 0) subsidy_rate,
                COALESCE(r.self_transaction_amount, 0) self_transaction_amount
            FROM category_level3_and_shops cs
            LEFT JOIN (
                SELECT
                    rd.category_level3,
                    rd.category_level1,
                    REPLACE(REPLACE(rd.shop_name, '（', '('), '）', ')') shop_name,
                    rd.available_commodity_count_distincted,
                    rd.transaction_amount,
                    rd.subsidy_amount,
                    r.available_commodity_count,
                    r.sold_commodity_count,
                    COALESCE(COALESCE(rd.transaction_amount, 0) / NULLIF(COALESCE(t.total_transaction_amount, 0), 0), 0) transaction_share,
                    COALESCE(COALESCE(rd.subsidy_amount, 0) / NULLIF(COALESCE(rd.transaction_amount, 0), 0), 0) subsidy_rate,
                    smr.transaction_amount self_transaction_amount
                FROM
                    rivals_monthly_distincted rd
                LEFT JOIN
                    rivals_monthly r
                ON
                    rd.category_level3 = r.category_level3
                    AND rd.category_level1 = r.category_level1
                    AND rd.shop_name = r.shop_name
                LEFT JOIN
                    total t
                ON
                    rd.category_level3 = t.category_level3
                    AND rd.category_level1 = t.category_level1
                LEFT JOIN
                    self_monthly_from_rival_stats_distincted smr
                ON
                    rd.category_level3 = smr.category_level3
                    AND rd.category_level1 = smr.category_level1
                WHERE
                    rd.shop_owner = '竞对'
            ) r
            ON
                cs.category_level3 = r.category_level3
                AND cs.category_level1 = r.category_level1
                AND cs.shop_name = r.shop_name
        ) r
        GROUP BY
            r.category_level3,
            r.category_level1
    ) r
    ON
        smr.category_level3 = r.category_level3
        AND smr.category_level1 = r.category_level1
    LEFT JOIN 
        self_by_week sw
    ON
        smr.category_level3 = sw.category_level3
        AND smr.category_level1 = sw.category_level1
    LEFT JOIN 
        self_by_day sd
    ON
        smr.category_level3 = sd.category_level3
        AND smr.category_level1 = sd.category_level1
    LIMIT 1000
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
                (today - d)::INT AS period_index
            FROM dates
            UNION ALL
            SELECT
                'week' period_type,
                TO_CHAR(d, 'YYYYMMDD') AS date_str,
                ((DATE_TRUNC('week', today)::DATE - DATE_TRUNC('week', d)::DATE) / 7) AS period_index
            FROM dates
            UNION ALL
            SELECT
                'month' period_type,
                TO_CHAR(d, 'YYYYMMDD') AS date_str,
                (
                    EXTRACT(YEAR FROM today)::INT - EXTRACT(YEAR FROM d)::INT
                ) * 12 
                + 
                (
                    EXTRACT(MONTH FROM today)::INT - EXTRACT(MONTH FROM d)::INT
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



INSERT INTO views VALUES (
    'table_of_sku',
    '1',
    'table_of_sku',
    'comparable_card',
    $$
    WITH
    date_ref AS (SELECT CONCAT(SUBSTRING({end}, 1, 4), '-', SUBSTRING({end}, 5, 2), '-', SUBSTRING({end}, 7, 2))::DATE AS today),
    date_offsets AS (
        SELECT
            date_ref.today - n AS d,
            date_ref.today
        FROM date_ref, generate_series(0, 179) AS n
    ),
    date_to_period_raw AS (
        SELECT
            TO_CHAR(d, 'YYYYMMDD') AS date_str,
            (today - d)::INT AS day_index,
            ((DATE_TRUNC('week', today)::DATE - DATE_TRUNC('week', d)::DATE) / 7) AS week_index,
            (
                EXTRACT(YEAR FROM today)::INT - EXTRACT(YEAR FROM d)::INT
            ) * 12 
            + 
            (
                EXTRACT(MONTH FROM today)::INT - EXTRACT(MONTH FROM d)::INT
            ) AS month_index
        FROM date_offsets
    ),
    date_to_period AS (
        SELECT n.*, e.month_index weekend_month_index
        FROM date_to_period_raw n
        LEFT JOIN date_to_period_raw e
        ON DATE_TRUNC('week', CONCAT(SUBSTRING(n.date_str, 1, 4), '-', SUBSTRING(n.date_str, 5, 2), '-', SUBSTRING(n.date_str, 7, 2))::DATE + 7)::DATE - 1 = e.date_str::DATE
    ),
    sku_and_weeks AS (
        SELECT DISTINCT product_id product_code, MAX(upc_code) upc_code, dp.week_index
        FROM dwd_rival_stats_distincted_di_1d rd, date_to_period dp
        WHERE
            CASE WHEN LENGTH(rd.date_str) < 8 THEN CONCAT('2025', rd.date_str) ELSE rd.date_str END = {end}
            AND dp.weekend_month_index = 0
            [category_level1:AND category_level1 = {category_level1}]
            [category_level3:AND category_level3 = {category_level3}]
            [product_keyword:AND (product_id = TRIM(BOTH '%' FROM {product_keyword}) OR product_name LIKE {product_keyword})]
        GROUP BY product_id, dp.week_index
    ),
    self_monthly_from_rival_stats_distincted AS ( 
        SELECT
            product_id product_code,
            MAX(sku_id) sku_id,
            MAX(upc_code) upc_code,
            MAX(category_large) category_large,
            MAX(category_level1) category_level1,
            MAX(category_level3) category_level3,
            MAX(classification_level1) classification_level1,
            MAX(classification_level2) classification_level2,
            MAX(product_name) product_name,
            MAX(spec) spec,
            MAX(original_price) original_price,
            MAX(activity_price) activity_price,
            MAX(final_price) final_price,
            MAX(coupon) coupon,
            MAX(monthly_sales) monthly_sales,
            MAX(min_order_qty) min_order_qty,
            MAX(CAST(COALESCE(NULLIF(activity_price, ''), '0') AS REAL) - (CAST(COALESCE(NULLIF(min_order_qty, ''), '0') AS REAL) - 1.0) * CAST(COALESCE(NULLIF(original_price, ''), '0') AS REAL)) adjusted_activity_price,
            MAX(CAST(COALESCE(NULLIF(monthly_sales, ''), '0') AS REAL) * CAST(COALESCE(NULLIF(original_price, ''), '0') AS REAL)) transaction_amount,
            MAX((CAST(COALESCE(NULLIF(original_price, ''), '0') AS REAL) - (CAST(COALESCE(NULLIF(activity_price, ''), '0') AS REAL) - (CAST(COALESCE(NULLIF(min_order_qty, ''), '0') AS REAL) - 1.0) * CAST(COALESCE(NULLIF(original_price, ''), '0') AS REAL))) * CAST(COALESCE(NULLIF(monthly_sales, ''), '0') AS REAL)) subsidy_amount,
            MAX((CAST(COALESCE(NULLIF(activity_price, ''), '0') AS REAL) - (CAST(COALESCE(NULLIF(min_order_qty, ''), '0') AS REAL) - 1.0) * CAST(COALESCE(NULLIF(original_price, ''), '0') AS REAL)) / NULLIF(CAST(COALESCE(NULLIF(original_price, ''), '0') AS REAL), 0)) discount_rate
        FROM
            dwd_rival_stats_distincted_di_1d
        WHERE
            CASE WHEN LENGTH(date_str) < 8 THEN CONCAT('2025', date_str) ELSE date_str END = {end}
            -- AND REPLACE(REPLACE(shop_name, '（', '('), '）', ')') = {self_shop_name}
            [category_level1:AND category_level1 = {category_level1}]
            [category_level3:AND category_level3 = {category_level3}]
            [product_keyword:AND (product_id = TRIM(BOTH '%' FROM {product_keyword}) OR product_name LIKE {product_keyword})]
        GROUP BY
            product_id
    ),
    self_monthly_from_store_common_commodity AS ( 
        SELECT
            c.barcode,
            MAX(c.product_code) product_code,
            MAX(c.product_name) product_name,
            MAX(e.product_level) product_level,
            MAX(c.meituan_sale_status) meituan_sale_status,
            MAX(c.online_stock) online_stock,
            MAX(c.meituan_min_qty) meituan_min_qty,
            MAX(s.product_quantity) product_quantity,
            MAX(CAST(COALESCE(s.product_quantity, 0) AS REAL) * CAST(COALESCE(NULLIF(c.meituan_price, ''), '0') AS REAL)) transaction_amount,
            MAX(c.meituan_price) meituan_price,
            MAX(pa.promo_price) promo_price,
            MAX(pa.activity_start_time) activity_start_time,
            MAX(CAST(COALESCE(NULLIF(c.meituan_price, ''), '0') AS REAL) - CAST(COALESCE(NULLIF(pa.promo_price, ''), '0') AS REAL)) single_product_subsidy_amount,
            MAX(CAST(COALESCE(NULLIF(pa.promo_price, ''), '0') AS REAL) / NULLIF(CAST(COALESCE(NULLIF(c.meituan_price, ''), '0') AS REAL), 0)) discount_rate
        FROM
            dwd_store_common_commodity_di_1d c
        LEFT JOIN
            dwd_store_common_commodity_extra_di_1d e
        ON
            e.dt = {end}
            AND c.product_code = e.product_code
        LEFT JOIN
            dwd_store_sales_commodity_availability_di_1d a
        ON
            a.dt = {end}
            AND c.product_code = a.product_code
            -- AND a.store_name = {self_shop_name}
            AND a.availability = '上线'
        LEFT JOIN (
            SELECT
                s.warehouse_store_sku_code product_code,
                SUM(s.product_quantity::INT) product_quantity
            FROM
                dwd_store_sales_commodity_stats_di_1d s
            JOIN date_to_period dp
            ON
                CONCAT(SUBSTRING(s.date_str, 1, 4), SUBSTRING(s.date_str, 6, 2), SUBSTRING(s.date_str, 9, 2)) = dp.date_str
                AND dp.weekend_month_index = 0
            WHERE
                s.dt = {end}
            GROUP BY
                s.warehouse_store_sku_code
        ) s
        ON
            c.product_code = s.product_code
        LEFT JOIN (
            SELECT
                product_code,
                MAX(promo_price) promo_price,
                MAX(activity_start_time) activity_start_time
            FROM
                dwd_promotion_activity_di_1d pa
            WHERE
                dt = {end}
            GROUP BY
                product_code
        ) pa  
        ON
            c.product_code = pa.product_code
        WHERE
            c.dt = {end}
            [product_keyword:AND (c.product_code = TRIM(BOTH '%' FROM {product_keyword}) OR c.product_name LIKE {product_keyword})]
        GROUP BY
            c.barcode
    ),
    self_by_week AS (
        SELECT
            c.barcode,
            cs.metrics_by_period
        FROM
            dwd_store_common_commodity_di_1d c
        JOIN (
            SELECT
                cs.product_code,
                CONCAT('{ ', STRING_AGG(CONCAT('"', CONCAT('p', cs.week_index), '": { "product_quantity": ', COALESCE(cs.product_quantity, 0), ', "product_quantity_last": ', COALESCE(cs.product_quantity_last, 0), ', "product_quantity_delta": ', COALESCE(cs.product_quantity, 0) - COALESCE(cs.product_quantity_last, 0), ', "product_quantity_wow": ', COALESCE((COALESCE(cs.product_quantity, 0) - COALESCE(cs.product_quantity_last, 0)) / NULLIF(COALESCE(cs.product_quantity_last, 0), 0), 0), ', "transaction_amount": ', COALESCE(cs.transaction_amount, 0), ', "transaction_amount_last": ', COALESCE(cs.transaction_amount_last, 0), ', "transaction_amount_delta": ', COALESCE(cs.transaction_amount, 0) - COALESCE(cs.transaction_amount_last, 0), ', "transaction_amount_wow": ', COALESCE((COALESCE(cs.transaction_amount, 0) - COALESCE(cs.transaction_amount_last, 0)) / NULLIF(COALESCE(cs.transaction_amount_last, 0), 0), 0), ' }'), ', ' ORDER BY cs.week_index), ' }') metrics_by_period
            FROM (
                SELECT
                    sw.upc_code,
                    sw.week_index,
                    cs.product_code,
                    CAST(COALESCE(NULLIF(cs.meituan_price, ''), '0') AS REAL) meituan_price,
                    COALESCE(cs.product_quantity, 0) product_quantity,
                    COALESCE(cs.product_quantity_last, 0) product_quantity_last,
                    COALESCE(cs.product_quantity, 0) * CAST(COALESCE(NULLIF(cs.meituan_price, ''), '0') AS REAL) transaction_amount,
                    COALESCE(cs.product_quantity_last, 0) * CAST(COALESCE(NULLIF(cs.meituan_price, ''), '0') AS REAL) transaction_amount_last
                FROM sku_and_weeks sw
                LEFT JOIN (
                    SELECT
                        c.barcode,
                        c.meituan_price,
                        cs.product_code,
                        cs.week_index,
                        cs.product_quantity,
                        cs.product_quantity_last
                    FROM
                        dwd_store_common_commodity_di_1d c
                    JOIN (
                        SELECT
                            cs.product_code,
                            cs.week_index,
                            cs.product_quantity,
                            COALESCE(LAG(cs.product_quantity) OVER (PARTITION BY cs.product_code ORDER BY cs.week_index DESC), cs.product_quantity) AS product_quantity_last
                        FROM (
                            SELECT
                                cs.product_code,
                                dp.week_index,
                                SUM(cs.product_quantity) product_quantity
                            FROM (
                                SELECT
                                    cs.warehouse_store_sku_code product_code,
                                    CONCAT(SUBSTRING(cs.date_str, 1, 4), SUBSTRING(cs.date_str, 6, 2), SUBSTRING(cs.date_str, 9, 2)) date_str,
                                    SUM(CAST(COALESCE(NULLIF(product_quantity, ''), '0') AS REAL)) product_quantity
                                FROM dwd_store_sales_commodity_stats_di_1d cs
                                WHERE
                                    -- cs.store_name = {self_shop_name} AND
                                    cs.date_str::DATE BETWEEN
                                        CONCAT(SUBSTRING({end}, 1, 4), '-', SUBSTRING({end}, 5, 2), '-', SUBSTRING({end}, 7, 2))::DATE - 35
                                        AND CONCAT(SUBSTRING({end}, 1, 4), '-', SUBSTRING({end}, 5, 2), '-', SUBSTRING({end}, 7, 2))::DATE
                                GROUP BY cs.warehouse_store_sku_code, cs.date_str
                            ) cs
                            JOIN date_to_period dp
                            ON
                                cs.date_str = dp.date_str
                                AND dp.weekend_month_index = 0
                            GROUP BY cs.product_code, dp.week_index
                        ) cs
                    ) cs
                    ON
                        c.product_code = cs.product_code
                    WHERE
                        c.dt = {end}
                ) cs
                ON
                    sw.upc_code = cs.barcode
                    AND sw.week_index = cs.week_index
            ) cs
            GROUP BY
                cs.product_code
        ) cs
        ON
            c.dt = {end}
            AND c.product_code = cs.product_code
    )
    SELECT
        smr.sku_id,
        smr.product_code,
        smr.upc_code,
        smr.category_large,
        smr.category_level1,
        smr.category_level3,
        smr.classification_level1,
        smr.classification_level2,
        smr.product_name,
        smr.spec,
        smr.original_price,
        smr.activity_price,
        smr.final_price,
        smr.coupon,
        smr.monthly_sales,
        smr.min_order_qty,
        smr.adjusted_activity_price,
        smr.transaction_amount,
        smr.subsidy_amount,
        smr.discount_rate,
        sme.product_code self_product_code,
        sme.product_name self_product_name,
        sme.product_level,
        '上下线?' product_availability,
        sme.meituan_sale_status,
        sme.online_stock,
        sme.meituan_min_qty,
        sme.product_quantity,
        sme.transaction_amount self_transaction_amount,
        COALESCE(sme.transaction_amount, 0) - COALESCE(smr.transaction_amount, 0) transaction_amount_diff,
        sme.meituan_price,
        sme.promo_price,
        '活动价小仓-竞对?' rival_promo_price,
        sme.activity_start_time,
        sme.single_product_subsidy_amount,
        sme.discount_rate self_discount_rate,
        '调整活动价?' adjusted_promo_price,
        '神价?' super_price,
        '调整活动价-竞对?' rival_adjusted_promo_price,
        '折扣率?' rival_discount_rate,
        CAST(COALESCE(NULLIF(smr.activity_price, ''), '0') AS REAL) - CAST(COALESCE(NULLIF(sme.meituan_price, ''), '0') AS REAL) price_diff,
        '动作周次?' week_index,
        COALESCE(sw.metrics_by_period, '{}') metrics_by_week
    FROM
        self_monthly_from_rival_stats_distincted smr
    LEFT JOIN
        self_monthly_from_store_common_commodity sme
    ON
        smr.upc_code != ''
        AND smr.upc_code = sme.barcode
    LEFT JOIN 
        self_by_week sw
    ON
        smr.upc_code != ''
        AND smr.upc_code = sw.barcode
    LIMIT 1000
    $$,
    DEFAULT,
    DEFAULT
)
ON CONFLICT (tenant_id, view_code) DO UPDATE
SET view_sql = EXCLUDED.view_sql;



INSERT INTO views VALUES (
    'table_of_activity',
    '1',
    'table_of_activity',
    'comparable_card',
    $$
    WITH
    date_ref AS (SELECT CONCAT(SUBSTRING({end}, 1, 4), '-', SUBSTRING({end}, 5, 2), '-', SUBSTRING({end}, 7, 2))::DATE AS today),
    date_offsets AS (
        SELECT
            date_ref.today - n AS d,
            date_ref.today
        FROM date_ref, generate_series(0, 179) AS n
    ),
    date_to_period_raw AS (
        SELECT
            TO_CHAR(d, 'YYYYMMDD') AS date_str,
            (today - d)::INT AS day_index,
            ((DATE_TRUNC('week', today)::DATE - DATE_TRUNC('week', d)::DATE) / 7) AS week_index,
            (
                EXTRACT(YEAR FROM today)::INT - EXTRACT(YEAR FROM d)::INT
            ) * 12 
            + 
            (
                EXTRACT(MONTH FROM today)::INT - EXTRACT(MONTH FROM d)::INT
            ) AS month_index
        FROM date_offsets
    ),
    date_to_period AS (
        SELECT n.*, e.month_index weekend_month_index
        FROM date_to_period_raw n
        LEFT JOIN date_to_period_raw e
        ON DATE_TRUNC('week', CONCAT(SUBSTRING(n.date_str, 1, 4), '-', SUBSTRING(n.date_str, 5, 2), '-', SUBSTRING(n.date_str, 7, 2))::DATE + 7)::DATE - 1 = e.date_str::DATE
    ),
    sku_and_weeks AS (
        SELECT DISTINCT product_code, MAX(barcode) barcode, dp.week_index
        FROM dwd_store_common_commodity_di_1d rd, date_to_period dp
        WHERE
            rd.dt = {end}
            AND dp.weekend_month_index = 0
            [product_keyword:AND (product_code = TRIM(BOTH '%' FROM {product_keyword}) OR product_name LIKE {product_keyword})]
        GROUP BY product_code, dp.week_index
    ),
    self_monthly_from_store_common_commodity AS ( 
        SELECT
            c.product_code,
            MAX(c.barcode) barcode,
            MAX(c.product_name) product_name,
            MAX(c.spec) spec,
            MAX(c.meituan_price) meituan_price,
            MAX(c.online_stock) online_stock,
            MAX(c.meituan_sale_status) meituan_sale_status,
            MAX(c.meituan_min_qty) meituan_min_qty
        FROM
            dwd_store_common_commodity_di_1d c
        WHERE
            c.dt = {end}
            [product_keyword:AND (product_code = TRIM(BOTH '%' FROM {product_keyword}) OR product_name LIKE {product_keyword})]
        GROUP BY
            c.product_code
    ),
    self_monthly_from_store_common_commodity_extra AS ( 
        SELECT
            c.product_code,
            MAX(c.product_category) product_category,
            MAX(c.category_level1) category_level1,
            MAX(c.category_level3) category_level3,
            MAX(c.spu) spu,
            MAX(c.product_level) product_level
        FROM
            dwd_store_common_commodity_extra_di_1d c
        WHERE
            c.dt = {end}
        GROUP BY
            c.product_code
    ),
    self_monthly_from_store_sales_commodity_stats AS ( 
        SELECT
            s.warehouse_store_sku_code product_code,
            SUM(s.product_quantity::INT) product_quantity
        FROM
            dwd_store_sales_commodity_stats_di_1d s
        JOIN date_to_period dp
        ON
            CONCAT(SUBSTRING(s.date_str, 1, 4), SUBSTRING(s.date_str, 6, 2), SUBSTRING(s.date_str, 9, 2)) = dp.date_str
            AND dp.weekend_month_index = 0
        WHERE
            s.dt = {end}
        GROUP BY
            s.warehouse_store_sku_code
    ),
    self_monthly_from_promotion_activity AS ( 
        SELECT
            product_code,
            MAX(promo_price) promo_price,
            MAX(activity_start_time) activity_start_time,
            MAX(activity_name) activity_name
        FROM
            dwd_promotion_activity_di_1d pa
        WHERE
            dt = {end}
        GROUP BY
            product_code
    ),
    self_by_week AS (
        SELECT
            c.product_code,
            cs.metrics_by_period
        FROM
            dwd_store_common_commodity_di_1d c
        JOIN (
            SELECT
                cs.product_code,
                CONCAT('{ ', STRING_AGG(CONCAT('"', CONCAT('p', cs.week_index), '": { "product_quantity": ', COALESCE(cs.product_quantity, 0), ', "product_quantity_last": ', COALESCE(cs.product_quantity_last, 0), ', "product_quantity_delta": ', COALESCE(cs.product_quantity, 0) - COALESCE(cs.product_quantity_last, 0), ', "product_quantity_wow": ', COALESCE((COALESCE(cs.product_quantity, 0) - COALESCE(cs.product_quantity_last, 0)) / NULLIF(COALESCE(cs.product_quantity_last, 0), 0), 0), ', "transaction_amount": ', COALESCE(cs.transaction_amount, 0), ', "transaction_amount_last": ', COALESCE(cs.transaction_amount_last, 0), ', "transaction_amount_delta": ', COALESCE(cs.transaction_amount, 0) - COALESCE(cs.transaction_amount_last, 0), ', "transaction_amount_wow": ', COALESCE((COALESCE(cs.transaction_amount, 0) - COALESCE(cs.transaction_amount_last, 0)) / NULLIF(COALESCE(cs.transaction_amount_last, 0), 0), 0), ' }'), ', ' ORDER BY cs.week_index), ' }') metrics_by_period
            FROM (
                SELECT
                    sw.product_code,
                    sw.week_index,
                    CAST(COALESCE(NULLIF(cs.meituan_price, ''), '0') AS REAL) meituan_price,
                    COALESCE(cs.product_quantity, 0) product_quantity,
                    COALESCE(cs.product_quantity_last, 0) product_quantity_last,
                    COALESCE(cs.product_quantity, 0) * CAST(COALESCE(NULLIF(cs.meituan_price, ''), '0') AS REAL) transaction_amount,
                    COALESCE(cs.product_quantity_last, 0) * CAST(COALESCE(NULLIF(cs.meituan_price, ''), '0') AS REAL) transaction_amount_last
                FROM sku_and_weeks sw
                LEFT JOIN (
                    SELECT
                        c.barcode,
                        c.meituan_price,
                        cs.product_code,
                        cs.week_index,
                        cs.product_quantity,
                        cs.product_quantity_last
                    FROM
                        dwd_store_common_commodity_di_1d c
                    JOIN (
                        SELECT
                            cs.product_code,
                            cs.week_index,
                            cs.product_quantity,
                            COALESCE(LAG(cs.product_quantity) OVER (PARTITION BY cs.product_code ORDER BY cs.week_index DESC), cs.product_quantity) AS product_quantity_last
                        FROM (
                            SELECT
                                cs.product_code,
                                dp.week_index,
                                SUM(cs.product_quantity) product_quantity
                            FROM (
                                SELECT
                                    cs.warehouse_store_sku_code product_code,
                                    CONCAT(SUBSTRING(cs.date_str, 1, 4), SUBSTRING(cs.date_str, 6, 2), SUBSTRING(cs.date_str, 9, 2)) date_str,
                                    SUM(CAST(COALESCE(NULLIF(product_quantity, ''), '0') AS REAL)) product_quantity
                                FROM dwd_store_sales_commodity_stats_di_1d cs
                                WHERE
                                    -- cs.store_name = {self_shop_name} AND
                                    cs.date_str::DATE BETWEEN
                                        CONCAT(SUBSTRING({end}, 1, 4), '-', SUBSTRING({end}, 5, 2), '-', SUBSTRING({end}, 7, 2))::DATE - 35
                                        AND CONCAT(SUBSTRING({end}, 1, 4), '-', SUBSTRING({end}, 5, 2), '-', SUBSTRING({end}, 7, 2))::DATE
                                GROUP BY cs.warehouse_store_sku_code, cs.date_str
                            ) cs
                            JOIN date_to_period dp
                            ON
                                cs.date_str = dp.date_str
                                AND dp.weekend_month_index = 0
                            GROUP BY cs.product_code, dp.week_index
                        ) cs
                    ) cs
                    ON
                        c.product_code = cs.product_code
                    WHERE
                        c.dt = {end}
                ) cs
                ON
                    sw.product_code = cs.product_code
                    AND sw.week_index = cs.week_index
            ) cs
            GROUP BY
                cs.product_code
        ) cs
        ON
            c.dt = {end}
            AND c.product_code = cs.product_code
    )
    SELECT
        smr.product_code,
        sme.product_category,
        sme.category_level1,
        sme.category_level3,
        sme.spu,
        sme.product_level,
        '上线?' product_availability,
        smr.product_name,
        smr.spec,
        smr.meituan_price,
        a.promo_price,
        CAST(COALESCE(NULLIF(smr.meituan_price, ''), '0') AS REAL) - CAST(COALESCE(NULLIF(a.promo_price, ''), '0') AS REAL) single_product_subsidy_amount,
        CAST(COALESCE(NULLIF(a.promo_price, ''), '0') AS REAL) / NULLIF(CAST(COALESCE(NULLIF(smr.meituan_price, ''), '0') AS REAL), 0) discount_rate,
        a.activity_start_time,
        a.activity_name,
        '调整折扣价?' adjusted_promo_price,
        '新折扣率?' new_discount_rate,
        '单品补贴?' new_single_product_subsidy_amount,
        '回收活动价?' recycle_promo_price,
        smr.online_stock,
        smr.meituan_sale_status,
        smr.meituan_min_qty,
        s.product_quantity,
        '动作周次?' week_index,
        COALESCE(sw.metrics_by_period, '{}') metrics_by_week
    FROM
        self_monthly_from_store_common_commodity smr
    LEFT JOIN
        self_monthly_from_store_common_commodity_extra sme
    ON
        smr.product_code = sme.product_code
    LEFT JOIN
        self_monthly_from_store_sales_commodity_stats s
    ON
        smr.product_code = s.product_code
    LEFT JOIN
        self_monthly_from_promotion_activity a
    ON
        smr.product_code = a.product_code
    LEFT JOIN 
        self_by_week sw
    ON
        smr.product_code = sw.product_code
    LIMIT 1000
    $$,
    DEFAULT,
    DEFAULT
)
ON CONFLICT (tenant_id, view_code) DO UPDATE
SET view_sql = EXCLUDED.view_sql;

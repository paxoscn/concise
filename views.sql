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
        s.date_str BETWEEN {start} AND {end}
        [category_level1:AND s.category_level1 = {category_level1}]
        [shop_names:AND s.shop_name IN {shop_names}]
    UNION ALL
    SELECT
        s.shop_name merchant_name,
        SUM(CAST(COALESCE(s.transaction_amount, '0') AS REAL)) transaction_amount
    FROM
        dwd_rival_stats_distincted_di_1d s
    WHERE
        s.date_str BETWEEN {start} AND {end}
        [category_level1:AND s.category_level1 = {category_level1}]
    GROUP BY s.shop_name
    $$,
    DEFAULT,
    DEFAULT
)
ON CONFLICT (tenant_id, view_code) DO UPDATE
SET view_sql = EXCLUDED.view_sql;
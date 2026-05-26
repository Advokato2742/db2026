WITH monthly_base AS (
    SELECT
        date_trunc('month', o.created) AS month_start,
        COUNT(DISTINCT o.order_id) AS order_count,
        SUM(oi.count) AS total_boxes,
        SUM(p.weight * oi.count) AS total_weight,
        mode() WITHIN GROUP (ORDER BY o.client_id) AS top_client_id
    FROM "Order" o
    JOIN OrderItem oi ON oi.order_id = o.order_id
    JOIN Product p ON p.article = oi.article
    WHERE o.created >= date_trunc('year', CURRENT_DATE - INTERVAL '1 year')
      	AND o.created < date_trunc('month', CURRENT_DATE + INTERVAL '1 month')
    GROUP BY date_trunc('month', o.created)
),
monthly_with_lag AS (
    SELECT
        month_start,
        order_count,
        total_boxes,
        total_weight,
        top_client_id,
        LAG(total_weight) OVER (ORDER BY month_start) AS prev_weight
    FROM monthly_base
)
select
	TO_CHAR(month_start, 'YYYY') AS year,
	TO_CHAR(month_start, 'MM') AS month,
    order_count,
    total_boxes,
    total_weight,
    CASE
        WHEN prev_weight IS NULL
            THEN '+100%'
        WHEN prev_weight = 0
            THEN 'N/A'
        ELSE
            CASE
                WHEN (total_weight - prev_weight) >= 0
                THEN '+' || ROUND((total_weight - prev_weight) * 100.0 / prev_weight, 2)::TEXT || '%'
                ELSE ROUND((total_weight - prev_weight) * 100.0 / prev_weight, 2)::TEXT || '%'
            END
    END AS weight_change_pct,
    c.client_name AS top_client
FROM monthly_with_lag mwl
JOIN Client c ON c.client_id = mwl.top_client_id
ORDER BY month_start;
WITH item_counts AS (
    SELECT order_id, SUM(count) AS cnt
    FROM OrderItem
    GROUP BY order_id
),
order_weights AS (
    SELECT oi.order_id, SUM(p.weight * oi.count) AS total_w
    FROM OrderItem oi
    JOIN Product p ON p.article = oi.article
    GROUP BY oi.order_id
),
popular_dest AS (
    SELECT
        o.client_id,
        mode() WITHIN GROUP (ORDER BY oi.dest_id) AS pop_dest_id
    FROM "Order" o
    JOIN OrderItem oi ON oi.order_id = o.order_id
    GROUP BY o.client_id
)
SELECT
    c.client_id,
    c.client_name,
    c.bus_address,
    c.phone,
    c.representative,

    COUNT(o.order_id) AS total_orders,

    COUNT(o.order_id) FILTER (
        WHERE o.created >= date_trunc('month', CURRENT_TIMESTAMP)
    ) AS orders_last_month,

    ROUND(AVG(ic.cnt), 2) AS avg_boxes_per_order,
    ROUND(AVG(ow.total_w), 2) AS avg_weight_per_order,

    COUNT(DISTINCT oi.dest_id) AS unique_destinations,

    d.dest_name AS popular_destination,

    CURRENT_DATE - MAX(o.created)::DATE AS days_since_last_order,

    CASE
        WHEN EXISTS (
            SELECT 1
            FROM "Order" o2
            JOIN OrderItem oi2 ON oi2.order_id = o2.order_id
            LEFT JOIN WaybillLine wl ON wl.item_id = oi2.item_id
            WHERE o2.client_id = c.client_id
              	AND (wl.delivered IS NULL OR wl.delivered <> 'Y')
        ) THEN 'есть'
        ELSE 'нет'
    end AS has_undelivered

FROM Client c
LEFT JOIN "Order" o ON o.client_id = c.client_id
LEFT JOIN OrderItem oi ON oi.order_id = o.order_id
LEFT JOIN item_counts ic ON ic.order_id = o.order_id
LEFT JOIN order_weights ow ON ow.order_id = o.order_id
LEFT JOIN popular_dest pd ON pd.client_id = c.client_id
LEFT JOIN Destination d ON d.dest_id = pd.pop_dest_id

GROUP BY
    c.client_id, c.client_name, c.bus_address,
    c.phone, c.representative,
    d.dest_name

ORDER BY total_orders DESC;
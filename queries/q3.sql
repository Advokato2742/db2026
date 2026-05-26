SELECT
    d.dest_name AS destination_name,
    SUM(oi.count) FILTER (WHERE wl.delivered = 'Y') AS total_delivered_boxes,
    MAX(wb.delivery_day) FILTER (WHERE wl.delivered = 'Y') AS last_delivery_date,
    COUNT(DISTINCT o.client_id) AS unique_clients

FROM Destination d
LEFT JOIN OrderItem oi ON oi.dest_id = d.dest_id
LEFT JOIN "Order" o ON o.order_id = oi.order_id
LEFT JOIN WaybillLine wl ON wl.item_id = oi.item_id
LEFT JOIN Waybill wb ON wb.waybill_id = wl.waybill_id

GROUP BY d.dest_id, d.dest_name
ORDER BY total_delivered_boxes DESC NULLS LAST;
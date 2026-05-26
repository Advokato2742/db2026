WITH completed_waybills AS (
    SELECT wb.waybill_id, wb.vehicle_id, wb.delivery_day
    FROM Waybill wb
    JOIN WaybillLine wl ON wl.waybill_id = wb.waybill_id
    GROUP BY wb.waybill_id, wb.vehicle_id, wb.delivery_day
    HAVING COUNT(*) = SUM(CASE WHEN wl.delivered = 'Y' THEN 1 ELSE 0 END)
),
vehicle_stats AS (
    -- короба, вес, самый частый пункт
    SELECT
        cw.vehicle_id,
        SUM(oi.count) AS total_boxes,
        SUM(oi.count * p.weight) AS total_weight_kg,
        mode() WITHIN GROUP (ORDER BY oi.dest_id) AS top_dest_id
    FROM completed_waybills cw
    JOIN WaybillLine wl ON wl.waybill_id = cw.waybill_id
    JOIN OrderItem oi ON oi.item_id = wl.item_id
    JOIN Product p ON p.article = oi.article
    GROUP BY cw.vehicle_id
),
vehicle_orders AS (
    -- уникальные заказы на ТС: стоимость и дата
    SELECT
        cw.vehicle_id,
        o.order_id,
        o.cost,
        o.created
    FROM completed_waybills cw
    JOIN WaybillLine wl ON wl.waybill_id = cw.waybill_id
    JOIN OrderItem oi ON oi.item_id = wl.item_id
    JOIN "Order" o ON o.order_id = oi.order_id
    GROUP BY cw.vehicle_id, o.order_id, o.cost, o.created
),
vehicle_order_agg AS (
    SELECT
        vehicle_id,
        SUM(cost) AS total_orders_cost,
        MAX(created)::DATE AS last_order_date
    FROM vehicle_orders
    GROUP BY vehicle_id
),
vehicle_waybill_count AS (
    SELECT vehicle_id, COUNT(*) AS completed_waybills_count
    FROM completed_waybills
    GROUP BY vehicle_id
)
SELECT
    v.vehicle_id,
    v.brand,
    vc.cat_name AS vehicle_category,
    vc.carrying AS carrying_kg,
    v.acquired,
    v.service_date,

    wc.completed_waybills_count,
    vs.total_boxes,
    vs.total_weight_kg,
    d.dest_name AS top_destination,
    oa.last_order_date,
    oa.total_orders_cost

FROM Vehicle v
JOIN VehicleCat vc ON vc.cat_id = v.cat_id
JOIN vehicle_stats vs ON vs.vehicle_id = v.vehicle_id
JOIN vehicle_order_agg oa ON oa.vehicle_id = v.vehicle_id
JOIN vehicle_waybill_count wc ON wc.vehicle_id = v.vehicle_id
JOIN Destination d  ON d.dest_id = vs.top_dest_id

ORDER BY wc.completed_waybills_count DESC;
SELECT
    wb.waybill_id,
    wb.delivery_day,

    v.vehicle_id,
    v.brand,
    vc.cat_name AS vehicle_category,
    vc.carrying AS carrying_capacity_kg,
    v.service_date AS next_service_date,

    COUNT(wl.line_id) AS total_lines,

    ROUND(SUM(case WHEN wl.delivered = 'Y' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(wl.line_id), 2
    ) AS done_pct

FROM Waybill wb
JOIN Vehicle v ON v.vehicle_id = wb.vehicle_id
JOIN VehicleCat vc ON vc.cat_id = v.cat_id
JOIN WaybillLine wl ON wl.waybill_id = wb.waybill_id
JOIN Worker w ON w.worker_id = wb.driver_id

GROUP BY
    wb.waybill_id,
    wb.delivery_day,
    v.vehicle_id,
    v.brand,
    v.service_date,
    vc.cat_name,
    vc.carrying

HAVING
    SUM(CASE WHEN wl.delivered = 'Y' THEN 1 ELSE 0 END) > 0
    AND SUM(CASE WHEN wl.delivered = 'Y' THEN 1 ELSE 0 END) < COUNT(wl.line_id)

ORDER BY wb.delivery_day, wb.waybill_id;
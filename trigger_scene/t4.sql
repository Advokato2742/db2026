--- v003 грузоподъемность 3000 кг
--- A017 = вода питьевая 5л = 5 кг => кол-во 200 = 1000 кг
DO $$
DECLARE
    v_waybill_id INTEGER;
    v_item_id INTEGER;
	v_order_id INTEGER;
BEGIN
	insert into "Order" (operator_id, pay_order_id, created, delivery_date, cost, client_id)
	values (1, NULL,  '2026-06-01', '2026-07-01', 100, 1)
    returning order_id into v_order_id;
    INSERT INTO Waybill (waybill_id, vehicle_id, dispatcher_id, driver_id, forwarder_id, delivery_day)
    VALUES (20,'V003', 2, 6, 8, '2026-06-01')
    RETURNING waybill_id INTO v_waybill_id;

    INSERT INTO OrderItem (order_id, article, dest_id, count, delivery_date)
    VALUES (v_order_id, 'A017', 1, 200, '2026-06-01')
    RETURNING item_id INTO v_item_id;

    INSERT INTO WaybillLine (waybill_id, item_id, delivered)
    VALUES (v_waybill_id, v_item_id, 'N');
	raise notice 'inserted 1';

    INSERT INTO WaybillLine (waybill_id, item_id, delivered)
    VALUES (v_waybill_id, v_item_id, 'N');
	raise notice 'inserted 1';

    INSERT INTO WaybillLine (waybill_id, item_id, delivered)
    VALUES (v_waybill_id, v_item_id, 'N');
	raise notice 'inserted 1';

    INSERT INTO WaybillLine (waybill_id, item_id, delivered)
    VALUES (v_waybill_id, v_item_id, 'N');
	raise notice 'inserted 1';
END;
$$;
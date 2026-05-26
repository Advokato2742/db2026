--- тест 2
--- проверка триггера 2 на добавление коробов в заказ

--- пройдет
DO $$
DECLARE
    v_item_id INTEGER;
BEGIN
    --- Заказ 1 не оплачен
    INSERT INTO OrderItem (order_id, article, dest_id, count, delivery_date)
    VALUES (1, 'A004', 1, 5, '2026-06-10')
    RETURNING item_id INTO v_item_id;
	RAISE NOTICE 'Добавлена строка заказа 1';
END;
$$;


--- не пройдет
DO $$
DECLARE
	v_pay_id INTEGER;
BEGIN
	INSERT INTO PaymentOrder (paid, accountant_id, order_cost)
	VALUES (NOW(), 3, 21500)
	RETURNING pay_order_id INTO v_pay_id;

	UPDATE "Order"
	SET pay_order_id = v_pay_id
	WHERE order_id = 1;
	RAISE NOTICE 'Заказ 1 оплачен';
END;
$$;

DO $$
DECLARE
    v_item_id INTEGER;
BEGIN
    --- заказ 1 уже оплачен
    INSERT INTO OrderItem (order_id, article, dest_id, count, delivery_date)
    VALUES (1, 'A005', 1, 5, '2026-06-10')
    RETURNING item_id INTO v_item_id;
END;
$$;
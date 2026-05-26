--- создание заказа
--- проверка процедуры 2 на создание заказа
/*    p_operator_id INTEGER,
    p_client_id INTEGER,
    p_delivery_date TIMESTAMP,
    p_items order_item_input[]*/
DO $$
BEGIN
    CALL place_order(1, 2, '2026-06-10 10:00:00',
        ARRAY[
            ROW('A017', 200, 1)::order_item_input,
            ROW('A006', 20, 1)::order_item_input,
            ROW('B001', 5, 2)::order_item_input
        ]
    );
END;
$$;

--- тест процедуры на создание путевых листов
--- подготовка
DO $$
BEGIN
    CALL place_order(1, 5, '2026-06-10 10:00:00',
        ARRAY[
            ROW('A017', 1600, 1)::order_item_input,
            ROW('A006', 20, 1)::order_item_input,
            ROW('B001', 5, 2)::order_item_input
        ]
    );
END;
$$;

--- процедура
DO $$
BEGIN
    CALL create_waybills_for_orders(
        ARRAY[1, 2], 2, 6, 8
    );
END;
$$;

--- trigger1
CREATE OR REPLACE FUNCTION check_vehicle_capacity()
RETURNS TRIGGER AS $trg_check_vehicle_capacity$
DECLARE
    v_vehicle_id VARCHAR;
    v_carrying NUMERIC;
    v_current_weight NUMERIC;
    v_new_item_weight NUMERIC;
    v_excess NUMERIC;
BEGIN
    SELECT vehicle_id INTO v_vehicle_id
    FROM waybill
    WHERE waybill_id = NEW.waybill_id;

    --- грузоподъёмность в граммах
    SELECT vc.carrying * 1000 INTO v_carrying
    FROM vehicle v
    JOIN vehiclecat vc ON v.cat_id = vc.cat_id
    WHERE v.vehicle_id = v_vehicle_id;

    -- текущий вес
    SELECT COALESCE(SUM(p.weight * oi.count), 0) INTO v_current_weight
    FROM waybillline wl
    JOIN orderitem oi ON wl.item_id = oi.item_id
    JOIN product p ON oi.article = p.article
    WHERE wl.waybill_id = NEW.waybill_id
        AND wl.line_id IS DISTINCT FROM NEW.line_id;

    --- добавляем
    SELECT p.weight * oi.count INTO v_new_item_weight
    FROM orderitem oi
    JOIN product p ON oi.article = p.article
    WHERE oi.item_id = NEW.item_id;

    IF (v_current_weight + v_new_item_weight) > v_carrying THEN
        v_excess := (v_current_weight + v_new_item_weight) - v_carrying;
        RAISE EXCEPTION
            'Превышена грузоподъёмность ТС (%)! '
            'Текущая нагрузка: % г, добавляемый вес: % г, '
            'грузоподъёмность: % г. Превышение: % г.',
            v_vehicle_id,
            v_current_weight,
            v_new_item_weight,
            v_carrying,
            v_excess;
    END IF;
    RETURN NEW;
END;
$trg_check_vehicle_capacity$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_check_vehicle_capacity
    BEFORE INSERT OR UPDATE ON waybillline
    FOR EACH ROW
    EXECUTE FUNCTION check_vehicle_capacity();
---
---
----
---
---
----
---
---
----
---
---
----

--- trigger2
CREATE OR REPLACE FUNCTION prevent_changes_on_paid_order()
RETURNS TRIGGER AS $trg_prevent_paid_order_changes$
DECLARE
    v_order_id INTEGER;
    v_pay_order_id INTEGER;
BEGIN
    IF TG_OP = 'DELETE' THEN
        v_order_id := OLD.order_id;
    ELSE
        v_order_id := NEW.order_id;
    END IF;

    SELECT o.pay_order_id INTO v_pay_order_id
    FROM "Order" o
    WHERE o.order_id = v_order_id
        AND o.pay_order_id IS NOT NULL;

    IF v_pay_order_id IS NOT NULL THEN
        RAISE EXCEPTION
            'Заказ № % уже оплачен (платёжный документ № %). '
            'Изменение, добавление и удаление коробов запрещено.',
            v_order_id,
            v_pay_order_id;
    END IF;

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    END IF;
    RETURN NEW;
END;
$trg_prevent_paid_order_changes$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_prevent_paid_order_changes
    BEFORE INSERT OR UPDATE OR DELETE ON OrderItem
    FOR EACH ROW
    EXECUTE FUNCTION prevent_changes_on_paid_order();
---
---
----
---
---
----
---
---
----
---
---
----
--- proc1
CREATE OR REPLACE PROCEDURE create_waybills_for_orders(
    p_order_ids INTEGER[],
    p_dispatcher_id INTEGER,
    p_driver_id INTEGER,
    p_forwarder_id INTEGER
)
LANGUAGE plpgsql AS $$
DECLARE
    v_vehicle_id VARCHAR(10);
    v_carrying NUMERIC;
    v_current_day DATE := CURRENT_DATE;
    v_waybill_id INTEGER;
    v_load NUMERIC := 0;
    v_item_weight NUMERIC;
    rec RECORD;
BEGIN
    SELECT v.vehicle_id, vc.carrying * 1000 INTO v_vehicle_id, v_carrying
    FROM vehicle v
    JOIN vehicleCat vc ON v.cat_id = vc.cat_id
    WHERE v.vehicle_id NOT IN (
        SELECT vehicle_id FROM Waybill WHERE delivery_day = CURRENT_DATE
    )
    ORDER  BY vc.carrying DESC
    LIMIT  1;

    IF v_vehicle_id IS NULL THEN
        RAISE EXCEPTION 'Нет свободных ТС на сегодня (%)!', CURRENT_DATE;
    END IF;

    FOR rec IN
        SELECT oi.item_id,
               oi.order_id,
               p.weight * oi.count AS item_weight
        FROM OrderItem oi
        JOIN Product p ON oi.article = p.article
        WHERE oi.order_id = ANY(p_order_ids)
        ORDER BY oi.order_id, oi.item_id
    LOOP
        v_item_weight := rec.item_weight;

        IF v_item_weight > v_carrying THEN
            RAISE EXCEPTION
                'Короб (item_id=%, заказ %) весит % г и превышает '
                'грузоподъёмность ТС % г.',
                rec.item_id,
                rec.order_id,
                v_item_weight,
                v_carrying;
        END IF;

        --- когда попес в штаны не влез
        IF v_waybill_id IS NULL OR (v_load + v_item_weight) > v_carrying THEN
            IF v_waybill_id IS NOT NULL THEN
                v_current_day := v_current_day + 1;
                WHILE EXISTS (
                    SELECT 1 FROM Waybill
                    WHERE vehicle_id = v_vehicle_id
                      AND delivery_day = v_current_day
                ) LOOP
                    v_current_day := v_current_day + 1;
                END LOOP;
            END IF;

            INSERT INTO Waybill (vehicle_id, dispatcher_id, driver_id, forwarder_id, delivery_day)
            VALUES (v_vehicle_id, p_dispatcher_id, p_driver_id, p_forwarder_id, v_current_day)
            RETURNING waybill_id INTO v_waybill_id;
            v_load := 0;
        END IF;

        INSERT INTO WaybillLine (waybill_id, item_id, delivered)
        VALUES (v_waybill_id, rec.item_id, 'N');

        v_load := v_load + v_item_weight;
    END LOOP;
END;
$$;
---
---
----
---
---
----
---
---
----
---
---
----
--- proc2
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'order_item_input') THEN
        CREATE TYPE order_item_input AS (
            article VARCHAR(10),
            qty INTEGER,
            dest_id INTEGER
        );
    END IF;
END;
$$;

CREATE OR REPLACE PROCEDURE place_order(
    p_operator_id INTEGER,
    p_client_id INTEGER,
    p_delivery_date TIMESTAMP,
    p_items order_item_input[]
)
LANGUAGE plpgsql AS $$
DECLARE
    MAX_BOX_WEIGHT CONSTANT NUMERIC := 40000;
    v_order_id INTEGER;
    v_total_cost NUMERIC := 0;
    v_prod_weight NUMERIC;
    v_prod_cost NUMERIC;
    v_remaining INTEGER;
    v_can_fit INTEGER;
    v_line order_item_input;
BEGIN
    --- создать заказ
    INSERT INTO "Order" (operator_id, pay_order_id, created, delivery_date, cost, client_id)
    VALUES (p_operator_id, NULL, NOW(), p_delivery_date, 1, p_client_id)
    RETURNING order_id INTO v_order_id;

    --- для каждой позиции создать item
    FOR v_line IN
        SELECT * FROM UNNEST(p_items)
    LOOP
        SELECT weight, cost INTO v_prod_weight, v_prod_cost
        FROM Product WHERE article = v_line.article;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Артикул % не найден!', v_line.article;
        END IF;

        IF v_prod_weight > MAX_BOX_WEIGHT THEN
            RAISE EXCEPTION
                'Вес единицы товара % (% г) превышает максимальный вес короба (% г)!',
                v_line.article, v_prod_weight, MAX_BOX_WEIGHT;
        END IF;

        v_remaining := v_line.qty;
        WHILE v_remaining > 0 LOOP
            --- сколько влезет в один короб
            v_can_fit := LEAST(
                FLOOR(MAX_BOX_WEIGHT / v_prod_weight)::INTEGER,
                v_remaining
            );

            INSERT INTO OrderItem (order_id, article, dest_id, count, delivery_date)
            VALUES (v_order_id, v_line.article, v_line.dest_id, v_can_fit, p_delivery_date);

            v_total_cost := v_total_cost + v_prod_cost * v_can_fit;
            v_remaining  := v_remaining - v_can_fit;
        END LOOP;
    END LOOP;

    --- добавить реальную стоимость
    UPDATE "Order" SET cost = v_total_cost WHERE order_id = v_order_id;
    RAISE NOTICE 'Заказ № % создан. Сумма: % руб.', v_order_id, v_total_cost;
END;
$$;
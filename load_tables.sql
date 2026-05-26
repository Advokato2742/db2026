COPY Client (client_id, client_name, bus_address, phone, license, representative)
FROM '/var/lib/postgres/import/Client.txt'
WITH (
    FORMAT csv,
    HEADER true,
    DELIMITER ';',
    ENCODING 'UTF8'
);

COPY Product (article, product_name, package, manufactorer, weight, height, width, cost)
FROM '/var/lib/postgres/import/Product.txt'
WITH (
    FORMAT csv,
    HEADER true,
    DELIMITER ';',
    ENCODING 'UTF8'
);

COPY Destination (dest_id, dest_name, address)
FROM '/var/lib/postgres/import/Destination.txt'
WITH (
    FORMAT csv,
    HEADER true,
    DELIMITER ';',
    ENCODING 'UTF8'
);

COPY JobTitle (job_id, job_name)
FROM '/var/lib/postgres/import/JobTitle.txt'
WITH (
    FORMAT csv,
    HEADER true,
    DELIMITER ';',
    ENCODING 'UTF8'
);

COPY Worker (worker_id, job_id, name, pass_series, pass_num, address, phone, accepted)
FROM '/var/lib/postgres/import/Worker.txt'
WITH (
    FORMAT csv,
    HEADER true,
    DELIMITER ';',
    ENCODING 'UTF8'
);

COPY PaymentOrder (pay_order_id, paid, accountant_id, order_cost)
FROM '/var/lib/postgres/import/PaymentOrder.txt'
WITH (
    FORMAT csv,
    HEADER true,
    DELIMITER ';',
    ENCODING 'UTF8'
);

COPY "Order" (order_id, operator_id, pay_order_id, created, delivery_date, cost, client_id)
FROM '/var/lib/postgres/import/Order.txt'
WITH (
    FORMAT csv,
    HEADER true,
    DELIMITER ';',
    ENCODING 'UTF8'
);

COPY OrderItem (item_id, order_id, article, dest_id, count, delivery_date)
FROM '/var/lib/postgres/import/OrderItem.txt'
WITH (
    FORMAT csv,
    HEADER true,
    DELIMITER ';',
    ENCODING 'UTF8'
);

COPY VehicleCat (cat_id, cat_name, carrying, cell_height, cell_width, cell_length, cell_num)
FROM '/var/lib/postgres/import/VehicleCat.txt'
WITH (
    FORMAT csv,
    HEADER true,
    DELIMITER ';',
    ENCODING 'UTF8'
);

COPY Vehicle (vehicle_id, acquired, service_date, brand, cat_id)
FROM '/var/lib/postgres/import/Vehicle.txt'
WITH (
    FORMAT csv,
    HEADER true,
    DELIMITER ';',
    ENCODING 'UTF8'
);

COPY Waybill (waybill_id, vehicle_id, dispatcher_id, driver_id, forwarder_id, delivery_day)
FROM '/var/lib/postgres/import/Waybill.txt'
WITH (
    FORMAT csv,
    HEADER true,
    DELIMITER ';',
    ENCODING 'UTF8'
);

COPY WaybillLine (line_id, waybill_id, item_id, delivered)
FROM '/var/lib/postgres/import/WaybillLine.txt'
WITH (
    FORMAT csv,
    HEADER true,
    DELIMITER ';',
    ENCODING 'UTF8'
);
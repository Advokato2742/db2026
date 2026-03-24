```
create table Client (
    client_id SERIAL PRIMARY KEY,
    client_name VARCHAR(255) UNIQUE,
    bus_address VARCHAR(255) NOT NULL,
    phone VARCHAR(25) NOT NULL,
    license INT NOT NULL CHECK (license > 1),
    representative VARCHAR(255) NOT NULL
);
```

```
create table Product (
    article VARCHAR(10) PRIMARY KEY,
    product_name VARCHAR(255) NOT NULL,
    package VARCHAR(255) NOT NULL,
    manufactorer VARCHAR(255) NOT NULL,
    weight INT CHECK (weight > 0),
    height INT CHECK (height > 0),
    width INT CHECK (width > 0),
    cost INT CHECK (cost > 0)
);
```
```
create table Destination (
    dest_id SERIAL PRIMARY KEY,
    dest_name VARCHAR(255) UNIQUE,
    address VARCHAR(255) NOT NULL,
);
```

```
create table JobTitle (
    job_id SERIAL PRIMARY KEY,
    job_name VARCHAR(255) UNIQUE
);
```

```
create table Worker (
    worker_id SERIAL PRIMARY KEY,
    job_id SERIAL,
    FOREIGN KEY (job_id) REFERENCES JobTitle(job_id) ON DELETE RESTRICT,
    name VARCHAR(255) NOT NULL,
    pass_series INT UNIQUE CHECK (10000 > pass_series and pass_series > 0),
    pass_num INT UNIQUE CHECK (10000 > pass_num and pass_num > 0),
    address VARCHAR(255) NOT NULL,
    phone VARCHAR(25) NOT NULL,
    accepted DATE NOT NULL 
);
```

```
create table PaymentOrder (
    pay_order_id SERIAL PRIMARY KEY,
    paid DATETIME,                               ##СРАЗУ ОПЛАЧИВАЕМ ИЛИ КАК???
    accountant_id SERIAL NOT NULL,
    FOREIGN KEY (accountant_id) REFERENCES Worker(worker_id) ON DELETE RESTRICT,
    order_cost INT CHECK (order_cost > 0)
);
```

```
create table Order (
    order_id SERIAL PRIMARY KEY,
    operator_id SERIAL NOT NULL,
    FOREIGN KEY (operator_id) REFERENCES Worker(worker_id) ON DELETE RESTRICT,
    created DATETIME NOT NULL,
    delivery_date DATETIME NOT NULL,
    cost INT CHECK (cost > 0)
);
```

```
create table OrderItem (
    item_id SERIAL PRIMARY KEY,
    order_id SERIAL NOT NULL,
    FOREIGN KEY (order_id) REFERENCES Order(order_id) ON DELETE CASCADE,
    article VARCHAR(10) NOT NULL,
    FOREIGN KEY (article) REFERENCES Product(article) ON DELETE RESTRICT,
    dest_id SERIAL NOT NULL,
    FOREIGN KEY (dest_id) REFERENCES Destination(dest_id) ON DELETE RESTRICT,
    count INT NOT NULL CHECH (count > 0),
    delivery_date DATETIME NOT NULL
);
```

```
create table VehicleCat (
    cat_id VARCHAR(1) PRIMARY KEY,
    cat_name VARCHAR(50) UNIQUE,
    carrying INT CHECK (carrying > 0),
    cell_height INT CHECK (cell_height > 0),
    cell_width INT CHECK (cell_width > 0),
    cell_length INT CHECK (cell_length > 0),
    cell_num INT CHECK (cell_num > 0),
);
```

```
create table Vehicle (
    vehicle_id VARCHAR(10) PRIMARY KEY,
    acquired DATE NOT NULL,
    service_date DATE NOT NULL,
    brand VARCHAR(10) NOT NULL,
    cat_id VARCHAR(1) NOT NULL,
    FOREIGN KEY (cat_id) REFERENCES VehicleCat(cat_id) ON DELETE RESTRICT
);
```

```
create table Waybill (
    waybill_id SERIAL PRIMIARY KEY,
    vehicle_id VARCHAR(10) NOT NULL,
    FOREIGN KEY (vehicle_id) REFERENCES Vehicle(vehicle_id) ON DELETE RESTRICT,
    dispatcher_id SERIAL NOT NULL,
    driver_id SERIAL NOT NULL,
    forwarder_id SERIAL NOT NULL,
    FOREIGN KEY (dispatcher_id, driver_id, forwarder_id) Worker(worker_id) REFERENCES ON DELETE RESTRICT,
    delivery_day DATE NOT NULL
);
```

```
create table WaybillLine(
    line_id SERIAL PRIMARY KEY,
    waybill_id SERIAL NOT NULL,
    FOREIGN KEY (waybill_id) REFERENCES Waybill(waybill_id) ON DELETE CASCADE,
    item_id SERIAL NOT NULL,
    FOREIGN KEY (item_id) REFERENCES OrderItem(item_id) ON DELETE CASCADE,
    delivered VARCHAR(1) NOT NULL
);
```
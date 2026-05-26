# зайти под пользователем
sudo mkdir /run/postgresql && sudo chown postgres: /run/postgresql && sudo -iu postgres

# скопировать таблицы в папку
sudo cp ~/db2026/tables/*.txt /var/lib/postgres/import/

# запустить сервер
pg_ctl -D /var/lib/postgres/data -l /var/lib/postgres/logfile start

# остановить сервер
pg_ctl -D /var/lib/postgres/data stop
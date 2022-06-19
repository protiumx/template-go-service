FROM migrate/migrate:v4.15.2

COPY /migrations /migrations

CMD migrate -path /migrations -database $DB_SOURCE up

-- name: AddUser :one
INSERT INTO
  users (id, user_name, password_hash)
VALUES
  ($1, $2, $3) RETURNING *;

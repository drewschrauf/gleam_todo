UPDATE tasks SET description = $2, done = $3 WHERE id = $1 RETURNING *

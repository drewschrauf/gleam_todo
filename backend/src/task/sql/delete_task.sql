DELETE FROM tasks WHERE tasks.id = $1 RETURNING *

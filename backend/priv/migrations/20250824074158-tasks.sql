--- migration:up
CREATE TABLE tasks (
	id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  description TEXT NOT NULL,
	done boolean NOT NULL DEFAULT false,
  created_at TIMESTAMP NOT NULL DEFAULT now()
);

--- migration:down
DROP TABLE tasks;

--- migration:end

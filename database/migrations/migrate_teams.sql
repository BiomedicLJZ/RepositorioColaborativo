BEGIN;

INSERT INTO users (email, username, password_hash, team_origin)
SELECT 
    email,
    'team_a_' || username,
    password_hash,
    'team_a'
FROM team_a_legacy_users
WHERE NOT EXISTS (
    SELECT 1 FROM users WHERE users.email = team_a_legacy_users.email
);

INSERT INTO users (email, username, password_hash, team_origin)
SELECT 
    email,
    'team_b_' || username,
    password_hash,
    'team_b'
FROM team_b_legacy_users
WHERE NOT EXISTS (
    SELECT 1 FROM users WHERE users.email = team_b_legacy_users.email
);

INSERT INTO migration_log (table_name, operation, team_source, records_affected, status)
VALUES 
    ('users', 'migration', 'team_a', 
     (SELECT COUNT(*) FROM users WHERE team_origin = 'team_a'), 'completed'),
    ('users', 'migration', 'team_b', 
     (SELECT COUNT(*) FROM users WHERE team_origin = 'team_b'), 'completed');

COMMIT;

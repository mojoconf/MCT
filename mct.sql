-- 1 up
CREATE TABLE conferences (
  id SERIAL PRIMARY KEY,
  identifier TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  tagline TEXT,
  analytics_code TEXT,
  created TIMESTAMP,
  start_date DATE,
  end_date DATE
);
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  registered TIMESTAMP,
  name TEXT NOT NULL,
  username TEXT NOT NULL UNIQUE,
  email TEXT
);
CREATE TABLE user_identities (
  id SERIAL PRIMARY KEY,
  id_user INTEGER NOT NULL REFERENCES users (id),
  identity_provider TEXT NOT NULL,
  identity_uid TEXT NOT NULL,
  identity_token TEXT,
  UNIQUE (identity_provider, identity_uid)
);
CREATE TABLE presentations (
  id SERIAL PRIMARY KEY,
  conference INTEGER NOT NULL REFERENCES conferences (id),
  author INTEGER NOT NULL REFERENCES users (id),
  url_name TEXT NOT NULL,
  title TEXT NOT NULL,
  subtitle TEXT,
  abstract TEXT,
  UNIQUE (url_name, conference)
);
-- 2 up
ALTER TABLE conferences ADD COLUMN address TEXT NOT NULL DEFAULT '';
ALTER TABLE conferences ADD COLUMN city TEXT NOT NULL DEFAULT '';
ALTER TABLE conferences ADD COLUMN country VARCHAR(2) NOT NULL DEFAULT '';
ALTER TABLE conferences ADD COLUMN domain TEXT NOT NULL DEFAULT '';
ALTER TABLE conferences ADD COLUMN location TEXT NOT NULL DEFAULT '';
ALTER TABLE conferences ADD COLUMN tags TEXT NOT NULL DEFAULT '';
ALTER TABLE conferences ADD COLUMN zip TEXT NOT NULL DEFAULT '';
-- 3 up
ALTER TABLE users ADD COLUMN avatar_url TEXT NOT NULL DEFAULT '';
ALTER TABLE users ADD COLUMN city TEXT NOT NULL DEFAULT '';
ALTER TABLE users ADD COLUMN country VARCHAR(2) NOT NULL DEFAULT '';
ALTER TABLE users ADD COLUMN address TEXT NOT NULL DEFAULT '';
ALTER TABLE users ADD COLUMN t_shirt_size TEXT NOT NULL DEFAULT '';
ALTER TABLE users ADD COLUMN web_page TEXT NOT NULL DEFAULT '';
ALTER TABLE users ADD COLUMN zip TEXT NOT NULL DEFAULT '';
-- 1 down
DROP TABLE IF EXISTS presentations;
DROP TABLE IF EXISTS conferences;
DROP TABLE IF EXISTS user_identities;
DROP TABLE IF EXISTS users;
-- 2 down
ALTER TABLE conferences DROP COLUMN address;
ALTER TABLE conferences DROP COLUMN city;
ALTER TABLE conferences DROP COLUMN country;
ALTER TABLE conferences DROP COLUMN domain;
ALTER TABLE conferences DROP COLUMN location;
ALTER TABLE conferences DROP COLUMN tags;
ALTER TABLE conferences DROP COLUMN zip;
-- 3 down
ALTER TABLE users DROP COLUMN IF EXISTS zip;
ALTER TABLE users DROP COLUMN IF EXISTS web_page;
ALTER TABLE users DROP COLUMN IF EXISTS t_shirt_size;
ALTER TABLE users DROP COLUMN IF EXISTS country;
ALTER TABLE users DROP COLUMN IF EXISTS city;
ALTER TABLE users DROP COLUMN IF EXISTS avatar_url;
ALTER TABLE users DROP COLUMN IF EXISTS address;

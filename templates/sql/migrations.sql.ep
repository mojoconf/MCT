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

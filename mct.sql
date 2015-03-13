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
ALTER TABLE users ADD COLUMN avatar_url TEXT NOT NULL DEFAULT '';
ALTER TABLE users ADD COLUMN city TEXT NOT NULL DEFAULT '';
ALTER TABLE users ADD COLUMN country VARCHAR(2) NOT NULL DEFAULT '';
ALTER TABLE users ADD COLUMN address TEXT NOT NULL DEFAULT '';
ALTER TABLE users ADD COLUMN t_shirt_size TEXT NOT NULL DEFAULT '';
ALTER TABLE users ADD COLUMN web_page TEXT NOT NULL DEFAULT '';
ALTER TABLE users ADD COLUMN zip TEXT NOT NULL DEFAULT '';
ALTER TABLE presentations DROP COLUMN subtitle;
-- 3 up
ALTER TABLE presentations RENAME COLUMN conference TO conference_id;
ALTER TABLE presentations RENAME COLUMN author TO user_id;
ALTER TABLE presentations ADD COLUMN duration INTEGER DEFAULT 20;
ALTER TABLE presentations ADD COLUMN status VARCHAR(16) DEFAULT 'waiting'; -- waiting,accepted,rejected,confirmed
CREATE TABLE user_conferences (
  user_id INTEGER REFERENCES users (id) ON UPDATE CASCADE,
  conference_id INTEGER REFERENCES conferences (id) ON UPDATE CASCADE,
  admin BOOLEAN DEFAULT FALSE,
  going BOOLEAN DEFAULT FALSE,
  payed REAL DEFAULT 0,
  CONSTRAINT user_conferences_pkey PRIMARY KEY (user_id, conference_id)
);
-- 4 up
CREATE TABLE conference_products (
  id SERIAL PRIMARY KEY,
  conference_id INTEGER REFERENCES conferences (id) ON UPDATE CASCADE,
  name TEXT NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  price REAL NOT NULL,
  currency VARCHAR(3) NOT NULL DEFAULT 'USD',
  n_of INTEGER NOT NULL DEFAULT -1, -- max number, -1 = infinite
  available_from TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  available_to TIMESTAMP NOT NULL DEFAULT '2099-12-31 23:59:59'
);
CREATE TABLE user_products (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users (id),
  product_id INTEGER REFERENCES conference_products (id),
  external_link TEXT,
  price REAL NOT NULL, -- conference_products.price may change
  currency VARCHAR(3) NOT NULL DEFAULT 'USD',
  paid TIMESTAMP
);
ALTER TABLE users ADD COLUMN bio TEXT NOT NULL DEFAULT '';
ALTER TABLE users ADD CONSTRAINT users_email_key UNIQUE (email);
ALTER TABLE user_conferences DROP COLUMN payed;
-- 5 up
ALTER TABLE user_products ADD COLUMN status TEXT NOT NULL DEFAULT '';
ALTER TABLE user_products ALTER COLUMN price TYPE INTEGER;
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
ALTER TABLE users DROP COLUMN IF EXISTS zip;
ALTER TABLE users DROP COLUMN IF EXISTS web_page;
ALTER TABLE users DROP COLUMN IF EXISTS t_shirt_size;
ALTER TABLE users DROP COLUMN IF EXISTS country;
ALTER TABLE users DROP COLUMN IF EXISTS city;
ALTER TABLE users DROP COLUMN IF EXISTS avatar_url;
ALTER TABLE users DROP COLUMN IF EXISTS address;
ALTER TABLE presentations ADD COLUMN subtitle TEXT;
-- 3 down
ALTER TABLE presentations DROP COLUMN status;
ALTER TABLE presentations DROP COLUMN duration;
ALTER TABLE presentations RENAME COLUMN conference_id TO conference;
ALTER TABLE presentations RENAME COLUMN user_id TO author;
DROP TABLE IF EXISTS user_conferences;
-- 4 down
ALTER TABLE user_conferences ADD COLUMN payed REAL DEFAULT 0;
DROP TABLE IF EXISTS user_products;
DROP TABLE IF EXISTS conference_products;
-- 5 down
ALTER TABLE user_products DROP COLUMN status;

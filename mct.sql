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
CREATE TABLE user_conferences (id SERIAL); -- just so we have something to drop later on
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
-- 5 up
ALTER TABLE user_products ADD COLUMN status TEXT NOT NULL DEFAULT '';
ALTER TABLE user_products ALTER COLUMN price TYPE INTEGER;
-- 6 up
CREATE TABLE user_roles (
  user_id INTEGER NOT NULL REFERENCES users (id) ON UPDATE CASCADE,
  conference_id INTEGER REFERENCES conferences (id) ON UPDATE CASCADE,
  role TEXT NOT NULL,
  created TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id, conference_id, role)
);
DROP TABLE IF EXISTS user_conferences; -- replaced by user_roles
-- 7 up
CREATE TABLE locations (
  id            SERIAL PRIMARY KEY,
  conference_id INTEGER REFERENCES conferences (id),
  name          TEXT NOT NULL,
  location      TEXT NOT NULL DEFAULT '',
  latitude      REAL,
  longitude     REAL,
  UNIQUE (conference_id, name)
);
CREATE TABLE events (
  id            SERIAL               PRIMARY KEY,
  conference_id INTEGER     NOT NULL REFERENCES conferences (id),
  user_id       INTEGER     NOT NULL REFERENCES users       (id),
  location_id   INTEGER              REFERENCES locations   (id),
  type          VARCHAR(16) NOT NULL,
  identifier    TEXT        NOT NULL,                     -- /:cid/events/:identifier
  title         TEXT        NOT NULL,
  description   TEXT        NOT NULL DEFAULT '',
  external_url  TEXT        NOT NULL DEFAULT '',
  sequence      INTEGER              DEFAULT 0,           -- http://www.kanzaki.com/docs/ical/sequence.html
  status        VARCHAR(16) NOT NULL DEFAULT 'TENTATIVE', -- http://www.kanzaki.com/docs/ical/status.html
  start_time    TIMESTAMP,
  duration      INTEGER              DEFAULT 20,
  created       TIMESTAMP            DEFAULT CURRENT_TIMESTAMP,
  last_modified TIMESTAMP            DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (conference_id, identifier)
);
INSERT INTO events (id, conference_id, user_id, title, description, identifier, duration, type)
  SELECT id, conference_id, user_id, title, abstract, url_name, duration, 'talk' FROM presentations;
DROP TABLE IF EXISTS presentations;
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
-- 4 down
DROP TABLE IF EXISTS user_products;
DROP TABLE IF EXISTS conference_products;
-- 5 down
ALTER TABLE user_products DROP COLUMN status;
-- 6 down
DROP TABLE IF EXISTS user_roles;
-- 7 down
CREATE TABLE presentations (
  id SERIAL PRIMARY KEY,
  conference_id INTEGER REFERENCES conferences (id) ON UPDATE CASCADE,
  user_id INTEGER NOT NULL REFERENCES users (id),
  title TEXT NOT NULL,
  abstract TEXT,
  url_name TEXT NOT NULL,
  duration INTEGER DEFAULT 20,
  status VARCHAR(16) DEFAULT 'waiting', -- waiting,accepted,rejected,confirmed
  UNIQUE (url_name, conference_id)
);
INSERT INTO presentations (id, conference_id, user_id, title, abstract, url_name, duration)
  SELECT id, conference_id, user_id, title, description, identifier, duration FROM events;
DROP TABLE IF EXISTS events;
DROP TABLE IF EXISTS locations;

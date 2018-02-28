DROP TABLE IF EXISTS users;

CREATE TABLE users(
  id INTEGER PRIMARY KEY,
  fname TEXT NOT NULL,
  lname TEXT NOT NULL
);


DROP TABLE if exists questions;

CREATE TABLE questions(
  id INTEGER PRIMARY KEY,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  users_id INTEGER NOT NULL,

  FOREIGN KEY (users_id) REFERENCES users(id)
);


DROP TABLE if exists question_follows;

CREATE TABLE question_follows(
  id INTEGER PRIMARY KEY,
  questions_id INTEGER NOT NULL,
  users_id INTEGER NOT NULL,

  FOREIGN KEY (users_id) REFERENCES users(id)
  FOREIGN KEY (questions_id) REFERENCES questions(id)
);

DROP TABLE if exists replies;

CREATE TABLE replies(
  id INTEGER PRIMARY KEY,
  questions_id INTEGER NOT NULL,
  parent_id INTEGER,
  users_id INTEGER NOT NULL,
  body TEXT NOT NULL,

  FOREIGN KEY (users_id) REFERENCES users(id)
  FOREIGN KEY (questions_id) REFERENCES questions(id)
  FOREIGN KEY (parent_id) REFERENCES replies(id)
);

DROP TABLE if exists question_likes;

CREATE TABLE question_likes(
  id INTEGER PRIMARY KEY,
  questions_id INTEGER NOT NULL,
  users_id INTEGER NOT NULL,

  FOREIGN KEY (users_id) REFERENCES users(id)
  FOREIGN KEY (questions_id) REFERENCES questions(id)
);

INSERT INTO
  users (fname, lname)
VALUES
  ('Arthur', 'Miller'),
  ('Eugene', 'O''Neill'),
  ('Best', 'Name');

INSERT INTO
  questions (title, body, users_id)
VALUES
  ('A', 'Body', 1),
  ('B', 'Body', 2),
  ('C', 'Body', 2),
  ('D', 'Body', 1);

INSERT INTO
  question_follows (users_id, questions_id)
VALUES
  (1, 1),
  (2, 2),
  (1, 3),
  (2, 3);

INSERT INTO
  replies (questions_id, parent_id, users_id, body)
VALUES
  (1, NULL, 2, 'Body'),
  (1, 1, 1, 'Body 2'),
  (1, 1, 1, 'Body 3'),
  (1, 3, 2, 'Grandchild');

INSERT INTO
  question_likes (questions_id, users_id)
VALUES
  (1, 1),
  (1, 2),
  (1, 3),
  (2, 1);

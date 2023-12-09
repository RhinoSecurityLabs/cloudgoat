CREATE DATABASE mydatabase;
USE mydatabase;
CREATE TABLE flag (
  id INT AUTO_INCREMENT PRIMARY KEY,
  value VARCHAR(255) NOT NULL
);

INSERT INTO flag(value) VALUES ('cg{test}');

CREATE DATABASE webshop;
CREATE TABLE webshop.orders (
    id         INT AUTO_INCREMENT PRIMARY KEY,
    customer   VARCHAR(100)  NOT NULL,
    total      DECIMAL(10,2) NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO webshop.orders (customer, total) VALUES ('สมชาย', 1290.00), ('สมหญิง', 590.00);
CREATE USER 'webapp'@'192.168.56.20' IDENTIFIED BY 'Web-App-2569' REQUIRE SSL;
GRANT SELECT, INSERT, UPDATE, DELETE ON webshop.* TO 'webapp'@'192.168.56.20';
SHOW GRANTS FOR 'webapp'@'192.168.56.20';

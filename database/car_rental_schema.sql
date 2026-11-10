-- =====================================================
-- Car Rental System - Database Schema
-- =====================================================

DROP DATABASE IF EXISTS car_rental_db;
CREATE DATABASE car_rental_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE car_rental_db;

-- 1. USERS --

CREATE TABLE users (
  user_id        INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name           VARCHAR(100)  NOT NULL,
  email          VARCHAR(150)  NOT NULL UNIQUE,
  password_hash  VARCHAR(255)  NOT NULL,           
  phone          VARCHAR(20)   NOT NULL,
  license_no     VARCHAR(50)   NULL UNIQUE,
  role           ENUM('customer','admin') NOT NULL DEFAULT 'customer',
  created_at     TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at     TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP
                               ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;


-- 2. CARS --

REATE TABLE cars (
  car_id         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  make           VARCHAR(50)   NOT NULL,
  model          VARCHAR(50)   NOT NULL,
  type           ENUM('Sedan','SUV','Hatchback','Van','Pickup','Luxury','Convertible') NOT NULL,
  seats          TINYINT UNSIGNED NOT NULL,
  transmission   ENUM('Manual','Automatic') NOT NULL DEFAULT 'Automatic',
  price_per_day  DECIMAL(10,2) NOT NULL CHECK (price_per_day > 0),
  status         ENUM('available','booked','maintenance') NOT NULL DEFAULT 'available',
  images         JSON          NULL,               -- array of image URLs
  created_at     TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_cars_type_price (type, price_per_day),
  INDEX idx_cars_status (status)
) ENGINE=InnoDB;


-- 3. BOOKINGS --

CREATE TABLE bookings (
  booking_id     INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id        INT UNSIGNED  NOT NULL,
  car_id         INT UNSIGNED  NOT NULL,
  start_date     DATE          NOT NULL,
  end_date       DATE          NOT NULL,
  total_cost     DECIMAL(10,2) NOT NULL,
  status         ENUM('pending','confirmed','active','completed','cancelled')
                 NOT NULL DEFAULT 'pending',
  created_at     TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_booking_user FOREIGN KEY (user_id) REFERENCES users(user_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_booking_car  FOREIGN KEY (car_id)  REFERENCES cars(car_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT chk_dates CHECK (end_date >= start_date),
  INDEX idx_booking_car_dates (car_id, start_date, end_date),
  INDEX idx_booking_user (user_id)
) ENGINE=InnoDB;


-- 4. PAYMENTS (one payment per booking) --

CREATE TABLE payments (
  payment_id     INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  booking_id     INT UNSIGNED  NOT NULL UNIQUE,
  amount         DECIMAL(10,2) NOT NULL,
  method         ENUM('paypal','card','mobile_money') NOT NULL DEFAULT 'paypal',
  transaction_ref VARCHAR(100) NULL,               -- PayPal transaction ID
  status         ENUM('pending','paid','failed','refunded') NOT NULL DEFAULT 'pending',
  payment_date   TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_payment_booking FOREIGN KEY (booking_id) REFERENCES bookings(booking_id)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;


-- 5. REVIEWS --

CREATE TABLE reviews (
  review_id      INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id        INT UNSIGNED  NOT NULL,
  car_id         INT UNSIGNED  NOT NULL,
  rating         TINYINT UNSIGNED NOT NULL,
  comment        TEXT          NULL,
  created_at     TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_review_user FOREIGN KEY (user_id) REFERENCES users(user_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_review_car  FOREIGN KEY (car_id)  REFERENCES cars(car_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT chk_rating CHECK (rating BETWEEN 1 AND 5),
  INDEX idx_review_car (car_id)
) ENGINE=InnoDB;


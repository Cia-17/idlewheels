-- ============================================================
-- idlewheels database schema
-- ============================================================
CREATE DATABASE IF NOT EXISTS carshare CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE carshare;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS notifications, disputes, reviews, payouts, payments, availability,
                     bookings, promotions, car_occasions, car_images, cars, occasions,
                     verifications, users;
SET FOREIGN_KEY_CHECKS = 1;

-- 1. USERS (renters, owners and admins)
CREATE TABLE users (
  user_id             INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  full_name           VARCHAR(100) NOT NULL,
  email               VARCHAR(150) NOT NULL UNIQUE,
  password_hash       VARCHAR(255) NOT NULL,
  phone               VARCHAR(20)  NOT NULL,
  role                ENUM('renter','owner','admin') NOT NULL DEFAULT 'renter',
  license_no          VARCHAR(50)  NULL,
  verification_status ENUM('unverified','pending','verified','rejected') NOT NULL DEFAULT 'unverified',
  profile_image       VARCHAR(255) NULL,
  reset_token         VARCHAR(255) NULL,
  reset_expires       DATETIME     NULL,
  account_status      ENUM('active','suspended') NOT NULL DEFAULT 'active',
  created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- 2. VERIFICATIONS (ID / licence / vehicle documents reviewed by admin)
CREATE TABLE verifications (
  verification_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id         INT UNSIGNED NOT NULL,
  doc_type        ENUM('national_id','drivers_licence','passport','vehicle_registration') NOT NULL,
  doc_number      VARCHAR(50)  NULL,
  file_path       VARCHAR(255) NOT NULL,
  status          ENUM('pending','approved','rejected') NOT NULL DEFAULT 'pending',
  reviewed_by     INT UNSIGNED NULL,
  review_note     VARCHAR(255) NULL,
  submitted_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  reviewed_at     DATETIME NULL,
  FOREIGN KEY (user_id)     REFERENCES users(user_id) ON DELETE CASCADE,
  FOREIGN KEY (reviewed_by) REFERENCES users(user_id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- 3. OCCASIONS (wedding, airport transfer, road trip, ...)
CREATE TABLE occasions (
  occasion_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name        VARCHAR(60) NOT NULL UNIQUE,
  description VARCHAR(255) NULL
) ENGINE=InnoDB;

-- 4. CARS (listed by owners)
CREATE TABLE cars (
  car_id             INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  owner_id           INT UNSIGNED NOT NULL,
  make               VARCHAR(50) NOT NULL,
  model              VARCHAR(50) NOT NULL,
  year               SMALLINT UNSIGNED NOT NULL,
  car_type           VARCHAR(30) NOT NULL,                -- sedan, SUV, minivan, pickup, luxury...
  seats              TINYINT UNSIGNED NOT NULL,
  transmission       ENUM('manual','automatic') NOT NULL,
  fuel_type          ENUM('petrol','diesel','hybrid','electric') NOT NULL,
  plate_no           VARCHAR(20) NOT NULL UNIQUE,
  price_per_day      DECIMAL(10,2) NOT NULL,
  deposit_amount     DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  city               VARCHAR(80) NOT NULL,
  pickup_address     VARCHAR(255) NULL,
  latitude           DECIMAL(10,7) NULL,
  longitude          DECIMAL(10,7) NULL,
  delivery_available TINYINT(1) NOT NULL DEFAULT 0,
  description        TEXT NULL,
  rental_rules       TEXT NULL,
  status             ENUM('pending_approval','active','inactive','rejected') NOT NULL DEFAULT 'pending_approval',
  is_featured        TINYINT(1) NOT NULL DEFAULT 0,
  created_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (owner_id) REFERENCES users(user_id) ON DELETE CASCADE,
  INDEX idx_cars_search (status, city, price_per_day)
) ENGINE=InnoDB;

-- 5. CAR_IMAGES
CREATE TABLE car_images (
  image_id    INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  car_id      INT UNSIGNED NOT NULL,
  file_path   VARCHAR(255) NOT NULL,
  is_primary  TINYINT(1) NOT NULL DEFAULT 0,
  uploaded_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (car_id) REFERENCES cars(car_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 6. CAR_OCCASIONS (many-to-many link between cars and occasions)
CREATE TABLE car_occasions (
  car_id      INT UNSIGNED NOT NULL,
  occasion_id INT UNSIGNED NOT NULL,
  PRIMARY KEY (car_id, occasion_id),
  FOREIGN KEY (car_id)      REFERENCES cars(car_id)           ON DELETE CASCADE,
  FOREIGN KEY (occasion_id) REFERENCES occasions(occasion_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 7. PROMOTIONS (promo and referral codes)
CREATE TABLE promotions (
  promo_id       INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  code           VARCHAR(30) NOT NULL UNIQUE,
  discount_type  ENUM('percent','fixed') NOT NULL,
  discount_value DECIMAL(10,2) NOT NULL,
  valid_from     DATE NOT NULL,
  valid_to       DATE NOT NULL,
  max_uses       INT UNSIGNED NULL,
  times_used     INT UNSIGNED NOT NULL DEFAULT 0,
  is_active      TINYINT(1) NOT NULL DEFAULT 1,
  created_by     INT UNSIGNED NULL,
  FOREIGN KEY (created_by) REFERENCES users(user_id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- 8. BOOKINGS (amounts are stored as a snapshot at booking time)
CREATE TABLE bookings (
  booking_id      INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  renter_id       INT UNSIGNED NOT NULL,
  car_id          INT UNSIGNED NOT NULL,
  promo_id        INT UNSIGNED NULL,
  start_date      DATE NOT NULL,
  end_date        DATE NOT NULL,
  total_days      SMALLINT UNSIGNED NOT NULL,
  daily_price     DECIMAL(10,2) NOT NULL,
  rental_amount   DECIMAL(10,2) NOT NULL,
  service_fee     DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  discount_amount DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  deposit_amount  DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  total_cost      DECIMAL(10,2) NOT NULL,
  pickup_option   ENUM('pickup','delivery') NOT NULL DEFAULT 'pickup',
  status          ENUM('pending_payment','confirmed','active','completed','cancelled','disputed')
                  NOT NULL DEFAULT 'pending_payment',
  cancel_reason   VARCHAR(255) NULL,
  created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (renter_id) REFERENCES users(user_id),
  FOREIGN KEY (car_id)    REFERENCES cars(car_id),
  FOREIGN KEY (promo_id)  REFERENCES promotions(promo_id) ON DELETE SET NULL,
  CHECK (end_date >= start_date),
  INDEX idx_bookings_car_dates (car_id, start_date, end_date),
  INDEX idx_bookings_renter (renter_id, status)
) ENGINE=InnoDB;

-- 9. AVAILABILITY (dates a car is booked or blocked by its owner)
CREATE TABLE availability (
  availability_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  car_id          INT UNSIGNED NOT NULL,
  start_date      DATE NOT NULL,
  end_date        DATE NOT NULL,
  reason          ENUM('blocked','booked') NOT NULL,
  booking_id      INT UNSIGNED NULL,
  FOREIGN KEY (car_id)     REFERENCES cars(car_id)         ON DELETE CASCADE,
  FOREIGN KEY (booking_id) REFERENCES bookings(booking_id) ON DELETE CASCADE,
  CHECK (end_date >= start_date),
  INDEX idx_availability_car_dates (car_id, start_date, end_date)
) ENGINE=InnoDB;

-- 10. PAYMENTS (a booking may have several attempts; at most one succeeds)
CREATE TABLE payments (
  payment_id         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  booking_id         INT UNSIGNED NOT NULL,
  amount             DECIMAL(10,2) NOT NULL,
  method             ENUM('card','mobile_money','bank_transfer') NULL,
  paystack_reference VARCHAR(100) NOT NULL UNIQUE,
  status             ENUM('pending','success','failed','refunded') NOT NULL DEFAULT 'pending',
  paid_at            DATETIME NULL,
  created_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (booking_id) REFERENCES bookings(booking_id),
  INDEX idx_payments_booking (booking_id, status)
) ENGINE=InnoDB;

-- 11. PAYOUTS (owner earnings after commission, one per completed booking)
CREATE TABLE payouts (
  payout_id         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  booking_id        INT UNSIGNED NOT NULL UNIQUE,
  owner_id          INT UNSIGNED NOT NULL,
  gross_amount      DECIMAL(10,2) NOT NULL,
  commission_rate   DECIMAL(5,2)  NOT NULL,           -- e.g. 15.00 = 15%
  commission_amount DECIMAL(10,2) NOT NULL,
  payout_amount     DECIMAL(10,2) NOT NULL,
  status            ENUM('pending','held','paid') NOT NULL DEFAULT 'pending',
  payout_reference  VARCHAR(100) NULL,
  paid_at           DATETIME NULL,
  FOREIGN KEY (booking_id) REFERENCES bookings(booking_id),
  FOREIGN KEY (owner_id)   REFERENCES users(user_id)
) ENGINE=InnoDB;

-- 12. REVIEWS (two-way: renter reviews owner/car, owner reviews renter)
CREATE TABLE reviews (
  review_id   INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  booking_id  INT UNSIGNED NOT NULL,
  reviewer_id INT UNSIGNED NOT NULL,
  reviewee_id INT UNSIGNED NOT NULL,
  car_id      INT UNSIGNED NOT NULL,
  rating      TINYINT UNSIGNED NOT NULL,
  comment     TEXT NULL,
  created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (booking_id)  REFERENCES bookings(booking_id),
  FOREIGN KEY (reviewer_id) REFERENCES users(user_id),
  FOREIGN KEY (reviewee_id) REFERENCES users(user_id),
  FOREIGN KEY (car_id)      REFERENCES cars(car_id),
  CHECK (rating BETWEEN 1 AND 5),
  UNIQUE KEY uq_one_review_per_booking (booking_id, reviewer_id)
) ENGINE=InnoDB;

-- 13. DISPUTES (damage, late return, no-show, payment issues)
CREATE TABLE disputes (
  dispute_id      INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  booking_id      INT UNSIGNED NOT NULL,
  raised_by       INT UNSIGNED NOT NULL,
  dispute_type    ENUM('damage','late_return','no_show','payment','other') NOT NULL,
  description     TEXT NOT NULL,
  status          ENUM('open','under_review','resolved','closed') NOT NULL DEFAULT 'open',
  resolution_note TEXT NULL,
  resolved_by     INT UNSIGNED NULL,
  created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  resolved_at     DATETIME NULL,
  FOREIGN KEY (booking_id)  REFERENCES bookings(booking_id),
  FOREIGN KEY (raised_by)   REFERENCES users(user_id),
  FOREIGN KEY (resolved_by) REFERENCES users(user_id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- 14. NOTIFICATIONS (email / SMS / in-app log)
CREATE TABLE notifications (
  notification_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id         INT UNSIGNED NOT NULL,
  channel         ENUM('email','sms','in_app') NOT NULL DEFAULT 'email',
  subject         VARCHAR(150) NULL,
  message         TEXT NOT NULL,
  is_read         TINYINT(1) NOT NULL DEFAULT 0,
  sent_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- Starter data
-- ------------------------------------------------------------
INSERT INTO occasions (name) VALUES
 ('Wedding'),('Funeral'),('Airport transfer'),('Business trip'),
 ('Road trip'),('Party / event'),('Tourism'),('Ride-hailing work');

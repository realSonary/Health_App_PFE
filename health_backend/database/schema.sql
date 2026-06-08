-- HealthAI Database Schema
-- MySQL 8.0+

CREATE DATABASE IF NOT EXISTS healthai_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE healthai_db;

-- ============================================================
-- USERS TABLE
-- ============================================================
CREATE TABLE users (
    id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    email         VARCHAR(255) NOT NULL UNIQUE,
    hashed_password VARCHAR(255) NOT NULL,
    is_active     BOOLEAN NOT NULL DEFAULT TRUE,
    is_verified   BOOLEAN NOT NULL DEFAULT FALSE,
    created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_email (email)
) ENGINE=InnoDB;

-- ============================================================
-- PROFILES TABLE
-- ============================================================
CREATE TABLE profiles (
    id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id       INT UNSIGNED NOT NULL UNIQUE,
    full_name     VARCHAR(100),
    date_of_birth DATE,
    gender        ENUM('male','female','other') DEFAULT 'other',
    weight_kg     DECIMAL(5,2),
    height_cm     DECIMAL(5,2),
    blood_type    ENUM('A+','A-','B+','B-','AB+','AB-','O+','O-'),
    medical_conditions JSON COMMENT 'Array of condition strings',
    allergies     JSON COMMENT 'Array of allergy strings',
    avatar_url    VARCHAR(500),
    fcm_token     VARCHAR(500) COMMENT 'Firebase push token',
    created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY fk_profile_user (user_id)
        REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_profile_user (user_id)
) ENGINE=InnoDB;

-- ============================================================
-- SYMPTOMS LOGS TABLE
-- ============================================================
CREATE TABLE symptoms_logs (
    id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id       INT UNSIGNED NOT NULL,
    logged_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    symptoms      JSON NOT NULL COMMENT 'Array of {name, severity 1-10}',
    notes         TEXT,
    duration_hours DECIMAL(5,1),
    body_temp_c   DECIMAL(4,1),
    created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY fk_symptom_user (user_id)
        REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_symptom_user_date (user_id, logged_at)
) ENGINE=InnoDB;

-- ============================================================
-- MEDICATIONS TABLE
-- ============================================================
CREATE TABLE medications (
    id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id       INT UNSIGNED NOT NULL,
    name          VARCHAR(200) NOT NULL,
    dosage        VARCHAR(100) NOT NULL,
    frequency     ENUM('once_daily','twice_daily','three_times_daily',
                       'four_times_daily','as_needed','weekly') NOT NULL,
    schedule_times JSON COMMENT 'Array of HH:MM strings',
    start_date    DATE NOT NULL,
    end_date      DATE,
    notes         TEXT,
    is_active     BOOLEAN NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY fk_med_user (user_id)
        REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_med_user (user_id, is_active)
) ENGINE=InnoDB;

-- ============================================================
-- MEDICATION LOGS (Taken / Missed / Skipped)
-- ============================================================
CREATE TABLE medication_logs (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    medication_id   INT UNSIGNED NOT NULL,
    user_id         INT UNSIGNED NOT NULL,
    scheduled_time  DATETIME NOT NULL,
    taken_at        DATETIME,
    status          ENUM('taken','missed','skipped') NOT NULL DEFAULT 'missed',
    notes           TEXT,
    FOREIGN KEY fk_medlog_medication (medication_id)
        REFERENCES medications(id) ON DELETE CASCADE,
    FOREIGN KEY fk_medlog_user (user_id)
        REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_medlog_user_date (user_id, scheduled_time)
) ENGINE=InnoDB;

-- ============================================================
-- WATER LOGS TABLE
-- ============================================================
CREATE TABLE water_logs (
    id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id       INT UNSIGNED NOT NULL,
    logged_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    amount_ml     INT UNSIGNED NOT NULL,
    FOREIGN KEY fk_water_user (user_id)
        REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_water_user_date (user_id, logged_at)
) ENGINE=InnoDB;

-- ============================================================
-- SLEEP LOGS TABLE
-- ============================================================
CREATE TABLE sleep_logs (
    id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id       INT UNSIGNED NOT NULL,
    sleep_start   DATETIME NOT NULL,
    sleep_end     DATETIME NOT NULL,
    duration_hours DECIMAL(4,2) AS (TIMESTAMPDIFF(MINUTE, sleep_start, sleep_end) / 60.0) STORED,
    quality       TINYINT UNSIGNED NOT NULL COMMENT '1-5 rating',
    notes         TEXT,
    FOREIGN KEY fk_sleep_user (user_id)
        REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_sleep_user_date (user_id, sleep_start)
) ENGINE=InnoDB;

-- ============================================================
-- CALORIES LOGS TABLE
-- ============================================================
CREATE TABLE calories_logs (
    id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id       INT UNSIGNED NOT NULL,
    logged_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    meal_type     ENUM('breakfast','lunch','dinner','snack') NOT NULL,
    food_name     VARCHAR(200) NOT NULL,
    calories      INT UNSIGNED NOT NULL,
    protein_g     DECIMAL(6,2),
    carbs_g       DECIMAL(6,2),
    fat_g         DECIMAL(6,2),
    FOREIGN KEY fk_cal_user (user_id)
        REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_cal_user_date (user_id, logged_at)
) ENGINE=InnoDB;

-- ============================================================
-- HEALTH SCORES TABLE
-- ============================================================
CREATE TABLE health_scores (
    id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id       INT UNSIGNED NOT NULL,
    scored_at     DATE NOT NULL,
    overall_score DECIMAL(5,2) NOT NULL COMMENT '0-100',
    sleep_score   DECIMAL(5,2),
    water_score   DECIMAL(5,2),
    medication_score DECIMAL(5,2),
    symptom_score DECIMAL(5,2),
    FOREIGN KEY fk_score_user (user_id)
        REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY uk_score_user_date (user_id, scored_at),
    INDEX idx_score_user_date (user_id, scored_at)
) ENGINE=InnoDB;

-- ============================================================
-- PREDICTIONS TABLE
-- ============================================================
CREATE TABLE predictions (
    id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id       INT UNSIGNED NOT NULL,
    symptom_log_id INT UNSIGNED,
    predicted_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    results       JSON NOT NULL COMMENT 'Array of {disease, confidence, actions}',
    model_version VARCHAR(50) NOT NULL,
    FOREIGN KEY fk_pred_user (user_id)
        REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY fk_pred_symptom (symptom_log_id)
        REFERENCES symptoms_logs(id) ON DELETE SET NULL,
    INDEX idx_pred_user (user_id, predicted_at)
) ENGINE=InnoDB;

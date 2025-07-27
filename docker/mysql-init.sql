-- MySQL initialization script for DMOJ
SET NAMES utf8mb4;
SET CHARACTER SET utf8mb4;

-- Create database if not exists
CREATE DATABASE IF NOT EXISTS dmoj CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Grant privileges
GRANT ALL PRIVILEGES ON dmoj.* TO 'dmoj'@'%';
FLUSH PRIVILEGES;

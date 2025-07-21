-- MySQL initialization script
ALTER DATABASE dmoj CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Create tables with proper encoding
SET NAMES utf8mb4;
SET character_set_client = utf8mb4;

-- Grant permissions
GRANT ALL PRIVILEGES ON dmoj.* TO 'dmoj'@'%';
FLUSH PRIVILEGES; 
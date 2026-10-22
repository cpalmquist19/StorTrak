-- StorTrak database bootstrap.
-- Runs automatically on first MySQL container start (docker-entrypoint-initdb.d)
-- and again on `make reset`. Tables are added in later steps.

CREATE DATABASE IF NOT EXISTS stortrak
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

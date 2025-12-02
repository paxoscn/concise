-- Seed data for testing
-- This script creates default test users and sample data

-- Insert default test user
-- Password: "password123" hashed with bcrypt
-- Note: In production, generate a new bcrypt hash for security
INSERT INTO users (id, nickname, password_hash, created_at, updated_at)
VALUES (
    'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
    'admin',
    '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYqVr/qvM8u',
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
) ON CONFLICT (id) DO NOTHING;

-- Insert test user
-- Password: "test123"
INSERT INTO users (id, nickname, password_hash, created_at, updated_at)
VALUES (
    'b1ffcd99-8d1c-5fg9-cc7e-7cc0ce491b22',
    'testuser',
    '$2b$12$EixZaYVK1fsbw1ZfbX3OXePaWxn96p36WQoeG6Lruj3vjPGga31lW',
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
) ON CONFLICT (id) DO NOTHING;

-- Insert sample data source (MySQL)
INSERT INTO data_sources (id, name, db_type, connection_config, created_at, updated_at)
VALUES (
    'c2ggde99-7e2d-6hh0-dd8f-8dd1df502c33',
    'Sample MySQL Database',
    'MySQL',
    jsonb_build_object(
        'host', 'localhost',
        'port', 3306,
        'database', 'sample_db',
        'username', 'sample_user',
        'password', 'sample_pass'
    ),
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
) ON CONFLICT (id) DO NOTHING;

-- Insert sample data source (PostgreSQL)
INSERT INTO data_sources (id, name, db_type, connection_config, created_at, updated_at)
VALUES (
    'd3hhef99-6f3e-7ii1-ee9g-9ee2eg613d44',
    'Sample PostgreSQL Database',
    'PostgreSQL',
    jsonb_build_object(
        'host', 'localhost',
        'port', 5432,
        'database', 'sample_db',
        'username', 'sample_user',
        'password', 'sample_pass'
    ),
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
) ON CONFLICT (id) DO NOTHING;

-- Insert sample storage (S3)
INSERT INTO storages (id, name, storage_type, upload_endpoint, download_endpoint, auth_config, created_at, updated_at)
VALUES (
    'e4iifg99-5g4f-8jj2-ff0h-0ff3fh724e55',
    'Sample S3 Storage',
    'S3',
    'https://s3.amazonaws.com/sample-bucket',
    'https://s3.amazonaws.com/sample-bucket',
    jsonb_build_object(
        'access_key', 'AKIAIOSFODNN7EXAMPLE',
        'secret_key', 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY',
        'region', 'us-east-1'
    ),
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
) ON CONFLICT (id) DO NOTHING;

-- Insert sample storage (MinIO)
INSERT INTO storages (id, name, storage_type, upload_endpoint, download_endpoint, auth_config, created_at, updated_at)
VALUES (
    'f5jjgh99-4h5g-9kk3-gg1i-1gg4gi835f66',
    'Sample MinIO Storage',
    'MinIO',
    'http://minio:9000/sample-bucket',
    'http://minio:9000/sample-bucket',
    jsonb_build_object(
        'access_key', 'minioadmin',
        'secret_key', 'minioadmin'
    ),
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
) ON CONFLICT (id) DO NOTHING;

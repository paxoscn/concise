# Database Initialization Scripts

This directory contains SQL scripts that are automatically executed when the MySQL container starts for the first time.

## Scripts

### 01-init-schema.sql
Creates the database schema including:
- `users` table: User authentication data
- `data_sources` table: Database connection configurations
- `storages` table: Object storage configurations

### 02-seed-data.sql
Inserts test data including:
- Default admin user (nickname: `admin`, password: `password123`)
- Test user (nickname: `testuser`, password: `test123`)
- Sample data sources (MySQL and PostgreSQL)
- Sample storage configurations (S3 and MinIO)

## Usage

These scripts are automatically executed by the MySQL container when it's first initialized. The scripts are mounted via docker-compose.yml:

```yaml
volumes:
  - ./init-db:/docker-entrypoint-initdb.d
```

## Security Note

⚠️ **WARNING**: The default passwords in these scripts are for testing purposes only. 

In production:
1. Generate new bcrypt hashes for user passwords
2. Use strong, unique passwords
3. Store sensitive credentials in environment variables or secrets management systems
4. Remove or modify the seed data script

## Generating Password Hashes

To generate a new bcrypt hash for a password, you can use:

```bash
# Using Python
python3 -c "import bcrypt; print(bcrypt.hashpw(b'your_password', bcrypt.gensalt()).decode())"

# Using Node.js
node -e "const bcrypt = require('bcrypt'); bcrypt.hash('your_password', 12, (err, hash) => console.log(hash));"
```

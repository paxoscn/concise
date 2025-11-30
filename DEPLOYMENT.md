# Deployment Guide

This guide explains how to deploy the Data Lakehouse System using Docker and Docker Compose.

## Prerequisites

- Docker Engine 20.10+
- Docker Compose 2.0+
- At least 4GB of available RAM
- At least 10GB of available disk space

## Quick Start

1. **Clone the repository and navigate to the project root**

2. **Start all services**
   ```bash
   docker-compose up -d
   ```

3. **Check service status**
   ```bash
   docker-compose ps
   ```

4. **View logs**
   ```bash
   # All services
   docker-compose logs -f
   
   # Specific service
   docker-compose logs -f backend
   docker-compose logs -f frontend
   docker-compose logs -f mysql
   ```

5. **Access the application**
   - Frontend: http://localhost
   - Backend API: http://localhost:8080
   - MySQL: localhost:3306

## Default Credentials

### Test Users
- **Admin User**
  - Nickname: `admin`
  - Password: `password123`

- **Test User**
  - Nickname: `testuser`
  - Password: `test123`

### Database
- **Root User**
  - Username: `root`
  - Password: `rootpassword`

- **Application User**
  - Username: `lakehouse_user`
  - Password: `lakehouse_pass`
  - Database: `lakehouse`

⚠️ **Change these credentials in production!**

## Architecture

```
┌─────────────────────────────────────┐
│         Frontend (Nginx)            │
│         Port: 80                    │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│         Backend (Rust)              │
│         Port: 8080                  │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│         MySQL Database              │
│         Port: 3306                  │
└─────────────────────────────────────┘
```

## Services

### Frontend
- **Image**: Built from `frontend/Dockerfile`
- **Port**: 80
- **Technology**: Vue.js/React + Nginx
- **Configuration**: `frontend/nginx.conf`

### Backend
- **Image**: Built from `backend/Dockerfile`
- **Port**: 8080
- **Technology**: Rust + Axum + SeaORM
- **Configuration**: `backend/config/default.toml`

### MySQL
- **Image**: mysql:8.0
- **Port**: 3306
- **Data Volume**: `mysql_data`
- **Initialization**: Scripts in `init-db/` directory

## Configuration

### Environment Variables

You can override default configuration using environment variables:

```bash
# Backend
export DATABASE_URL="mysql://user:pass@host:3306/dbname"
export JWT_SECRET="your-secret-key"
export TASK_CENTER_URL="http://task-center:8081"
export SERVER_PORT="8080"
export RUST_LOG="info"

# MySQL
export MYSQL_ROOT_PASSWORD="rootpassword"
export MYSQL_DATABASE="lakehouse"
export MYSQL_USER="lakehouse_user"
export MYSQL_PASSWORD="lakehouse_pass"
```

### Custom docker-compose Configuration

Create a `docker-compose.override.yml` file for local customizations:

```yaml
version: '3.8'

services:
  backend:
    environment:
      JWT_SECRET: my-custom-secret
      RUST_LOG: debug
    ports:
      - "8081:8080"
```

## Database Initialization

The database is automatically initialized on first startup using scripts in the `init-db/` directory:

1. **01-init-schema.sql**: Creates tables and indexes
2. **02-seed-data.sql**: Inserts test data

To reset the database:
```bash
docker-compose down -v  # Remove volumes
docker-compose up -d    # Restart with fresh database
```

## Building Images

### Build all images
```bash
docker-compose build
```

### Build specific service
```bash
docker-compose build backend
docker-compose build frontend
```

### Build with no cache
```bash
docker-compose build --no-cache
```

## Managing Services

### Start services
```bash
docker-compose up -d
```

### Stop services
```bash
docker-compose stop
```

### Restart services
```bash
docker-compose restart
```

### Remove services and volumes
```bash
docker-compose down -v
```

### Scale services (if needed)
```bash
docker-compose up -d --scale backend=3
```

## Monitoring

### View resource usage
```bash
docker stats
```

### View service logs
```bash
# Follow all logs
docker-compose logs -f

# Last 100 lines
docker-compose logs --tail=100

# Specific service
docker-compose logs -f backend
```

### Health checks
```bash
# Check MySQL health
docker-compose exec mysql mysqladmin ping -h localhost -u root -prootpassword

# Check backend health
curl http://localhost:8080/health

# Check frontend
curl http://localhost
```

## Troubleshooting

### Backend won't start
1. Check database connection:
   ```bash
   docker-compose logs mysql
   docker-compose logs backend
   ```
2. Verify DATABASE_URL is correct
3. Ensure MySQL is healthy before backend starts

### Frontend can't reach backend
1. Check nginx configuration in `frontend/nginx.conf`
2. Verify backend is running: `docker-compose ps`
3. Check network connectivity: `docker-compose exec frontend ping backend`

### Database connection issues
1. Wait for MySQL to be fully initialized (check logs)
2. Verify credentials in docker-compose.yml
3. Check if port 3306 is already in use

### Port conflicts
If ports are already in use, modify `docker-compose.yml`:
```yaml
services:
  frontend:
    ports:
      - "8000:80"  # Change 80 to 8000
  backend:
    ports:
      - "8081:8080"  # Change 8080 to 8081
```

## Production Deployment

### Security Checklist

- [ ] Change all default passwords
- [ ] Generate strong JWT secret
- [ ] Use HTTPS (add SSL certificates to nginx)
- [ ] Restrict database access (remove port exposure)
- [ ] Use Docker secrets for sensitive data
- [ ] Enable firewall rules
- [ ] Regular security updates
- [ ] Implement backup strategy

### Production docker-compose.yml

```yaml
version: '3.8'

services:
  mysql:
    # Remove port exposure for security
    # ports:
    #   - "3306:3306"
    environment:
      MYSQL_ROOT_PASSWORD_FILE: /run/secrets/mysql_root_password
    secrets:
      - mysql_root_password

  backend:
    environment:
      JWT_SECRET_FILE: /run/secrets/jwt_secret
    secrets:
      - jwt_secret

secrets:
  mysql_root_password:
    external: true
  jwt_secret:
    external: true
```

### Backup Strategy

```bash
# Backup database
docker-compose exec mysql mysqldump -u root -prootpassword lakehouse > backup.sql

# Restore database
docker-compose exec -T mysql mysql -u root -prootpassword lakehouse < backup.sql

# Backup volumes
docker run --rm -v lakehouse_mysql_data:/data -v $(pwd):/backup alpine tar czf /backup/mysql_data_backup.tar.gz /data
```

## Performance Tuning

### MySQL Optimization
Add to docker-compose.yml:
```yaml
services:
  mysql:
    command: --max_connections=200 --innodb_buffer_pool_size=1G
```

### Backend Optimization
- Adjust connection pool size in `backend/config/default.toml`
- Increase worker threads if needed
- Enable production optimizations in Dockerfile

## Support

For issues and questions:
- Check logs: `docker-compose logs`
- Review documentation in `init-db/README.md`
- Verify configuration in `backend/config/default.toml`

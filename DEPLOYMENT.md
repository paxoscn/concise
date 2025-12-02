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
   - PostgreSQL: localhost:5432

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
│      PostgreSQL Database            │
│         Port: 5432                  │
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

### PostgreSQL
- **Image**: postgres:16
- **Port**: 5432
- **Data Volume**: `postgres_data`
- **Initialization**: Scripts in `init-db/` directory

## Configuration

### Environment Variables

You can override default configuration using environment variables:

```bash
# Backend
export DATABASE_URL="postgres://user:pass@host:5432/dbname"
export JWT_SECRET="your-secret-key"
export TASK_CENTER_URL="http://task-center:8081"
export SERVER_PORT="8080"
export RUST_LOG="info"

# PostgreSQL
export POSTGRES_DB="lakehouse"
export POSTGRES_USER="lakehouse_user"
export POSTGRES_PASSWORD="lakehouse_pass"
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
# Check PostgreSQL health
docker-compose exec postgres pg_isready -U lakehouse_user

# Check backend health
curl http://localhost:8080/health

# Check frontend
curl http://localhost
```

## Troubleshooting

### Backend won't start
1. Check database connection:
   ```bash
   docker-compose logs postgres
   docker-compose logs backend
   ```
2. Verify DATABASE_URL is correct
3. Ensure PostgreSQL is healthy before backend starts

### Frontend can't reach backend
1. Check nginx configuration in `frontend/nginx.conf`
2. Verify backend is running: `docker-compose ps`
3. Check network connectivity: `docker-compose exec frontend ping backend`

### Database connection issues
1. Wait for PostgreSQL to be fully initialized (check logs)
2. Verify credentials in docker-compose.yml
3. Check if port 5432 is already in use

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
  postgres:
    # Remove port exposure for security
    # ports:
    #   - "5432:5432"
    environment:
      POSTGRES_PASSWORD_FILE: /run/secrets/postgres_password
    secrets:
      - postgres_password

  backend:
    environment:
      JWT_SECRET_FILE: /run/secrets/jwt_secret
    secrets:
      - jwt_secret

secrets:
  postgres_password:
    external: true
  jwt_secret:
    external: true
```

### Backup Strategy

```bash
# Backup database
docker-compose exec postgres pg_dump -U lakehouse_user lakehouse > backup.sql

# Restore database
docker-compose exec -T postgres psql -U lakehouse_user lakehouse < backup.sql

# Backup volumes
docker run --rm -v lakehouse_postgres_data:/data -v $(pwd):/backup alpine tar czf /backup/postgres_data_backup.tar.gz /data
```

## Performance Tuning

### PostgreSQL Optimization
Add to docker-compose.yml:
```yaml
services:
  postgres:
    command: -c max_connections=200 -c shared_buffers=1GB
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

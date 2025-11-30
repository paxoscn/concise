# Configuration Guide

## Configuration Files

The application uses `config/default.toml` as the default configuration file.

## Configuration Structure

```toml
[server]
host = "0.0.0.0"
port = 8080

[database]
url = "mysql://user:password@localhost:3306/lakehouse"
max_connections = 10

[jwt]
secret = "your-secret-key-change-in-production"
expiration_hours = 24

[task_center]
base_url = "http://task-center:8081"
timeout_seconds = 30

[logging]
level = "info"
```

## Environment Variable Overrides

You can override any configuration value using environment variables with the prefix `APP__` and double underscores as separators.

### Examples

Override server port:
```bash
APP__SERVER__PORT=9090 cargo run
```

Override database URL:
```bash
APP__DATABASE__URL="mysql://user:pass@localhost:3306/mydb" cargo run
```

Override JWT secret:
```bash
APP__JWT__SECRET="my-super-secret-key" cargo run
```

Override task center URL:
```bash
APP__TASK_CENTER__BASE_URL="http://localhost:8081" cargo run
```

Override logging level:
```bash
APP__LOGGING__LEVEL="debug" cargo run
```

### Multiple Overrides

You can combine multiple environment variables:
```bash
APP__SERVER__PORT=9090 \
APP__DATABASE__URL="mysql://user:pass@localhost:3306/mydb" \
APP__JWT__SECRET="production-secret" \
cargo run
```

## Configuration Loading Order

1. Load `config/default.toml` (if exists)
2. Override with environment variables prefixed with `APP__`

Environment variables always take precedence over file configuration.

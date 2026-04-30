# Math App

Math learning Flutter app for Vietnamese kids ages 5-7 with Rust microservices backend.

## Quick Start

```bash
# Install dependencies (local Flutter SDK + Rust)
make setup

# Full CI pipeline: format, lint, test, build
make deploy

# Start all services (Docker)
make docker-dev
```

## Requirements

- **Docker with Buildx**
  - If `buildx` isn't installed, run:
    ```bash
    docker buildx create --use
    ```
- **Rust 1.93** (matching `backend/Dockerfile`)
- **Flutter** (optional: local SDK is auto-downloaded)

## Access URLs

### After `make docker-dev`

| URL | Resource |
|-----|----------|
| [http://localhost:8082](http://localhost:8082) | Flutter web app |
| [http://localhost:8083](http://localhost:8083) | Traefik dashboard |

### API Docs (Swagger UI)

| Service | URL |
|---------|-----|
| Auth | http://localhost:8082/api/auth/swagger-ui |
| Content | http://localhost:8082/api/content/swagger-ui |
| Users | http://localhost:8082/api/users/swagger-ui |
| Progress | http://localhost:8082/api/progress/swagger-ui |
| Notifications | http://localhost:8082/api/notifications/swagger-ui |
| Media | http://localhost:8082/api/media/swagger-ui |

### MinIO Console

| URL | Resource |
|-----|----------|
| [http://localhost:9002](http://localhost:9002) | MinIO API |
| [http://localhost:9003](http://localhost:9003) | MinIO Console |

## Makefile Commands

| Command | Description |
|---------|-------------|
| `make setup` | Install dependencies |
| `make deploy` | Full CI pipeline (format+lint+test+build) |
| `make test` | Flutter tests only |
| `make test-rust` | Rust tests only |
| `make test-all` | All tests |
| `make build-web` | Build Flutter web |
| `make build-rust` | Build Rust backend |
| `make lint` | Run analyzers |
| `make format` | Format code |
| `make docker-dev` | Start Docker services |
| `make docker-stop` | Stop Docker services |

## Project Structure

```
.
├── frontend          # Flutter app
│   ├── lib/
│   └── test/
├── backend           # Rust microservices
│   ├── auth/
│   ├── user/
│   ├── content/
│   ├── progress/
│   ├── notification/
│   ├── media/
│   └── shared/
├── docker-compose.yml
└── Makefile
```

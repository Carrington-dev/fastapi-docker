# FastAPI Docker — README

A minimal, practical README for containerizing a FastAPI app.

## Project layout
- app/
    - main.py            # FastAPI application (app = FastAPI())
    - requirements.txt
- Dockerfile
- docker-compose.yml
- .env                 # optional environment variables

## Quick start (production-ish)
Build image:
```bash
docker build -t my-fastapi:latest .
```
Run container:
```bash
docker run --rm -p 8000:80 --env-file .env my-fastapi:latest
```
Open: http://localhost:8000/docs

## Dockerfile (recommended, multistage)
```dockerfile
# Build stage
FROM python:3.11-slim AS builder
WORKDIR /app
RUN apt-get update && apt-get install -y build-essential gcc libpq-dev --no-install-recommends && rm -rf /var/lib/apt/lists/*
COPY requirements.txt .
RUN pip install --upgrade pip && pip wheel --no-cache-dir -r requirements.txt -w /wheels

# Final stage
FROM python:3.11-slim
WORKDIR /app
COPY --from=builder /wheels /wheels
RUN pip install --no-cache /wheels/*
COPY . .
ENV PYTHONUNBUFFERED=1
EXPOSE 80
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "80", "--proxy-headers"]
```

Notes:
- For production, consider using Gunicorn + Uvicorn workers:
    CMD ["gunicorn", "-k", "uvicorn.workers.UvicornWorker", "app.main:app", "-b", "0.0.0.0:80", "--workers", "4"]

## docker-compose.yml (development)
```yaml
version: "3.8"
services:
    web:
        build: .
        ports:
            - "8000:80"
        volumes:
            - ./app:/app
        env_file:
            - .env
        restart: unless-stopped
        healthcheck:
            test: ["CMD", "curl", "-f", "http://localhost:80/health || exit 1"]
            interval: 30s
            timeout: 5s
            retries: 3
```
- Mounting the app directory enables live-editing (requires auto-reload in uvicorn).

## Environment variables
Use .env for secrets and configuration:
```
APP_ENV=production
DATABASE_URL=postgresql://user:pass@db:5432/app
LOG_LEVEL=info
```

## Useful commands
- Build: docker-compose build
- Start: docker-compose up -d
- View logs: docker-compose logs -f web
- Exec shell: docker-compose exec web sh
- Rebuild after requirements change: docker-compose build --no-cache web

## Health & readiness
- Expose a lightweight /health or /ready endpoint that returns 200 for orchestrator checks.
- Configure Docker HEALTHCHECK (see compose example).

## Testing inside container
Run tests with pytest in container:
```bash
docker-compose run --rm web pytest -q
```

## Tips
- Pin dependency versions in requirements.txt for deterministic builds.
- Use multi-stage builds to keep images small.
- Consider using a distroless or slim base for smaller final image.
- Use a process manager (gunicorn) for multiple workers in production.

## License
Project files are under your chosen license.

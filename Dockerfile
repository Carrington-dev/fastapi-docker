FROM python:3.12-slim

WORKDIR /app

LABEL version="0.0.1"
LABEL maintainer="X Xavier <xxxxx@gmail.com>"

# Update and install dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# Copy requirements
COPY requirements.txt .

# Install dependencies with uv (10-100x faster than pip!)
RUN uv pip install --system -r requirements.txt

# Copy app code (make sure to copy after installing dependencies to leverage caching to speed up builds, working directory is /app)
COPY  . /app

# Set environment variables
ENV PYTHONUNBUFFERED=1

EXPOSE 8000

RUN pwd && ls -la

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
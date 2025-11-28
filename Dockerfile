# Use a slim Python image
FROM python:3.10-slim

# Prevent Python from writing .pyc files and enable unbuffered stdout/stderr
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Set working dir
WORKDIR /app

# Install system dependencies needed for:
# - ffmpeg (audio conversion)
# - chromium (headless browser)
# - chromium-driver (Chromedriver)
# - libsndfile1 (audio libs)
# - build-essential for some pip installs
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    ca-certificates \
    ffmpeg \
    chromium \
    chromium-driver \
    libsndfile1 \
    build-essential \
    git \
    && rm -rf /var/lib/apt/lists/*

# Ensure Chromium path is available to selenium (we'll reference /usr/bin/chromium)
ENV CHROME_BIN=/usr/bin/chromium
ENV CHROMEDRIVER_PATH=/usr/bin/chromedriver

# Copy requirements first for better caching
COPY requirements.txt /app/requirements.txt

# Install Python requirements; use pip's --no-cache-dir to reduce image size
# If your requirements.txt includes torch, this will download CPU torch and can be large (~300MB).
RUN pip install --upgrade pip
RUN pip install --no-cache-dir -r /app/requirements.txt

# Copy app
COPY . /app

# Expose the port Render will map
ENV PORT 8000

# Create a non-root user (optional but recommended)
RUN useradd -m appuser || true
RUN chown -R appuser:appuser /app
USER appuser

# Default start command - use gunicorn with Uvicorn worker
CMD ["gunicorn", "-k", "uvicorn.workers.UvicornWorker", "main:app", "--bind", "0.0.0.0:8000", "--workers", "1", "--timeout", "120"]

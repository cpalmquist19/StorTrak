# Seed-data generator. Dependencies are baked in; the generator source is
# bind-mounted at run time (see the `seed` service in docker-compose.yml),
# so code changes do not need an image rebuild.
FROM python:3.12.7-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /app
COPY seed/requirements.txt /tmp/requirements.txt
RUN pip install -r /tmp/requirements.txt

ENTRYPOINT ["python", "-m", "seed"]
CMD ["--out", "/out/seed.sql"]

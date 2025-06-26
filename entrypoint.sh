#!/bin/bash
set -e

# Generate any missing migrations and apply them
python manage.py makemigrations --noinput || true
python manage.py migrate --noinput --run-syncdb

# Create default superuser if it doesn't exist
python manage.py shell <<'PY'
from django.contrib.auth import get_user_model
User = get_user_model()
if not User.objects.filter(username="admin").exists():
    User.objects.create_superuser("admin", "admin@example.com", "admin")
PY

# Collect static files (idempotent)
python manage.py collectstatic --noinput

GUNICORN_OPTS="${GUNICORN_OPTS:-"--worker-class gthread --threads 4 --workers 3 --timeout 300 --keep-alive 5 --max-requests 500 --max-requests-jitter 50"}"

# Allow overriding Gunicorn options via $GUNICORN_OPTS env var
exec gunicorn horilla.wsgi:application \
    --bind 0.0.0.0:8000 \
    $GUNICORN_OPTS

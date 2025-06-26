#!/bin/bash
set -e

# Wait for the database to become available
python manage.py migrate --check || python manage.py migrate --noinput

# Create default superuser if it doesn't exist
python manage.py shell <<'PY'
from django.contrib.auth import get_user_model
User = get_user_model()
if not User.objects.filter(username="admin").exists():
    User.objects.create_superuser("admin", "admin@example.com", "admin")
PY

# Collect static files (idempotent)
python manage.py collectstatic --noinput

exec gunicorn horilla.wsgi:application \
    --bind 0.0.0.0:8000 \
    --workers ${WORKERS:-1} \
    --timeout ${TIMEOUT:-300}

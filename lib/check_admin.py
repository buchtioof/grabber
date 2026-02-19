import os
import sys
import django

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

sys.path.insert(0, BASE_DIR)
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')

django.setup()

from django.contrib.auth import get_user_model

User = get_user_model()

if User.objects.filter(is_superuser=True).exists():
    sys.exit(0)
else:
    sys.exit(1)
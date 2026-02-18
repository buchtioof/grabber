import os
import sys
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')

django.setup()

from django.contrib.auth import get_user_model

User = get_user_model()

if User.objects.filter(is_superuser=True).exists():
    sys.exit(0)  # Code 0 = Succès (le superuser existe)
else:
    sys.exit(1)  # Code 1 = Erreur/Faux (aucun superuser)
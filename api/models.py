from django.db import models

class SystemInfo(models.Model):

    # Primary key
    id = models.BigAutoField(primary_key=True)

    # ID of computer
    mac_address = models.CharField(max_length=100, unique=True)
    
    # HARDWARE
    motherboard = models.CharField(max_length=255, null=True, blank=True)
    cpu_model = models.CharField(max_length=255, null=True, blank=True)
    cpu_id = models.CharField(max_length=255, null=True, blank=True)
    cpu_cores = models.CharField(max_length=50, null=True, blank=True)
    cpu_threads = models.CharField(max_length=50, null=True, blank=True)
    cpu_frequency_min = models.CharField(max_length=50, null=True, blank=True)
    cpu_frequency_cur = models.CharField(max_length=50, null=True, blank=True)
    cpu_frequency_max = models.CharField(max_length=50, null=True, blank=True)
    gpu_model = models.CharField(max_length=255, null=True, blank=True)
    ram_slots = models.CharField(max_length=50, null=True, blank=True)
    ram_total = models.CharField(max_length=50, null=True, blank=True)
    total_storage = models.CharField(max_length=50, null=True, blank=True)

    # SOFTWARE
    hostname = models.CharField(max_length=255, null=True, blank=True)
    os = models.CharField(max_length=255, null=True, blank=True)
    arch = models.CharField(max_length=50, null=True, blank=True)
    desktop_env = models.CharField(max_length=100, null=True, blank=True)
    window_manager = models.CharField(max_length=100, null=True, blank=True)
    kernel = models.CharField(max_length=100, null=True, blank=True)

    # Last update date
    last_updated = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.hostname} ({self.mac_address})"
from django.contrib import admin
from .models import SystemInfo

admin.site.site_header = "💻 Tableau de bord Grabber"
admin.site.site_title = "Grabber Admin"
admin.site.index_title = "Gestion du parc informatique"

@admin.register(SystemInfo)
class SystemInfoAdmin(admin.ModelAdmin):
    list_display = ('mac_address', 'hostname', 'os', 'ram_total', 'total_storage', 'last_updated')
    list_editable = ('hostname', 'os', 'ram_total', 'total_storage')
    search_fields = ('hostname', 'mac_address', 'os', 'cpu_model')
    list_filter = ('os', 'desktop_env')

    class Media:
        css = {
            'all': ('css/admin.css',)
        }
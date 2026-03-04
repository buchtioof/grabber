from django.contrib import admin
from django.urls import path, include
from django.views.generic import RedirectView
from web import views, api

# Redirect /admin path to / root but lets login possible
admin_patterns = ([
    path('login/', admin.site.login, name='login'),
    path('', RedirectView.as_view(url='/', permanent=False), name='index'),
], 'admin')

urlpatterns = [
    path('admin/', include(admin_patterns)),                                # Permit admin requests
    path('i18n/', include('django.conf.urls.i18n')),                        # Request translations
    path('endpoint', api.receive_system_info, name='receive_system_info'),  # Endpoint fetch Alfred data from target PC

    # Views for user
    path('', views.computers_list, name='computers_list'),
    path('deploy', views.deploy_ssh, name='deploy_ssh'),
    path('ordi/<str:mac_address>', views.show_info, name='show_info'),
    path('logout', views.logout_view, name='logout'),
    path('update_admin/', views.update_admin, name='update_admin'),
    path('employees/manage/', views.manage_employees, name='manage_employees'),
]
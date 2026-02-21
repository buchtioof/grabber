from django.contrib import admin
from django.urls import path, include
from django.views.generic import RedirectView
from api import views, api

# Redirect /admin path to / root but lets login possible
admin_patterns = ([
    path('login/', admin.site.login, name='login'),
    path('', RedirectView.as_view(url='/', permanent=False), name='index'),
], 'admin')

urlpatterns = [
    path('admin/', include(admin_patterns)),

    path('endpoint', api.receive_system_info, name='receive_system_info'), # API fetch grabber.sh data

    # Views for user
    path('', views.computers_list, name='computers_list'),
    path('deploy', views.deploy_ssh, name='deploy_ssh'),
    path('ordi/<str:mac_address>', views.show_info, name='show_info'),
    path('logout', views.logout_view, name='logout'),
]
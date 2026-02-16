# Manage the url paths for pages
from django.urls import path
from api import views

urlpatterns = [
    path('endpoint', views.receive_system_info, name='receive_system_info'),
    path('', views.computers_list, name='computers'), # Homepage
    path('ordi/<str:mac_address>', views.show_info, name='show_info'), # Details page
]
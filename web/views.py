import os
import paramiko
from django.db import IntegrityError
from django.conf import settings
from django.contrib import messages
from django.shortcuts import render, get_object_or_404, redirect
from django.contrib.admin.views.decorators import staff_member_required
from django.contrib.auth import logout, update_session_auth_hash
from django.utils.translation import gettext as _
from django.utils import translation
from .models import SystemInfo, Employees

# Actions in list.html page
@staff_member_required(login_url='admin:login')
def computers_list(request):
    
    if request.method == 'POST':
        
        # Action via button to delete a PC
        if 'delete_mac' in request.POST:
            mac_to_delete = request.POST.get('delete_mac')
            pc = get_object_or_404(SystemInfo, mac_address=mac_to_delete)
            pc.delete()
            return redirect('computers_list')
        
        elif 'edit_computer' in request.POST:
            mac_address = request.POST.get('mac_address')
            ip_address = request.POST.get('ip_address')
            ssh_user = request.POST.get('ssh_user')
            
            pc = get_object_or_404(SystemInfo, mac_address=mac_address)
            pc.ip_address = ip_address
            pc.ssh_user = ssh_user
            pc.save()
            
            messages.success(request, _("[OK] The information of {hostname} has been updated.").format(hostname=pc.hostname))
            return redirect('computers_list')

    computers = SystemInfo.objects.all()
    employees = Employees.objects.all()
    return render(request, 'list.html', {'computers': computers, 'employees': employees})

@staff_member_required(login_url='admin:login')
def show_info(request, mac_address):
    
    if request.method == 'POST' and 'assign_employee' in request.POST:
        employees_id = request.POST.get('employees_id')
        pc = get_object_or_404(SystemInfo, mac_address=mac_address)
        
        if employees_id:
            employee = get_object_or_404(Employees, id=employees_id)
            pc.employees = employee
            messages.success(request, _("[OK] The computer has been assigned to {first_name} {last_name}.").format(first_name=employee.first_name, last_name=employee.last_name))
        else:
            pc.employees = None
            messages.success(request, _("[OK] The assignment has been removed for this computer."))
            
        pc.save()
        return redirect(request.META.get('HTTP_REFERER', 'computers_list'))

    # Object that fetch the system informations via SystemInfo in models.py linked to the mac adress asked, if no return = 404
    computer_info = get_object_or_404(SystemInfo, mac_address=mac_address)
    employees = Employees.objects.all()
    
    # Return the requested object in item.html by using the keyword "data"
    return render(request, 'item.html', {'data': computer_info, 'employees': employees})
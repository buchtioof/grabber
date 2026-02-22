import os
import paramiko
from django.conf import settings
from django.contrib import messages
from django.shortcuts import render, get_object_or_404, redirect
from django.contrib.admin.views.decorators import staff_member_required
from django.contrib.auth import logout
from .models import SystemInfo, Employees

def logout_view(request):
    logout(request)
    return redirect('admin:login')

@staff_member_required(login_url='admin:login')
def computers_list(request):
    
    if request.method == 'POST':
        
        # Action via button to delete a PC
        if 'delete_mac' in request.POST:
            mac_to_delete = request.POST.get('delete_mac')
            pc = get_object_or_404(SystemInfo, mac_address=mac_to_delete)
            pc.delete()
            return redirect('computers_list')
        
        # Action via form to create an employee
        elif 'add_employee' in request.POST:
            first_name = request.POST.get('first_name')
            last_name = request.POST.get('last_name')
            
            if first_name and last_name:
                Employees.objects.create(first_name=first_name, last_name=last_name)
                messages.success(request, f"[OK] L'employé {first_name} {last_name} a été ajouté.")
            else:
                messages.error(request, "[ERREUR] Veuillez remplir le nom et le prénom.")
                
            return redirect('computers_list')
        
        # Assign an employee to a PC
        elif 'assign_employee' in request.POST:
            mac_address = request.POST.get('mac_address')
            employees_id = request.POST.get('employees_id')
            
            pc = get_object_or_404(SystemInfo, mac_address=mac_address)
            
            if employees_id:
                employees = get_object_or_404(Employees, id=employees_id)
                pc.employees = employees
                messages.success(request, f"[OK] {employees.first_name} a été assigné au PC {pc.mac_address}.")
            else:
                pc.employees = None
                messages.success(request, f"[OK] L'assignation a été retirée pour le PC {pc.mac_address}.")
                
            pc.save()
            return redirect('computers_list')

    computers = SystemInfo.objects.all()
    employees = Employees.objects.all()
    return render(request, 'list.html', {'computers': computers, 'employees': employees})

@staff_member_required(login_url='admin:login')
def show_info(request, mac_address):
    
    # Object that fetch the system informations via SystemInfo in models.py linked to the mac adress asked, if no return = 404
    computer_info = get_object_or_404(SystemInfo, mac_address=mac_address)
    
    # Return the requested object in item.html by using the keyword "data"
    return render(request, 'item.html', {'data': computer_info})

@staff_member_required(login_url='admin:login')
def deploy_ssh(request):
    if request.method == 'POST':
        target = request.POST.get('target')
        username = request.POST.get('username')
        password = request.POST.get('password')
        
        try:
            # 1. Init SSH connection via paramiko
            ssh = paramiko.SSHClient()
            ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
            ssh.connect(hostname=target, username=username, password=password, timeout=5)
            
            # 2. Send Alfred in temp path
            sftp = ssh.open_sftp()
            local_path = os.path.join(settings.BASE_DIR, './lib/alfred.run')
            remote_path = '/tmp/alfred.run'
            sftp.put(local_path, remote_path)
            sftp.close()
            
            # 3. Execution
            server = request.get_host()  # Fetch actual server address for Alfred
            token = settings.SESSION_TOKEN
            
            formula = f"chmod +x /tmp/alfred.run && /tmp/alfred.run {server} {token} && rm /tmp/alfred.run"
            
            stdin, stdout, stderr = ssh.exec_command(formula)
            
            # Wait for finish then close communication
            exit_status = stdout.channel.recv_exit_status()
            ssh.close()
            
            if exit_status == 0:
                messages.success(request, f"[OK] Alfred has successfully fetched from {target} !")
            else:
                error_output = stderr.read().decode('utf-8')
                messages.error(request, f"[ERROR] {error_output}")
                
        except Exception as e:
            messages.error(request, f"[ERROR] Impossible to connect at {target}: {str(e)}")
            
    return redirect('computers_list')
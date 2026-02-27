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

    computers = SystemInfo.objects.all()
    employees = Employees.objects.all()
    return render(request, 'list.html', {'computers': computers, 'employees': employees})

def manage_employees(request):

    if request.method == 'POST':
        
        if 'add_employee' in request.POST:
            first_name = request.POST.get('first_name')
            last_name = request.POST.get('last_name')
            email = request.POST.get('email') 
            
            if first_name and last_name:
                Employees.objects.create(first_name=first_name, last_name=last_name, email=email)
                messages.success(request, f"[OK] L'employé {first_name} {last_name} a été ajouté.")

        elif 'edit_employee' in request.POST:
            emp_id = request.POST.get('employee_id')
            first_name = request.POST.get('first_name')
            last_name = request.POST.get('last_name')
            emp = get_object_or_404(Employees, id=emp_id)
            
            if first_name and last_name:
                emp.first_name = first_name
                emp.last_name = last_name
                emp.save()
                messages.success(request, f"[OK] L'employé {first_name} {last_name} a été mis à jour.")

        elif 'delete_employee' in request.POST:
            emp_id = request.POST.get('employee_id')
            emp = get_object_or_404(Employees, id=emp_id)
            nom_complet = f"{emp.first_name} {emp.last_name}"
            emp.delete()
            messages.success(request, f"[OK] L'employé {nom_complet} a été supprimé.")

    return redirect(request.META.get('HTTP_REFERER', 'computers_list'))


@staff_member_required(login_url='admin:login')
def update_admin(request):
    if request.method == 'POST':
        user = request.user
        new_username = request.POST.get('new_username')
        new_password = request.POST.get('new_password')

        new_timezone = request.POST.get('timezone')
        if new_timezone:
            request.session['django_timezone'] = new_timezone
        
        if new_username:
            user.username = new_username
            
        password_changed = False
        if new_password:
            user.set_password(new_password)
            password_changed = True
            
        user.save()
        
        if password_changed:
            update_session_auth_hash(request, user)
            messages.success(request, "[OK] Identifiant et mot de passe mis à jour avec succès !")
        else:
            messages.success(request, "[OK] Identifiant mis à jour avec succès !")
            
    return redirect(request.META.get('HTTP_REFERER', 'computers_list'))

@staff_member_required(login_url='admin:login')
def show_info(request, mac_address):
    
    if request.method == 'POST' and 'assign_employee' in request.POST:
        employees_id = request.POST.get('employees_id')
        pc = get_object_or_404(SystemInfo, mac_address=mac_address)
        
        if employees_id:
            employee = get_object_or_404(Employees, id=employees_id)
            pc.employees = employee
            messages.success(request, f"[OK] L'ordinateur a été assigné à {employee.first_name} {employee.last_name}.")
        else:
            pc.employees = None
            messages.success(request, "[OK] L'assignation a été retirée pour cet ordinateur.")
            
        pc.save()
        return redirect(request.META.get('HTTP_REFERER', 'computers_list'))

    # Object that fetch the system informations via SystemInfo in models.py linked to the mac adress asked, if no return = 404
    computer_info = get_object_or_404(SystemInfo, mac_address=mac_address)
    employees = Employees.objects.all()
    
    # Return the requested object in item.html by using the keyword "data"
    return render(request, 'item.html', {'data': computer_info, 'employees': employees})

@staff_member_required(login_url='admin:login')
def deploy_ssh(request):
    if request.method == 'POST':
        target = request.POST.get('target')
        username = request.POST.get('username')
        password = request.POST.get('password')
        
        try:
            ssh = paramiko.SSHClient()
            ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
            
            key_path = os.path.join(settings.BASE_DIR, 'keys', 'id_ed25519')
            pub_key_path = key_path + '.pub'
            
            if not os.path.exists(key_path):
                messages.error(request, "[ERROR] Clé SSH introuvable. Relancez grabber.sh pour configurer une clé.")
                return redirect('computers_list')
                
            connected_with_key = False
            
            # If key available
            try:
                ssh.connect(hostname=target, username=username, key_filename=key_path, timeout=5)
                connected_with_key = True
            except paramiko.AuthenticationException:
                pass 
                    
            # Else, use pswd and install public key
            if not connected_with_key:
                if not password:
                    messages.error(request, "[ERROR] Nouveau PC : vous devez fournir un mot de passe pour le premier déploiement ! (clé refusée)")
                    return redirect('computers_list')
                    
                ssh.connect(hostname=target, username=username, password=password, timeout=5)
                
                if os.path.exists(pub_key_path):
                    with open(pub_key_path, 'r') as f:
                        pub_key = f.read().strip()
                    setup_key_cmd = f"mkdir -p ~/.ssh && chmod 700 ~/.ssh && echo '{pub_key}' >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
                    ssh.exec_command(setup_key_cmd)

            # Deploy Alfred
            sftp = ssh.open_sftp()
            local_path = os.path.join(settings.BASE_DIR, './lib/alfred.run')
            remote_path = '/tmp/alfred.run'
            sftp.put(local_path, remote_path)
            sftp.close()
            
            server = request.get_host()
            token = settings.SESSION_TOKEN
            
            formula = f"chmod +x /tmp/alfred.run && /tmp/alfred.run {server} {token} && rm /tmp/alfred.run"
            stdin, stdout, stderr = ssh.exec_command(formula)
            exit_status = stdout.channel.recv_exit_status()
            ssh.close()
            
            if exit_status == 0:
                msg = f"[OK] Alfred a été déployé avec succès sur {target} !"
                if not connected_with_key:
                    msg += " (Clé SSH installée)."
                messages.success(request, msg)
            else:
                messages.error(request, f"[ERROR] {stderr.read().decode('utf-8')}")
                
        except Exception as e:
            messages.error(request, f"[ERROR] Connexion impossible à {target}: {str(e)}")
            
    return redirect('computers_list')
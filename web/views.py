import os
import paramiko
from django.conf import settings
from django.contrib import messages
from django.shortcuts import render, get_object_or_404, redirect
from django.contrib.admin.views.decorators import staff_member_required
from django.contrib.auth import logout, update_session_auth_hash
from django.utils.translation import gettext as _
from django.utils import translation
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

def manage_employees(request):

    if request.method == 'POST':
        
        if 'add_employee' in request.POST:
            first_name = request.POST.get('first_name')
            last_name = request.POST.get('last_name')
            email = request.POST.get('email') 
            
            if first_name and last_name:
                Employees.objects.create(first_name=first_name, last_name=last_name, email=email)
                messages.success(request, _("[OK] Employee {first_name} {last_name} has been added.").format(first_name=first_name, last_name=last_name))

        elif 'edit_employee' in request.POST:
            emp_id = request.POST.get('employee_id')
            first_name = request.POST.get('first_name')
            last_name = request.POST.get('last_name')
            emp = get_object_or_404(Employees, id=emp_id)
            
            if first_name and last_name:
                emp.first_name = first_name
                emp.last_name = last_name
                emp.save()
                messages.success(request, _("[OK] Employee {first_name} {last_name} has been updated.").format(first_name=first_name, last_name=last_name))

        elif 'delete_employee' in request.POST:
            emp_id = request.POST.get('employee_id')
            emp = get_object_or_404(Employees, id=emp_id)
            nom_complet = f"{emp.first_name} {emp.last_name}"
            emp.delete()
            messages.success(request, _("[OK] Employee {nom_complet} has been deleted.").format(nom_complet=nom_complet))

    return redirect(request.META.get('HTTP_REFERER', 'computers_list'))


@staff_member_required(login_url='admin:login')
def update_admin(request):
    if request.method == 'POST':
        user = request.user
        new_username = request.POST.get('new_username')
        new_password = request.POST.get('new_password')
        
        # Récupération des nouveaux paramètres
        new_timezone = request.POST.get('timezone')
        new_language = request.POST.get('language')

        # 1. Sauvegarde du Fuseau horaire (Toujours géré par la session)
        if new_timezone:
            request.session['django_timezone'] = new_timezone
        
        # 2. Sauvegarde du compte utilisateur
        if new_username:
            user.username = new_username
            
        password_changed = False
        if new_password:
            user.set_password(new_password)
            password_changed = True
            
        user.save()
        
        if password_changed:
            update_session_auth_hash(request, user)
            messages.success(request, _("[OK] Username and password updated successfully!"))
        else:
            messages.success(request, _("[OK] Settings updated successfully!")) 
            
        # --- NOUVEAU : On prépare d'abord la redirection (la réponse) ---
        response = redirect(request.META.get('HTTP_REFERER', 'computers_list'))
        
        # 3. Sauvegarde de la Langue via Cookie (Nouvelle norme Django 4.0+)
        if new_language:
            translation.activate(new_language)
            # On attache le cookie de langue directement à la réponse
            response.set_cookie(settings.LANGUAGE_COOKIE_NAME, new_language)
            
        return response # On retourne la réponse modifiée
            
    return redirect(request.META.get('HTTP_REFERER', 'computers_list'))

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
                messages.error(request, _("[ERROR] SSH key not found. Rerun grabber.sh to configure a key."))
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
                    messages.error(request, _("[ERROR] New PC: you must provide a password for the first deployment! (key refused)"))
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
                msg = _("[OK] Alfred has been successfully deployed on {target}!").format(target=target)
                if not connected_with_key:
                    msg += _(" (SSH key installed).")
                messages.success(request, msg)
            else:
                messages.error(request, f"[ERROR] {stderr.read().decode('utf-8')}")
                
        except Exception as e:
            messages.error(request, _("[ERROR] Unable to connect to {target}: {error}").format(target=target, error=str(e)))
            
    return redirect('computers_list')
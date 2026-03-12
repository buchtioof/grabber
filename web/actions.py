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

##### LOGOUT #####
def disconnect(request):
    logout(request)
    return redirect('admin:login')

##### DEPLOYMENT ACTION #####
@staff_member_required(login_url='admin:login')
def deploy_ssh(request):

    if request.method == 'POST':
        target = request.POST.get('target')
        username = request.POST.get('username')
        password = request.POST.get('password')
        
        try:
            # Init SSH & check keys
            ssh = paramiko.SSHClient()
            ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
            
            key_path = os.path.join(settings.BASE_DIR, 'keys', 'id_ed25519')
            pub_key_path = key_path + '.pub'
            
            if not os.path.exists(key_path):
                messages.error(request, _("[ERROR] SSH key not found. Rerun grabber.sh to configure a key."))
                return redirect('computers_list')
                
            connected_with_key = False
            
            # Use key authentification
            try:
                ssh.connect(hostname=target, username=username, key_filename=key_path, timeout=5)
                connected_with_key = True
            except paramiko.AuthenticationException:
                pass 
                    
            # If no key found, use credentials then install key
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

            # Upload payload via SFTP
            sftp = ssh.open_sftp()
            local_path = os.path.join(settings.BASE_DIR, './lib/alfred.run')
            remote_path = '/tmp/alfred.run'
            sftp.put(local_path, remote_path)
            sftp.close()
            
            # Execute Alfred and cleanup
            server = request.get_host()
            token = settings.SESSION_TOKEN
            
            formula = f"chmod +x /tmp/alfred.run && /tmp/alfred.run {server} {token} && rm /tmp/alfred.run"
            stdin, stdout, stderr = ssh.exec_command(formula)
            exit_status = stdout.channel.recv_exit_status()
            ssh.close()
            
            # Results
            if exit_status == 0:
                msg = _("[OK] Alfred has been successfully deployed on {target}!").format(target=target)
                if not connected_with_key:
                    msg += _(" (SSH key installed).")
                messages.success(request, msg)
            else:
                messages.error(request, f"[ERROR] {stderr.read().decode('utf-8')}")
                
        except Exception as e:
            # Catch global errors
            messages.error(request, _("[ERROR] Unable to connect to {target}: {error}").format(target=target, error=str(e)))
            
    return redirect('computers_list')

##### SETTINGS ACTIONS #####
# Employees management
@staff_member_required(login_url='admin:login')
def emp_settings(request):

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
                emp_name = f"{emp.first_name} {emp.last_name}"
                emp.save()
                messages.success(request, _("[OK] Employee {emp_name} has been updated.").format(emp_name=emp_name))

        elif 'delete_employee' in request.POST:
            emp_id = request.POST.get('employee_id')
            emp = get_object_or_404(Employees, id=emp_id)
            emp_name = f"{emp.first_name} {emp.last_name}"
            emp.delete()
            messages.success(request, _("[OK] Employee {emp_name} has been deleted.").format(emp_name=emp_name))

    return redirect(request.META.get('HTTP_REFERER', 'computers_list'))

# Settings management
@staff_member_required(login_url='admin:login')
def user_settings(request):
    if request.method == 'POST':
        user = request.user
        new_username = request.POST.get('new_username')
        new_password = request.POST.get('new_password')
        new_timezone = request.POST.get('timezone')
        new_language = request.POST.get('language')
        
        # User editing settings
        user_updated = False

        ## Verify if Username changed and is not already used
        if new_username and new_username != user.username:
            user.username = new_username
            user_updated = True
        
        ## Verify if Password changed
        if new_password:
            user.set_password(new_password)
            user_updated = True
        
        if user_updated: # note: in "user_updated:" the two points mean TRUE as if user_updated TRUE
            try:
                user.save()
                if new_password:
                    update_session_auth_hash(request, user)
                
                messages.success(request, _("[OK] Profile updated successfully!"))

            except IntegrityError:
                messages.error(request, _("[ERROR] This username is already taken."))
                return redirect(request.META.get('HTTP_REFERER', 'computers_list'))

        # Region settings
        tz_updated = False
        lang_updated = False
        response = redirect(request.META.get('HTTP_REFERER', 'computers_list'))

        ## Verify if TZ changed
        if new_timezone:
            request.session['django_timezone'] = new_timezone
            tz_updated = True
        
        ## Verify if Language changed
        if new_language:
            translation.activate(new_language)
            response.set_cookie(settings.LANGUAGE_COOKIE_NAME, new_language)
            lang_updated = True
        
        if tz_updated:
            messages.success(request, _("[OK] Timezone updated successfully!"))
        if lang_updated:
            messages.success(request, _("[OK] Language updated successfully!"))
            
        return response
            
    return redirect(request.META.get('HTTP_REFERER', 'computers_list'))
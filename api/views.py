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

def manage_employees(request):
    """
    Vue dédiée uniquement à la gestion des employés (Ajout, Modification, Suppression).
    Elle ne retourne pas de template HTML, elle redirige juste d'où l'utilisateur vient.
    """
    if request.method == 'POST':
        
        # 1. AJOUTER UN EMPLOYÉ
        if 'add_employee' in request.POST:
            first_name = request.POST.get('first_name')
            last_name = request.POST.get('last_name')
            # On récupère l'email depuis le HTML
            email = request.POST.get('email') 
            
            if first_name and last_name:
                # On l'injecte lors de la création en base de données
                Employees.objects.create(first_name=first_name, last_name=last_name, email=email)
                messages.success(request, f"[OK] L'employé {first_name} {last_name} a été ajouté.")

        # 2. MODIFIER UN EMPLOYÉ
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

        # 3. SUPPRIMER UN EMPLOYÉ
        elif 'delete_employee' in request.POST:
            emp_id = request.POST.get('employee_id')
            emp = get_object_or_404(Employees, id=emp_id)
            nom_complet = f"{emp.first_name} {emp.last_name}"
            emp.delete()
            messages.success(request, f"[OK] L'employé {nom_complet} a été supprimé.")

    # Dans tous les cas, on renvoie l'utilisateur sur la page sur laquelle il se trouvait
    return redirect(request.META.get('HTTP_REFERER', 'computers_list'))


@staff_member_required(login_url='admin:login')
def update_admin(request):
    if request.method == 'POST':
        user = request.user
        new_username = request.POST.get('new_username')
        new_password = request.POST.get('new_password')
        
        # 1. Mise à jour du nom d'utilisateur (si fourni)
        if new_username:
            user.username = new_username
            
        # 2. Mise à jour du mot de passe (uniquement si le champ n'est pas vide)
        password_changed = False
        if new_password:
            # set_password hashe automatiquement le mot de passe (ne jamais faire user.password = ...)
            user.set_password(new_password)
            password_changed = True
            
        # 3. Sauvegarde en base de données
        user.save()
        
        # 4. Maintien de la session si le mot de passe a changé
        if password_changed:
            update_session_auth_hash(request, user)
            messages.success(request, "[OK] Identifiant et mot de passe mis à jour avec succès !")
        else:
            messages.success(request, "[OK] Identifiant mis à jour avec succès !")
            
    # Redirige l'utilisateur vers la page d'où il vient (pratique car la modale est dans base.html)
    return redirect(request.META.get('HTTP_REFERER', 'computers_list'))

@staff_member_required(login_url='admin:login')
def show_info(request, mac_address):
    
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
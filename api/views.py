import json
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.shortcuts import render, get_object_or_404
from .models import SystemInfo

@csrf_exempt

# Function launching the model module SystemInfo and parse JSON data in SQL
def receive_system_info(request):
    
    if request.method == 'POST': # Check if the HTTP can receive data

        try:
            # Load JSON data and separate HW and SW
            data = json.loads(request.body)
            hw = data.get('HARDWARE', {})
            sw = data.get('SOFTWARE', {})
            
            # Check MAC adress
            mac = sw.get('mac_address')
            if not mac or mac == "Unknown-MAC":
                return JsonResponse({'error': 'MAC address is required'}, status=400)

            # Use Django module update or create that add or update itself data in SQL
            obj, created = SystemInfo.objects.update_or_create(
                mac_address=mac, # For that MAC adress PC
                defaults={ # Add his content
                    'motherboard': hw.get('motherboard'),
                    'cpu_model': hw.get('cpu_model'),
                    'cpu_id': hw.get('cpu_id'),
                    'cpu_cores': hw.get('cpu_cores'),
                    'cpu_threads': hw.get('cpu_threads'),
                    'cpu_frequency_min': hw.get('cpu_frequency_min'),
                    'cpu_frequency_cur': hw.get('cpu_frequency_cur'),
                    'cpu_frequency_max': hw.get('cpu_frequency_max'),
                    'gpu_model': hw.get('gpu_model'),
                    'ram_slots': hw.get('ram_slots'),
                    'ram_total': hw.get('ram_total'),
                    'total_storage': hw.get('total_storage'),
                    'hostname': sw.get('hostname'),
                    'os': sw.get('os'),
                    'arch': sw.get('arch'),
                    'desktop_env': sw.get('desktop_env'),
                    'window_manager': sw.get('window_manager'),
                    'kernel': sw.get('kernel'),
                }
            )
            
            status_msg = "created" if created else "updated"
            return JsonResponse({'message': f'System info {status_msg} successfully!'}, status=200)

        except json.JSONDecodeError:
            return JsonResponse({'error': 'Invalid JSON format'}, status=400)
        except Exception as e:
            return JsonResponse({'error': str(e)}, status=500)

    return JsonResponse({'error': 'Only POST method is allowed'}, status=405)

def computers_list(request):
    
    # Fetch all the computers in the SystemInfo parser
    computers = SystemInfo.objects.all()
    
    # Send each computers in the template "list.html"
    return render(request, 'list.html', {'computers': computers})

def show_info(request, mac_address):
    
    # Object that fetch the system informations via SystemInfo in models.py linked to the mac adress asked, if no return = 404
    computer_info = get_object_or_404(SystemInfo, mac_address=mac_address)
    
    # Return the requested object in item.html by using the keyword "data"
    return render(request, 'item.html', {'data': computer_info})
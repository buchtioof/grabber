from django.conf import settings

def version_processor(request):
    return {
        'grabber_version': settings.GRABBER_VERSION,
        'motor_used': settings.MOTOR_USED,
    }
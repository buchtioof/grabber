#!/usr/bin/python3
import configparser
import requests
class ordinateur():
    mb_serial = " "
    cpu_model = " "
    cpu_id = " "
    cpu_cores_number = " "
    cpu_threads_number = " "
    cpu_frequency_min = " "
    cpu_frequency_cur = " "
    cpu_frequency_max = " "
    gpu_model = " "
    ram_size = " "
    ram_slots_number = " "
    ram_number = " "
    ram_gen = " "

    os = " "
    arch = " "
    desktop = " "
    wm = " "
    kernel = " "
    def __init__(self):
        self.reload()
    def reload(self):
        r = requests.get("http://localhost:8000/summary.txt")
        r.raise_for_status()
        print(type(r.content.decode("utf-8")))
        sum = configparser.ConfigParser()
        sum.read_string(r.content.decode("utf-8"))
        # sum.read("/opt/grabber/summary.txt")
        if "MB_SERIAL" in sum['HARDWARE']:
            self.mb_serial=sum['HARDWARE']['MB_SERIAL']
        if "CHASSIS_SERIAL" in sum['HARDWARE']:
            self.chassis_serial=sum['HARDWARE']['CHASSIS_SERIAL']
        if "CPU" in sum['HARDWARE']:
            self.cpu=sum['HARDWARE']['CPU']
        if "CPU_ID" in sum['HARDWARE']:
            self.cpu_id=sum['HARDWARE']['CPU_ID']
        if "CPU_CORES_NUMBER" in sum['HARDWARE']:
            self.cpu_cores_number=sum['HARDWARE']['CPU_CORES_NUMBER']
        if "CPU_THREADS_NUMBER" in sum['HARDWARE']:
            self.cpu_threads_number=sum['HARDWARE']['CPU_THREADS_NUMBER']
        if "CPU_FREQUENCY_MIN" in sum['HARDWARE']:
            self.cpu_frequency_min=sum['HARDWARE']['CPU_FREQUENCY_MIN']
        if "CPU_FREQUENCY_CUR" in sum['HARDWARE']:
            self.cpu_frequency_cur=sum['HARDWARE']['CPU_FREQUENCY_CUR']
        if "CPU_FREQUENCY_MAX" in sum['HARDWARE']:
            self.cpu_frequency_max=sum['HARDWARE']['CPU_FREQUENCY_MAX']
        if "GPU_MODEL" in sum['HARDWARE']:
            self.gpu_model=sum['HARDWARE']['GPU_MODEL']
        if "RAM_SLOTS_NUMBER" in sum['HARDWARE']:
            self.ram_slots_number=sum['HARDWARE']['RAM_SLOTS_NUMBER']
        if "RAM_NUMBER" in sum['HARDWARE']:
            self.ram_number=sum['HARDWARE']['RAM_NUMBER']
        if "RAM_GEN" in sum['HARDWARE']:
            self.ram_gen=sum['HARDWARE']['RAM_GEN']
        return
    def fetch_summary(self):
        return
    def shutdown():
        return
    def status(self):
        return
    def link_to_user(self,user):
        return
    def remove_user_access(self):
        return
    def show_users(self):
        return

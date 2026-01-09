#!/usr/bin/python3
import configparser

class ordinateur():
    mb_serial=" "
    cpu_model=" "
    cpu_id=" "
    cpu_cores_number=" "
    cpu_threads_number=" "
    cpu_frequency_min=" "
    cpu_frequency_cur=" "
    cpu_frequency_max=" "
    gpu_model=" "
    ram_slots_number=" "
    ram_number=" "
    ram_gen=" "

    os=" "
    architecture=" "
    desktop=" "
    window_manager=" "
    kernel=" "

    def reload(self):
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

sum=configparser.ConfigParser()
sum.read("/opt/grabber/summary.txt")
sum.sections

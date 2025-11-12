#!/bin/bash
DIR=/opt/grabber

echo "================" | tee -a /dev/stderr
echo "Début de grabber" | tee -a /dev/stderr
echo "================" | tee -a /dev/stderr

echo "================" | tee -a /dev/stderr
echo "Périphériques USB" | tee -a /dev/stderr
echo "================" | tee -a /dev/stderr
echo "Commande lsusb:" | tee -a /dev/stderr

lsusb 1> $DIR/lsusb.cmd
#cat /etc/passwd > $DIR/passwd.file
#cat /etc/group > $DIR/group.file
#uptime > $DIR/uptime.cmd
#lsblk > $DIR/lsblk.cmd
#lspci -nn > $DIR/lspci.cmd
#systemd-analyze > $DIR/systemd-analyze.cmd
#systemd-analyze blame | head -n 10 > $DIR/systemd-blame.cmd
#lsmem > $DIR/lsmem.cmd
#lscpu > $DIR/lscpu.cmd
#inxi > $DIR/inxi.cmd
#lshw > $DIR/lshw.cmd
#free > $DIR/free.cmd
#arch > $DIR/arch.cmd

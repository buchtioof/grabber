#!/bin/bash

DIR=/opt/grabber
SUCCESS_LOG=/var/log/grabber-success.log
ERROR_LOG=/var/log/grabber-error.log

tee $SUCCESS_LOG $ERROR_LOG <<EOF1
++++++++++++++++
Début de grabber
++++++++++++++++
================
Récupération des informations sur les paquets
================
EOF1


#Fichier /etc/apt/sources.list
tee -a $SUCCESS_LOG $ERROR_LOG <<EOF2
================
Copie du fichier de configuration /etc/apt/sources.list
================
EOF2

cat /etc/apt/sources.list 2> >(tee -a $ERROR_LOG) > $DIR/sources-list.file

tee -a $SUCCESS_LOG $ERROR_LOG <<EOF3
================
Récupération de la liste des paquets installés
================
EOF3

apt list --installed 2> >(tee -a $ERROR_LOG) > $DIR/apt-installed.cmd \
	&& echo "[OK]: Fichier apt-installed.cmd généré" > tee -a $SUCCES_LOG \
	|| echo "[ECHEC]: Erreur à la génération de apt-installed.cmd" > tee -a $ERROR_LOG


tee -a $SUCCESS_LOG $ERROR_LOG <<EOF4
================
Liste des périphériques USB
================
EOF4

lsusb 2> >(tee -a $ERROR_LOG) > $DIR/lsusb.cmd \
	&& echo "[OK]: Fichier lsusb.cmd généré" > tee -a $SUCCES_LOG \
	|| echo "[ECHEC]: Erreur à la génération de lsusb.cmd" > tee -a $ERROR_LOG

tee -a $SUCCESS_LOG $ERROR_LOG <<EOF5
================
Informations sur le processeur
================
EOF5

lscpu 2> >(tee -a $ERROR_LOG) > $DIR/lscpu.cmd \
	&& echo "[OK]: Fichier lscpu.cmd généré" > tee -a $SUCCES_LOG \
	|| echo "[ECHEC]: Erreur à la génération de lscpu.cmd" > tee -a $ERROR_LOG

tee -a $SUCCESS_LOG $ERROR_LOG <<EOF6
================
Liste des groupes
================
EOF6

cat /etc/group 2> >(tee -a $ERROR_LOG) > $DIR/group.file \
	&& echo "[OK]: Fichier group.file généré" > tee -a $SUCCES_LOG \
	|| echo "[ECHEC]: Erreur à la génération de group.file" > tee -a $ERROR_LOG

tee -a $SUCCESS_LOG $ERROR_LOG <<EOF7
================
Liste des utilisateurs
================
EOF7

cat /etc/passwd 2> >(tee -a $ERROR_LOG) > $DIR/passwd.file \
	&& echo "[OK]: Fichier passwd.file généré" > tee -a $SUCCES_LOG \
	|| echo "[ECHEC]: Erreur à la génération de passwd.file" > tee -a $ERROR_LOG

tee -a $SUCCESS_LOG $ERROR_LOG <<EOF8
================
Informations mémoire
================
EOF8

lsmem 2> >(tee -a $ERROR_LOG) > $DIR/lsmem.cmd \
	&& echo "[OK]: Fichier lsmem.cmd généré" > tee -a $SUCCES_LOG \
	|| echo "[ECHEC]: Erreur à la génération de lsmem.cmd" > tee -a $ERROR_LOG

tee -a $SUCCESS_LOG $ERROR_LOG <<EOF9
================
Liste du matériel
================
EOF9

lspci 2> >(tee -a $ERROR_LOG) > $DIR/lspci.cmd \
	&& echo "[OK]: Fichier lspci.cmd généré" > tee -a $SUCCES_LOG \
	|| echo "[ECHEC]: Erreur à la génération de lspci.cmd" > tee -a $ERROR_LOG

tee -a $SUCCESS_LOG $ERROR_LOG <<EOF10
================
Information démarrage services
================
EOF10

systemd-analyze 2> >(tee -a $ERROR_LOG) > $DIR/systemd-analyze.cmd \
	&& echo "[OK]: Fichier systemd-analyze.cmd généré" > tee -a $SUCCES_LOG \
	|| echo "[ECHEC]: Erreur à la génération de systemd-analyze.cmd" > tee -a $ERROR_LOG

tee -a $SUCCESS_LOG $ERROR_LOG <<EOF11
================
Performances démarrage services
================
EOF11

systemd-analyze blame 2> >(tee -a $ERROR_LOG) > $DIR/systemd-blame.cmd \
	&& echo "[OK]: Fichier systemd-analyze.cmd généré" > tee -a $SUCCES_LOG \
	|| echo "[ECHEC]: Erreur à la génération de systemd-analyze.cmd" > tee -a $ERROR_LOG

tee -a $SUCCESS_LOG $ERROR_LOG <<EOF12
================
Liste des réseaux
================
EOF12

cat /etc/network/interfaces 2> >(tee -a $ERROR_LOG) > $DIR/etc-network-interfaces.file \
	&& echo "[OK]: Fichier etc-network-interfaces.file généré" > tee -a $SUCCES_LOG \
	|| echo "[ECHEC]: Erreur à la génération de etc-network-interfaces.file" > tee -a $ERROR_LOG

tee -a $SUCCESS_LOG $ERROR_LOG <<EOF13
================
Disques et Partitions
================
EOF13

lsblk 2> >(tee -a $ERROR_LOG) > $DIR/lsblk.cmd \
	&& echo "[OK]: Fichier lsblk.cmd généré" > tee -a $SUCCES_LOG \
	|| echo "[ECHEC]: Erreur à la génération de lsblk.cmd" > tee -a $ERROR_LOG

tee -a $SUCCESS_LOG $ERROR_LOG <<EOF14
================
Configuration DNS
================
EOF14

cat /etc/resolv.conf 2> >(tee -a $ERROR_LOG) > $DIR/etc-resolv-conf.file \
	&& echo "[OK]: Fichier etc-resolv-conf.file généré" > tee -a $SUCCES_LOG \
	|| echo "[ECHEC]: Erreur à la génération de etc-resolv-conf.file" > tee -a $ERROR_LOG


declare -a DEVICES
mapfile -t DEVICES < <(lsblk -dn -o NAME |grep -v loop)

declare -A FILES

FILES=(
    "sources_list.file" "/etc/apt/sources.list*"
    "passwd.file" "/etc/passwd" 
    "group.file" "/etc/group"
    "/etc-network-interfaces.file" "/etc/network/interfaces"
    "/etc-resolv-conf.file" "/etc/resolv.conf"
)

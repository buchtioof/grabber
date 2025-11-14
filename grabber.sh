# Définition des variables
DIR=/opt/grabber
SUCCESS_LOG=/var/log/grabber/grabber-success.log
ERROR_LOG=/var/log/grabber/grabber-error.log

# Affichage du texte de démarrage
tee $SUCCESS_LOG $ERROR_LOG <<EOF1
++++++++++++++++++++++++
Démarrage du script Grabber
++++++++++++++++++++++++
========================
Récupération des informations sur les paquets
========================
EOF1

# Fichier /etc/apt/sources.list

tee $SUCCESS_LOG $ERROR_LOG <<EOF2
---------------------------------------------
Copie du fichier de configuration /etc/apt/sources.list
-------------------
EOF2
cat /etc/apt/sources.list 2> >(tee -a $ERROR_LOG) > sources-list.file

# Commande apt-list --installed

tee -a $SUCCESS_LOG $ERROR_LOG <<EOF3
---------------------------------------------
Récupération de la liste de paquets installés
-------------------
EOF3

apt list --installed 2> >(tee -a $ERROR_LOG) > apt-installed.cmd \
	&& echo "[OK]: Fichier apt -installed.cmd généré" | tee -a $SUCCESS_LOG \
	|| echo "[ECHEC]: Erreur à la génération de apt-installed.cmd" | tee -a $ERROR_LOG

#lsusb 1> $DIR/lsusb.cmd
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

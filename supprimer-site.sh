#!/bin/bash
#########################################################################################
## @auteur : Thierry                                                                   ##
## @date : 10 octobre 2006                                                             ##
## @version : 0.1                                                                      ##
## @contact : blog.titax.fr                                                            ##
## -------------                                                                       ##
## Permet de:                                                                          ##
## >> Supprime un compte user avec sa home directory /home/$user                       ##
## Supprime le site web sous www                                                       ##
## >> Suppression d'une base MySql                                                     ##
#########################################################################################

#variables
#votre password mysql
passmysql="votre_pass"

# petit nettoyage d'écran
clear

# seul root peux exécuter ce script
if test `id -u` != "0"; then
     echo "Vous devez etre root pour executer ce script, désolé..."
else


echo "################################## Suppression d'utilisateur"
# recuperation des parametres
echo -n "Entrez le compte à supprimer : ";
read login;

# --- Suppression du user ---

/usr/sbin/userdel $login

echo -e " + Suppression de l'utilisateur : $login     [  \E[32;40m\033[1mOK\033[0m  ]"

echo -n "Voulez vous supprimer le repertoire dans /home? (o/[n]) ";
read home
if [ _$home != _o -a _$home != _O ]
then
     echo "le repertoire dans /home ne sera pas effacé"
else

# --- Suppression du repertoire /var/www/nom_du_compte ---
        rm -rf /home/$login/

echo -e " + Suppression du repertoire /www            [  \E[32;40m\033[1mOK\033[0m  ]"
fi

echo -n "Voulez vous supprimer la configuration vhost (o/[n]) ";
read www
if [ _$www != _o -a _$www != _O ]
then
     echo "la configuration vhost ne sera pas effacée"
else

# --- Suppression du virtual host---

rm -f /etc/httpd/conf/vhosts/$login.conf

echo -e " + Suppression du VirtualHost : $login       [  \E[32;40m\033[1mOK\033[0m  ]"
fi

echo -n "Voulez vous supprimer la base de donnée (o/[n]) ";
read base
if [ _$base != _o -a _$base != _O ]
then
     echo "la base de donnée ne sera pas effacée"
else

# --- Suppression de la base de donnée et de l'utilisateur---

        mysql -u root --password=$passmysql mysql <<END_COMMANDS

        REVOKE ALL ON *.* FROM $login@localhost;

        REVOKE ALL ON $login.* FROM $login@localhost;

        DELETE FROM mysql.user WHERE user='$login';

        DROP DATABASE IF EXISTS $login;

        FLUSH PRIVILEGES;

END_COMMANDS

/usr/bin/mysqladmin -u root -p"$passmysql" reload

fi

#On recharge la configuration de apache

service httpd restart

#c'est fini !!!!
echo -e " + Suppression totale de  $login             [  \E[32;40m\033[1mOK\033[0m  ]"
fi

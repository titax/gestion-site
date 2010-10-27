#!/bin/bash
#########################################################################################
## @auteur :      Thierry                                                              ##
## @date :        10 octobre 2006                                                      ##
## @version :     0.2                                                                  ##
## @contact : blog.titax.fr                                                                       ##
##                                -------------                                        ##
## Permet de:                                                                          ##
## >>   Creer un compte user avec sa home directory /home/$user                        ##
##	Site accessible en www (www.domaine.com pointe vers /home/$user/www            ##
##	Alias illimites (ex: linux.domaine.com pointe vers /home/u$ser/linux           ##
## >> Creation d'une base MySql                                                        ##
#########################################################################################
#quelques variables
log="/var/log/creation-$login-`date +%d-%m-%Y`.log"
touch $log
group="users"
# petit nettoyage d'ecran
clear

# seul root peux executer ce script
if test `id -u` != "0"; then
     echo "il faut etre root pour executer ce script"
else

echo "################################## Creation d'utilisateur"
# on recupere les parametres du compte
echo -n "Entrez le compte a creer : ";
read login;

echo -n "Entrez son mot de passe : ";
read password;
passmysql=$password

echo -n "Entrez le nom de domaine (sans \"www\", par exemple domaine.com) : ";
read domaine;

# on demande confirmation de ces parametres
echo "
Domaine  : $domaine
Compte   : $login
Passwd   : $password
" >> $log
echo -n "Est- ce correct ? (o/[n]) "
read ans
if [ _$ans != _o -a _$ans != _O ]
then
     echo "la creation du compte a ete annulee">> $log
fi

# creation du compte utilisateur sauf si existe deja
/usr/sbin/useradd $login -p `perl -e "print crypt('$password',pwet)"` -g $group -d /home/$login -m -s /bin/bash
if [ $? -ne 0 ]
	then
	echo "L'utilisateur $login existe deja!" >> $log
fi
echo -e " + Utilisateur \"$login\"                                   [  \E[32;40m\033[1mOK\033[0m  ]"
# creation et droits sur les repertoires
/bin/mkdir /home/$login/logs /home/$login/www /home/$login/cgi-bin
echo -e " + Creation repertoires                                     [  \E[32;40m\033[1mOK\033[0m  ]"

# modifications des droits sur les dossiers
chown -R $login.$group /home/$login/
echo -e " + Modification des droits                                  [  \E[32;40m\033[1mOK\033[0m  ]"

# creation du virtual host (inclus dans httpd.conf)
echo "
<VirtualHost *:80>
        ServerName $domaine
        DocumentRoot /home/$login/www/
        ErrorLog /home/$login/logs/error.log
        CustomLog /home/$login/logs/access.log combined
        ScriptAlias /cgi-bin/ /home/$login/cgi-bin/
        <Directory /home/$login/www/>
                AllowOverride All
                Options -Indexes +ExecCGI
                Order Deny,Allow
                Allow from all
        </Directory>
</VirtualHost>

" > /etc/httpd/conf/vhosts/$login.conf
echo -e " + VirtualHost Apache                                       [  \E[32;40m\033[1mOK\033[0m  ]"
echo "################################## Termine "

# creation de la base de donnee mysql
echo -n "Faut-il installer une base de donnee mySQL ? (o/[n]) "
read ans
if [ _$ans = _o -o _$ans = _O ]
then
echo "################################## Creation de la base MySql "
	echo -n "Entrez le password root mysql :";
	read passroot;

	# creation de la base
	/usr/bin/mysqladmin -u root -p$passroot create $login
echo -e "Base MySQL \"$login\"                                       [  \E[32;40m\033[1mOK\033[0m  ]"

	# creation du compte + db + droits
	/usr/bin/mysql -u root --password=$passroot mysql <<END_COMMANDS
#	GRANT ALL PRIVILEGES ON $login.* TO "$login"@"localhost" IDENTIFIED BY '$passmysql';
        GRANT ALL PRIVILEGES ON \`$login\`.* TO "$login"@"localhost" IDENTIFIED BY '$passmysql';
	FLUSH PRIVILEGES;
END_COMMANDS

	# redemarrage de la base
	/usr/bin/mysqladmin -u root -p$passroot reload
	echo -e "User MySQL \"$login\" [  \E[32;40m\033[1mOK\033[0m  ]"
else
	echo "Choix: Base non creee">> $log
fi
echo "################################## Termine "

echo "Creation du nouvel utilisateur \"$login\" terminee."
service httpd restart
echo "relance de Apache"
fi
# fin du script

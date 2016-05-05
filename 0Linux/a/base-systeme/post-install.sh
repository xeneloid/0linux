
# Si l'on dispose de Busybox (il vaudrait mieux, soit dit en passant) :
if [ -x /usr/bin/busybox ]; then
	BUSYBOXBIN="/usr/bin/busybox"
fi

# On tente de migrer depuis l'ancienne structure :
rm -f usr/lib 2>/dev/null || true # Cette commande échouera sur un répertoire ;)

# On s'assure de la présence des liens symboliques critiques :
# Si '/usr/lib' est un répertoire, on est dans le cas du x86_64 multilib :
if [ -d usr/lib ]; then
	[ -e libARCH ] || ${BUSYBOXBIN} ln -sf usr/libARCH libARCH
	[ -e lib ] || ${BUSYBOXBIN} ln -sf usr/lib lib
else
	[ -e lib ] || ${BUSYBOXBIN} ln -sf usr/lib lib
	[ -e usr/lib ] || ${BUSYBOXBIN} ln -sf libARCH usr/lib || true # Si LIBDIRSUFFIX est vide
fi

# On crée des liens standards pour les binaires :
[ -e bin ] || ${BUSYBOXBIN} ln -sf usr/bin bin
[ -e sbin ] || ${BUSYBOXBIN} ln -sf usr/sbin sbin

# Création/vérification des utilisateurs et groupes du système.
# Syntaxe : champs séparés par des deux-points « : », le tout entre double-guillemets :
# Dans basegid : nom:GID
# Dans baseuid : nom:UID:GID:Description de l'utilisateur:répertoire dédié:shell

basegid=(
		"root:0"
		"bin:1"
		"daemon:2"
		"sys:3"
		"adm:4"
		"tty:5"
		"disk:6"
		"lp:7"
		"mem:8"
		"kmem:9"
		"wheel:10"
		"floppy:11"
		"mail:12"
		"news:13"
		"uucp:14"
		"man:15"
		"dialout:16"
		"audio:17"
		"video:18"
		"cdrom:19"
		"games:20"
		"slocate:21"
		"utmp:22"
		"tape:23"
		"smmsp:25"
		"polkit:26"
		"mysql:27"
		"rpc:32"
		"sshd:33"
		"kdm:41"
		"gdm:42"
		"shadow:43"
		"avahi:44"
		"tor:45"
		"privoxy:46"
		"ftp:50"
		"oprofile:51"
		"lock:54"
		"tomcat:66"
		"dovenull:74"
		"dovecot:76"
		"apache:80"
		"dbus:81"
		"plugdev:83"
		"power:84"
		"netdev:86"
		"sudo:88"
		"pop:90"
		"scanner:93"
		"input:97"
		"nogroup:99"
		"users:100"
		"console:101"
		"polkitd:102"
		"colord:108"
		"gdm:120"
		"vboxusers:215"
		)

baseuid=(
		"root:0:0:Super Utilisateur:/root:/bin/bash"
		"bin:1:1:Utilisateur bin:/usr/bin:/usr/bin/false"
		"daemon:2:2:Utilisateur daemon:/usr/sbin:/usr/bin/false"
		"adm:3:4:Utilisateur adm:/var/log:/usr/bin/false"
		"lp:4:7:Utilisateur impression lp:/var/spool/lpd:/usr/bin/false"
		"sync:5:0:Utilisateur sync:/usr/bin:/usr/bin/sync"
		"shutdown:6:0:Utilisateur shutdown:/usr/sbin:/usr/sbin/shutdown"
		"halt:7:0:Utilisateur halt:/usr/sbin:/usr/sbin/halt"
		"mail:8:12:Utilisateur mail:/:/usr/bin/false"
		"news:9:13:Utilisateur news:/usr/lib/news:/usr/bin/false"
		"uucp:10:14:Utilisateur uucp:/var/spool/uucppublic:/usr/bin/false"
		"operator:11:0:Utilisateur operator:/root:/usr/bin/bash"
		"games:12:100:Utilisateur des jeux:/usr/share/games:/usr/bin/false"
		"ftp:14:50:Utilisateur FTP:/home/ftp:/usr/bin/false"
		"smmsp:25:25:Utilisateur smmsp:/var/spool/clientmqueue:/usr/bin/false"
		"polkit:26:26:Utilisateur PolKit:/:/usr/bin/false"
		"mysql:27:27:Utilisateur MySQL:/var/lib/mysql:/usr/bin/false"
		"rpc:32:32:Utilisateur RPC:/:/usr/bin/false"
		"sshd:33:33:Utilisateur du démon SSH:/:/usr/bin/false"
		"kdm:41:41:Utilisateur KDM:/var/lib/kdm:/usr/bin/false"
		"gdm:42:42:Utilisateur GDM:/var/state/gdm:/usr/bin/false"
		"avahi:44:44:Utilisateur Avahi:/dev/null:/usr/bin/false"
		"tor:45:45:Utilisateur Tor:/var/lib/tor:/usr/bin/false"
		"privoxy:46:46:Utilisateur Privoxy:/var/spool/privoxy:/bin/false"
		"oprofile:51:51:Utilisateur oprofile:/usr/bin:/usr/bin/false"
		"tomcat:66:66:Utilisateur Tomcat:/var/lib/tomcat:/usr/bin/false"
		"dovenull:74:74:Utiliateur non fiable pour dovecot:/var/empty:/usr/bin/false"
		"dovecot:76:76:Utiliateur dovecot:/var/empty:/usr/bin/false"
		"apache:80:80:Utilisateur Apache httpd:/srv/httpd:/usr/bin/false"
		"messagebus:81:81:Utilisateur dbus:/run/dbus:/usr/bin/false"
		"pop:90:90:Utilisateur POP:/:/usr/bin/false"
		"nobody:99:99:Utilisateur fictif nobody:/:/usr/bin/false"
		"polkitd:102:102:Utilisateur Policy Kit:/var/lib/polkit:/usr/bin/false"
		"colord:108:108:Utilisateur pour colord:/:/usr/bin/false"
		"gdm:120:120:Utilisateur GNOME GDM:/var/lib/gdm:/usr/bin/false"
		"vboxadd:215:215:Utilisateur VirtualBox:/:/usr/bin/false"
		"vboxweb:240:215:Utilisateur VirtualBox (Web):/var/lib/vboxweb:/usr/bin/false"
		"pulse:216:17:PulseAudio:/:/usr/bin/false"
		)

# On s'assure de la présence de ces fichiers critiques :
touch etc/{group,passwd}

# Pour chaque ligne du tableau des groupes :
for ((i = 0; i < ${#basegid[@]}; i++)); do
	champgroupe=$(echo "${basegid[$i]}" | awk -F ":" '{ print $1 }')
	champgid=$(echo "${basegid[$i]}" | awk -F ":" '{ print $2 }')
	
	if [ ! "$(grep -E "^${champgroupe}:" etc/group)" = "" ]; then
		
		# Le groupe existe, on le corrige (même s'il est correct) :
		chroot . groupmod -g ${champgid} -n ${champgroupe} ${champgroupe} 2>/dev/null
	
	elif [ ! "$(grep ":x:${champgid}:" etc/group)" = "" ]; then
		
		# Le groupe existe mais sous un autre nom, on le corrige :
		anciengroupe="$(grep ":x:${champgid}:" etc/group | awk -F ":" '{ print $3 }')"
		chroot . groupmod -g ${champgid} -n ${champgroupe} ${anciengroupe} 2>/dev/null
	else
		
		# Le groupe n'existe pas, on le crée :
		chroot . groupadd -g ${champgid} ${champgroupe} 2>/dev/null
	fi
done

# Pour chaque ligne du tableau des comptes utilisateur :
for ((i = 0; i < ${#baseuid[@]}; i++)); do
	
	# On vérifie que 6 champs sont identifiables, sinon on quitte :
	valide="$(echo "${baseuid[$i]}" | awk -F ":" 'NF != 6 { print "ERREUR : 6 champs séparés par des DEUX-POINTS « : » sont requis. Or il y a "NF" champs dans \""$0"\"" }')"
	
	if [ ! "$(echo ${valide} | grep ERREUR)" = "" ];then
		echo ${valide}
		exit 1
	fi
	
	champnom=$(echo "${baseuid[$i]}" | awk -F ":" '{ print $1 }')
	champuid=$(echo "${baseuid[$i]}" | awk -F ":" '{ print $2 }')
	champgid=$(echo "${baseuid[$i]}" | awk -F ":" '{ print $3 }')
	champdesc=$(echo "${baseuid[$i]}" | awk -F ":" '{ print $4 }')
	champhome=$(echo "${baseuid[$i]}" | awk -F ":" '{ print $5 }')
	champshell=$(echo "${baseuid[$i]}" | awk -F ":" '{ print $6 }')
	
	# Si le compte utilisateur existe :
	if [ ! "$(grep -E "^${champnom}:" etc/passwd)" = "" ]; then
	
		# Le groupe qu'on veut lui attribuer existe-t-il ?
		if [ ! "$(grep ":x:${champgid}:" etc/group)" = "" ]; then
			
			# Le groupe existe, on peut modifier le compte :
			chroot . usermod -s ${champshell} -c "${champdesc}" -d ${champhome} -u ${champuid} -g ${champgid} ${champnom} 2>/dev/null
		fi
	
	# Si le compte utilisateur n'existe pas :
	else
		# Le groupe qu'on veut lui attribuer existe-t-il ?
		if [ ! "$(grep ":x:${champgid}:" etc/group)" = "" ]; then
			
			# Le groupe existe, on peut créer le compte :
			chroot . useradd -s ${champshell} -c "${champdesc}" -d ${champhome} -u ${champuid} -g ${champgid} -r ${champnom} 2>/dev/null
		fi
	fi
done

# On s'assure que '/var/run' et '/var/lock' pointent bien sur '/run', quitte à
# déplacer des fichiers : :
if [ ! -L var/run ] && [ -d var/run ]; then
	${BUSYBOXBIN} cp -ar var/run/* run/
	${BUSYBOXBIN} rm -rf var/{lock,run}
	${BUSYBOXBIN} ln -sf ../run var/
	${BUSYBOXBIN} ln -sf ../run/lock var/
fi

# On force la création du lien symbolique 'mtab' vers '/proc/mounts' :
[ -f etc/mtab ] && rm -f etc/mtab
ln -sf ../proc/mounts etc/mtab

# On s'assure que les utilisateurs disposent de leur '~/.bash_profile' pour charger
# le contenuu de '.bashrc' :
for d in $(find home -maxdepth 0 -type d 2>/dev/null); do
	if [ ! -e ${d}/.bash_profile ] ; then
		cp -a etc/skel/.bash_profile ${d}/
	fi
done

# On s'assure des permissions :
chown root.utmp run/utmp* var/log/wtmp* >/dev/null 2>&1
chmod 664 run/utmp* >/dev/null 2>&1
chown root.shadow etc/shadow* etc/gshadow* >/dev/null 2>&1
chgrp ftp srv/ftp >/dev/null 2>&1
chgrp games var/games >/dev/null 2>&1

# Les fonctions de traitement des fichiers '*.0nouveau' et des fichiers
# services, normalement appelées dans creer_post_installation() :
traiter_nouvelle_config() {
	NEW="$1"
	OLD="$(dirname $NEW)/$(basename $NEW .0nouveau)"
	
	if [ ! -r $OLD ]; then
		mv $NEW $OLD >/dev/null 2>&1 || busybox mv $NEW $OLD >/dev/null 2>&1 || true
	elif [ "$(diff -abBEiw $OLD $NEW)" = "" ]; then
		mv $NEW $OLD >/dev/null 2>&1 || busybox mv $NEW $OLD >/dev/null 2>&1 || true
	fi
}

traiter_service() {
	NEWSVCFILE="$1"
	OLDSVCFILE="$(dirname $NEWSVCFILE)/$(basename $NEWSVCFILE .0nouveauservice)"
	
	if [ -e ${OLDSVCFILE} ]; then
		
		# On copie temporairement le service déjà installé en préservant les permissions :
		cp -a ${OLDSVCFILE}{,.tmp} || busybox cp -a ${OLDSVCFILE}{,.tmp} || true
		
		# On injecte le contenu du nouveau fichier service dans le temporaire (qui a les bonnes permissions) :
		cat ${NEWSVCFILE} > ${OLDSVCFILE}.tmp || busybox cat ${NEWSVCFILE} > ${OLDSVCFILE}.tmp || true
		
		# On renomme le temporaire pour écraser l'ancien, les permissions sont alors OK :
		mv ${OLDSVCFILE}{.tmp,} >/dev/null 2>&1 || busybox mv ${OLDSVCFILE}{.tmp,} >/dev/null 2>&1 || true
		
		# On supprime le '.0nouveauservice' ('rm -f' dans BusyBox a un comportement parfois différent) :
		rm -f ${NEWSVCFILE} || busybox rm ${NEWSVCFILE} >/dev/null 2>&1 || true
	else
		# Si l'ancien n'existe pas, on renomme d'office le '.0nouveauservice' :
		mv ${NEWSVCFILE} ${OLDSVCFILE}
	fi
}

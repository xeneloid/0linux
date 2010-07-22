#!/bin/env bash
# On nettoie avant toute chose :
rm -f $TMP/choix_swap $TMP/ignorer_swap

# Si aucune swap n'est détectée :
if [ listeswap = "" ]; then
	noswapfound
	
	# Si l'utilisateur ne veut pas continuer :
	if [ "$?" = "1" ]; then
		abortswap
	# Si l'utilisateur ne veut pas de swap :
	else
		touch $TMP/ignorer_swap
	fi
	
	exit

# Si l'on trouve une ou plusieurs swaps :
else
	# On détecte les tailles des swaps et on en retire une liste à afficher :
	for partitionswap in $LISTESWAP ; do
		TAILLEPART=$(taille_partition $partitionswap)
		tempswap >> $TMP/temp_swap
	done
	
	swapselect 2> $TMP/selection_swap
	
	# En cas de problème, on quitte et on ignore la config' de la swap :
	if [ ! $? = 0 ]; then
		rm -f $TMP/temp_swap $TMP/choix_swap $TMP/selection_swap
		touch $TMP/ignorer_swap
	fi
	
	if [ -r $TMP/selection_swap ]; then
		# On supprime les éventuels guillemets :
		cat $TMP/selection_swap | tr -d \" > $TMP/selection_swap
		
		# Si aucune swap n'a été spécifiée, on ignore l'étape :
		if [ "$(cat $TMP/selection_swap)" = "" -a ! -r $TMP/ignorer_swap ]; then
			rm -f $TMP/temp_swap $TMP/choix_swap $TMP/selection_swap
			touch $TMP/ignorer_swap
		fi
	fi
	
	# On crée et on active la ou les swaps avec 'mkswap' et 'swapon' :
	for partitionswap in $(cat $TMP/selection_swap) ; do
		mkswap -v1 $partitionswap 1> $REDIR 2> $REDIR
		swapon $partitionswap 1> $REDIR 2> $REDIR
	done
	
	# Ce qui suit permet d'éviter à l'écran de clignoter :
	sleep 2
	
	# On ajoute maintenant les infos qui iront dans '/etc/fstab' :
	for pswap in $(cat $TMP/selection_swap) ; do
		echo "$pswap     swap         swap       defaults           0     0" >> $TMP/choix_swap
	done
	
	# On affiche les infos qui iront dans '/etc/fstab' à l'utilisateur :
	swapconfigured
	
fi

# C'est fini !

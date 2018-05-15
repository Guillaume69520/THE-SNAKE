#!/bin/bash

#Noeud = corp du serpent (des zéros 0000 de base)

perdue=(
    '                                                      '
    '                       AÏE !!!                        '
    '                                                      '
    '                   Score:                             '
    '          Appuyer sur Q pour Quitter                  '
    '          Appuyer sur n pour une nouvelle partie      '                                                     
);

jeux=(
    '                                                          '
    '                ~~~ THE S N A K E ~~~                     '
    '                                                          '
    '          Auteurs : Maxime, Mathieu, Guillaume            '
    '             Espace ou entrer  Joue / Pause               '
    '                  q   Quitter le jeu                      '
    '           Appuyer sur Entrer pour commencer !!           '
    '  Skin Or pour Deux parties consécutives gagnées (80 pts) '
);

gagne=(                                                                           
    '                                                      '
    '                      Bravo !!!                       '
    '                                                      '
    '                   Score:                             '
    '          Appuyer sur Q pour Quitter                  '
    '          Appuyer sur n pour une nouvelle partie      ' 
);

quitter() {  #Fonction pour  Quitter le Jeu 
    stty echo;  #echo de récupération (affichage sur le shell après jeu)
    tput rmcup; #Ecran de récupération
    tput cvvis; #Curseur de récupération
    exit 0; #fin du programme
}

interface() {         # Dessine les bordures de l'interface  $1=longueur cadre -1 $2= largeur
    clear; # clear de l'interface
    color="\e[33m*\e[0m";  #couleur autour 33 = jaune et motif *
    for (( i = 0; i < $1; i++ )); do   #dessin des latéaux du cadre
        echo -ne "\033[$i;0H${color}";  #coutour de gauche  
        echo -ne "\033[$i;$2H${color}"; #contour de droite
    done
    

    for (( i = 0; i <= $2; i++ )); do   #dessin cadre haut et bas
        echo -ne "\033[0;${i}H${color}"; #haut
        echo -ne "\033[$1;${i}H${color}"; #bas
    done
   
    vitesse 0;    #affichage de la vitesse sur l'interface
    echo -ne "\033[$Lines;$((yscore-10))H\e[36mScore:  0\e[0m"; #affichage du score en bas
    echo -ne "\033[$Lines;$((Cols-80))H\e[33mPause Espace/Entrer\e[0m";
     [ -f ./skin.txt  ] && echo -ne "\033[$Lines;$((Cols-30))H\e[33m Skill : OR!!! \e[0m" || echo -ne "\033[$Lines;$((Cols-30))H\e[33m Skill : Aucun... \e[0m";
     
}

initialisation() {
    Lines=`tput lines`; Cols=`tput cols`;     # Longueur / Largeur écran
    xline=$((Lines/2));                       #Position de départ  
    xscore=$Lines;      yscore=$((Cols/2));   #Imprimer position du score
    xcent=$xline;       ycent=$yscore;        #Emplacement point central
    xrand=0;            yrand=0;              #Point aléatoire
    sumscore=0;         liveflag=1;           #Score total + drapeau présence de point
    sumnode=0;          foodscore=0;          #Longueur totale des noeuds et des points à augmenter
    byebyeetoile=0;     byebyemalus=0;
    byebyetortue=0;
    snake="0000 ";                            #Initialisation du serpent
    pos=(right right right right right);      #Direction noeud de départ
    xpt=($xline $xline $xline $xline $xline); #Coordonnée x de départ de chaque noeud  Horizontal
    ypt=(5 4 3 2 1);                          #Coordonné y de départ de chaque noeud Vertical
    speed=(0.02 0.1 0.15);  spk=${spk:-2};    #Vitesse par défaut
    xtab=(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0);  #initialisation des tableaux de position des malus
    ytab=(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0);
    interface $((Lines-1)) $Cols  #passage des arguments de position d'écran à interface
}

dessiner_murs(){
	
	lvl1fstwallpos=$2/4
	lvl1scndwallpos=$2/4*3
	lvl1walllength=$Lines/2
	lvl2wallpos=$2/2
	lvl2walllength=$Lines/4

	color="\e[33m*\e[0m";
	if [ "$1" == "lvl1" ];then 

		for (( i = 0; i < $lvl1walllength; i++ )); do
			echo -ne "\033[$i;$((lvl1fstwallpos))H${color}";
		done
		
		for (( i = $lvl1walllength; i < $Lines; i++ )); do
			echo -ne "\033[$i;$((lvl1scndwallpos))H${color}";
		done

	elif [ "$1" == "lvl2" ];then
		for (( i = 0; i < $lvl2walllength; i++)); do	
			echo -ne "\033[$i;$((lvl2wallpos))H${color}";
		done
	
		for (( i = 3*$lvl2walllength; i < $Lines; i++)); do	
			echo -ne "\033[$i;$((lvl2wallpos))H${color}";
		done
	fi

}



pause() {              
    echo -en "\033[$Lines;$((Cols-80))H\e[33mJeu en pause !  Entrer ou Espace\e[0m";
    while read -n 1 space; do  #while pour arrter la boucle principale tant que le user n'a pas appuyer sur entrer
        [[ ${space:-enter} = enter ]] && \
            echo -en "\033[$Lines;$((Cols-80))H\e[33m Pause ? Espace / Entrer           \e[0m" && return;
        [[ ${space:-enter} = q ]] && quitter;
    done
}

# $1=Emplacement du noeud
maj() {                     #Mise à jour des coordonnées de chacuns des noeuds
    case ${pos[$1]} in
        right) ((ypt[$1]++));;
         left) ((ypt[$1]--));;
         down) ((xpt[$1]++));;
           up) ((xpt[$1]--));;
    esac
}

vitesse() {                #Gestion de la vitesse / mise à jour

     case $spk in
         0) temp="Ferrari";;
         1) temp="Golf" ;;
         2) temp="Clio   ";;
     esac
     echo -ne "\033[$Lines;3H\e[33mVitesse: $temp\e[0m"; #affichage écran
}

Direction() {                                   #Mise à jour de la direction
    case ${key:-enter} in
        k) [[ ${pos[0]} != "up"    ]] && pos[0]="down";;        #gestion des auto-collisions
        i) [[ ${pos[0]} != "down"  ]] && pos[0]="up";;          #ex: si on appuie sur haut si le serpet descend...
        j) [[ ${pos[0]} != "right" ]] && pos[0]="left";;
        l) [[ ${pos[0]} != "left"  ]] && pos[0]="right";;
        q|Q) quitter;;
      enter) pause;;
    esac
}

ajout_noeud() {  #Ajouter des noeuds au serpent
    

    snake="0$snake";  #ajout d'un zéro
    pos=(${pos[0]} ${pos[@]});
    xpt=(${xpt[0]} ${xpt[@]});
    ypt=(${ypt[0]} ${ypt[@]});
    maj 0;  #mise à jour des positions des noeuds

    local x=${xpt[0]} y=${ypt[0]}
    (( ((x>=$((Lines-1)))) || ((x<=1)) || ((y>=Cols)) || ((y<=1)) )) && return 1; # Collision avec le mur

    for (( i = $((${#snake}-1)); i > 0; i-- )); do
        (( ${xpt[0]} == ${xpt[$i]} && ${ypt[0]} == ${ypt[$i]} )) && return 1; #crash du serpent
    done 
     
     [ -f ./skin.txt  ] &&  echo -ne "\033[${xpt[0]};${ypt[0]}H\e[33m${snake[@]:0:1}\e[0m" || echo -ne "\033[${xpt[0]};${ypt[0]}H\e[32m${snake[@]:0:1}\e[0m";  
    
 

    return 0;
}

affichage_malus(){   #on affiche les malus (calcul aléatoires des positions)

    for ((i=0; i<35;i++)); do           #35 = nombres de malus
    	xtab[$i]="$((RANDOM%(Lines-3)+2))"
    done
    
    for ((j=0; j<35;j++)); do
    	ytab[$j]="$((RANDOM%(Cols-2)+2))"
    done

   for ((k=0; k<35;k++)); do  #affichage en fonction des positions calculées précedemment
    	echo -ne "\033[${xtab[$k]};${ytab[$k]}H\e[31mO\e[0m";
    done
}

disparition_malus(){

	for ((l=0; l<35;l++)); do

    		echo -ne "\033[${xtab[$l]};${ytab[$l]}H\e[30mO\e[0m"; 

   	       done
}

malus(){  #gestion temps d'apparition malus + gestion collision

if ((byebyemalus>0)); then
    	    ((byebyemalus--))
    	 
    	 else
    	  
    	  disparition_malus;
          liveflag=1;   	 
 fi

 	 for ((m=0; m<35;m++)); do #test de toutes les positions des malus pour voiri si collision

 	 	if (( x==${xtab[$m]} && y==${ytab[$m]} )); then

    		 liveflag=1; 

    		 if (($sumscore>0)); then

    		 sumscore=$(($sumscore/2));

    		fi

    		for ((t=0;t<10;t++)); do

    			ajout_noeud;
    		done

    		disparition_malus;
    	fi
   	 done  
}

aleatoire() {       
                        #Génération points et nombres aléatoires
    xrand=$((RANDOM%(Lines-3)+2));
    yrand=$((RANDOM%(Cols-2)+2));
    foodscore=$((RANDOM%13+1)); #generer entre 1 et 13
   
    #si foodscore est supérieur à 9 alors on entre dans des cas particulier (bonus ou malus)

    if ((foodscore>9)); then

		 ((foodscore==10)) && echo -ne "\033[$xrand;${yrand}H\e[33m★\e[0m";
		 ((foodscore==10)) && ((spk==2)) && byebyeetoile=100;
		 ((foodscore==10)) && ((spk==1)) && byebyeetoile=150;
		 ((foodscore==10)) && ((spk==0)) && byebyeetoile=200;
		 ((foodscore==11)) && echo -ne "\033[$xrand;${yrand}H\e[33m🐢\e[0m";
		 ((foodscore==11)) && ((spk==2)) && byebyetortue=100;
		 ((foodscore==11)) && ((spk==1)) && byebyetortue=150;
		 ((foodscore==11)) && ((spk==0)) && byebyetortue=200;
		
	     #12 et 13 = malus !
		 ((foodscore==12)) && affichage_malus && byebyemalus=400;
		 ((foodscore==13)) && affichage_malus && byebyemalus=400;

		else
		 echo -ne "\033[$xrand;${yrand}H$foodscore";  
    fi

    liveflag=0;                                      #passage à 0 pour éviter de générer encore si le point n'est pas manger par le serpent
}

evolution_vitesse(){  #évolution de la vitesse en fonction du score

        (($sumscore <=4 )) && spk=2 && vitesse;   #clio
        (($sumscore > 5)) && spk=1 && vitesse;    #Golf
        (($sumscore > 15)) && spk=0 && vitesse;   #ferrari
        }
 
bonus_etoile(){ #après un certains temps supprime l'étoile bonus

	if ((byebyeetoile>0)); then
    	    ((byebyeetoile--))
    	 else
    	  echo -ne "\033[$xrand;${yrand}H\e[30m★\e[0m"
    	  liveflag=1;
    	fi
    	(( x==xrand && y==yrand )) && ((liveflag=1)) && ((sumscore+=20));  #colision avec le bonus on ajoute 20 points + liveflag à 1 pour nouveau nombre
}

 bonus_vitesse(){ #rend le serpent moins rapide pendant un petit moment

 	if ((byebyetortue>0)); then
    	    ((byebyetortue--))
    	 else
    	  echo -ne "\033[$xrand;${yrand}H\e[30m🐢\e[0m"
    	  liveflag=1;
    	fi
    	(( x==xrand && y==yrand )) && ((liveflag=1)) && slow=100;

 }

nouvelle_partie() {      

    initialisation;
    while true; do   #boucle principale

    	if ((slow>0)); then  #si bonus actif on réduit la vitesse et quand slow=0 on revient à la normal

    		spk=2 && vitesse;
    		((slow--));

    	else
           evolution_vitesse; 

        fi

        read -t ${speed[$spk]} -n 1 key; #lecture touche
        [[ $? -eq 0 ]] && Direction; #si pas d'erreur on actualise la position

        ((liveflag==0)) || aleatoire; #si liveflag 0 on générer un nouveau foodscore

        if (( sumnode > 0 )); then
            ((sumnode--));   # on décrémente jusqu'à zéro pour ajouter les noeud un par un 
             ajout_noeud; 
             (($?==0)) || return 1; #si erreur on sort de la boucle
        else
            maj 0; 
            [ -f ./skin.txt  ] && echo -ne "\033[${xpt[0]};${ypt[0]}H\e[33m${snake[@]:0:1}\e[0m" || echo -ne "\033[${xpt[0]};${ypt[0]}H\e[32m${snake[@]:0:1}\e[0m";   

            for (( i = $((${#snake}-1)); i > 0; i-- )); do
                maj $i;
                 [ -f ./skin.txt  ] && echo -ne "\033[${xpt[$i]};${ypt[$i]}H\e[33m${snake[@]:$i:1}\e[0m" || echo -ne "\033[${xpt[$i]};${ypt[$i]}H\e[32m${snake[@]:$i:1}\e[0m";    

                (( ${xpt[0]} == ${xpt[$i]} && ${ypt[0]} == ${ypt[$i]} )) && return 1; #crash
                [[ ${pos[$((i-1))]} = ${pos[$i]} ]] || pos[$i]=${pos[$((i-1))]};
            done
        
        fi
    

        local x=${xpt[0]} y=${ypt[0]}
        (( ((x>=$((Lines-1)))) || ((x<=1)) || ((y>=Cols)) || ((y<=1)) )) && return 1; #collsion mur
	
	if ((sumscore>=10));then
		dessiner_murs lvl1 $Cols;
		(( ((x<=$((Lines-2))/2)) && ((y==$lvl1fstwallpos)) )) && return 1; 
		(( ((x>$((Lines-2))/2)) && ((y==$lvl1scndwallpos)) )) && return 1;
	fi       	
	if ((sumscore>=15));then
		dessiner_murs lvl2 $Cols;
		(( ((x<=$((Lines-2))/4)) && ((y==$lvl2wallpos)) )) && return 1; 
		(( ((x>=$((Lines-2))/4*3)) && ((y==$lvl2wallpos)) )) && return 1; 
	fi	

	
	if ((foodscore>9)); then
		 	((foodscore==10)) && bonus_etoile;
			((foodscore==11)) && bonus_vitesse;
			((foodscore==12)) && malus;
			((foodscore==13)) && malus;
		 
		else
			(( x==xrand && y==yrand )) && ((liveflag=1)) && ((sumnode+=foodscore)) && ((sumscore+=foodscore)); #collision avec le score donc liveflag à 1 pour générer un nouveau nombre / sumnode += foodscore pour ajouter les noeuds et ajout du score
		 	
    	fi

        echo -ne "\033[$xscore;$((yscore-2))H$sumscore"; #affichage du nouveau score

        (($sumscore>80)) && return 1;   #si on fait 80 points on sort de la boucle principale on va a affichage qui s'occupera d'imprimer "Gagne"
        
    done
}

affichage() {
    local x=$((xcent-4)) y=$((ycent-25))
    
	if (($sumscore>80)); then       #si on gagne                                   
	
		for (( i = 0; i < 8; i++ )); do
			echo -ne "\033[$((x+i));${y}H\e[45m${gagne[$i]}\e[0m";
		done
	else
	
		for (( i = 0; i < 8; i++ )); do  #si on perd affiche de fin
			echo -ne "\033[$((x+i));${y}H\e[45m${perdue[$i]}\e[0m";
		done
	
	fi

    echo -ne "\033[$((x+3));$((ycent+1))H\e[45m${sumscore}\e[0m"; #affichage du score écran de fin /gagne
       
}

sauvegarde(){

        [ ! -f "./sauvegarde.txt" ] && touch sauvegarde.txt;  #vérifier si le fichier existe 
    
        nbpartie=$(grep Score ./sauvegarde.txt | wc -l)  #calcul nombre de parties

        (($sumscore>50)) &&  echo "Score de la partie numéro "$nbpartie ":" $sumscore "Bravo" >> sauvegarde.txt || echo "Score de la partie numéro "$nbpartie ":" $sumscore >> sauvegarde.txt  #affichage score dans sauvegarde.txt

        if (($nbpartie > 0)); then

        nextscore=$(($nbpartie+1))

        first_bravo=$(awk 'NR == '$nbpartie' {print $9}' ./sauvegarde.txt)   #récupère le premier bravo
        second_bravo=$(awk 'NR == '$nextscore' {print $9}' ./sauvegarde.txt)   #récupère le deuxième bravo

        
        [[ $first_bravo == "Bravo" ]] && [[ $second_bravo == "Bravo" ]] && echo "OR" >> skin.txt;    #si deux bravo donc deux parties consécutives gagnées on créer skills.txt
        
        fi
}

serpent() {
    
    initialisation; #mise en place du plateau de jeu / init variables

    local x=$((xcent-5)) y=$((ycent-25))
    for (( i = 0; i < 10; i++ )); do
        echo -ne "\033[$((x+i));${y}H\e[45m${jeux[$i]}\e[0m"; #ecran de depart
    done

    while read -n 1 anykey; do 
        [[ ${anykey:-enter} = enter ]] && break; #enter on commence le jeu
        [[ ${anykey:-enter} = q ]] && quitter; #pour quitter 
    done
    
    while true; do
    
        nouvelle_partie; 
        sauvegarde; #sauvegarde fin de partie
        affichage; #affichage fin de jeu
	
        while read -n 1 anykey; do
            [[ $anykey = n ]] && break;
            [[ $anykey = q ]] && quitter;
        done
    done
}

menu() {
    trap 'quitter;' SIGTERM SIGINT; 
    stty -echo;                               #Annuler l'écho (remis à la fin du jeu)
    tput civis;                               #Masquer le curseur
    tput smcup; clear;                        #Enregistrer puis effacer l'écran

    serpent;                         #Démarrage du jeu 
}

menu;  #c'est partie !!!

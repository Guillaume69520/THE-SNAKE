#!/bin/bash

#Noeud = corp du serpent (des zéros)

perdue=(
    '                                                      '
    '                       AÏE !!!                        '
    '                                                      '
    '                   Score:                             '
    '          Appuyer sur Q pour Quitter                  '
    '          Appuyer sur n pour une nouvelle partie      '
    '          Appuyer sur s pour changer la vitesse       '
    '                                                      '
);

jeux=(
    '                                                   '
    '                ~~~ THE S N A K E ~~~              '
    '                                                   '
    '          Auteurs : Maxime, Mathieu, Guillaume     '
    '           Espace ou entrer  Joue / Pause          '
    '               q   Quitter le jeu                  '
    '               s changer la vitesse                '
    '                                                   '
    '         Appuyer sur Entrer pour commencer !!      '
    '                                                   '
);

quitter() {  #Fonction pour  Quitter le Jeu 
    stty echo;  #echo de récupération (affichage sur le shell après jeu)
    tput rmcup; #Ecran de récupération
    tput cvvis; #Curseur de récupération
    exit 0;
}

interface() {         # Dessine les bordures de l'interface  $1=longueur cadre -1 $2= largeur
    clear; # clear de l'interface
    color="\e[33m*\e[0m";  #couleur autour 33 = jaune
    for (( i = 0; i < $1; i++ )); do   #dessin des latéaux du cadre
        echo -ne "\033[$i;0H${color}";  #coutour de gauche
        echo -ne "\033[$i;$2H${color}"; #contour de droite
    done

    for (( i = 0; i <= $2; i++ )); do   #dessin cadre haut et bas
        echo -ne "\033[0;${i}H${color}"; #haut
        echo -ne "\033[$1;${i}H${color}"; #bas
    done

    vitesse 0; #affichage de la vitesse sur l'interface
    echo -ne "\033[$Lines;$((yscore-10))H\e[36mScores: 0\e[0m"; #affichage du score en bas
    echo -ne "\033[$Lines;$((Cols-50))H\e[33mPause Espace/Entrer\e[0m";
}

initialisation() {
    Lines=`tput lines`; Cols=`tput cols`;     #	Longueur / Largeur écran
    xline=$((Lines/2)); ycols=4;              #Position de départ  Utilité du ycols ???
    xscore=$Lines;      yscore=$((Cols/2));   #Imprimer position du score
    xcent=$xline;       ycent=$yscore;        #Emplacement point central
    xrand=0;            yrand=0;              #Point aléatoire
    sumscore=0;         liveflag=1;           #Score total + drapeau présence de point
    sumnode=0;          foodscore=0;          #Longueur totale des noeuds et des points à augmenter
    
    snake="OOOO ";                            #Initialisation du serpent
    pos=(right right right right right);      #Direction noeud de départ
    xpt=($xline $xline $xline $xline $xline); #Coordonnée x de départ de chaque noeud  Horizontal
    ypt=(5 4 3 2 1);                          #Coordonné y de départ de chaque noeud Vertical
    speed=(0.02 0.1 0.15);  spk=${spk:-1};    #Vitesse par défaut

    interface $((Lines-1)) $Cols  #passage des arguments de position d'écran à interface
}

pause() {               #Jeu de rôle
    echo -en "\033[$Lines;$((Cols-50))H\e[33mJeu en pause !  Entrer ou Espace\e[0m";
    while read -n 1 space; do
        [[ ${space:-enter} = enter ]] && \
            echo -en "\033[$Lines;$((Cols-50))H\e[33m Pause ? Espace / Entrer           \e[0m" && return;
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
     [[ $# -eq 0 ]] && spk=$(((spk+1)%3));
     case $spk in
         0) temp="Ferrari ";;
         1) temp="Golf" ;;
         2) temp="Clio ";;
     esac
     echo -ne "\033[$Lines;3H\e[33mVitesse: $temp\e[0m"; #affichage écran
}

Direction() {                                   #Mise à jour de la direction
    case ${key:-enter} in
        5) [[ ${pos[0]} != "up"    ]] && pos[0]="down";;		#gestion des auto-collisions
        8) [[ ${pos[0]} != "down"  ]] && pos[0]="up";;
        4) [[ ${pos[0]} != "right" ]] && pos[0]="left";;
        6) [[ ${pos[0]} != "left"  ]] && pos[0]="right";;
        s|S) vitesse;;
        q|Q) quitter;;
      enter) pause;;
    esac
}

ajout_noeud() {                                 #Ajouter des noeuds au serpent
    snake="0$snake";  #ajout d'un zéro
    pos=(${pos[0]} ${pos[@]});
    xpt=(${xpt[0]} ${xpt[@]});
    ypt=(${ypt[0]} ${ypt[@]});
    maj 0;  #mise à jour des positions des noeuds

    local x=${xpt[0]} y=${ypt[0]}
    (( ((x>=$((Lines-1)))) || ((x<=1)) || ((y>=Cols)) || ((y<=1)) )) && return 1; #	Collision avec le mur

    for (( i = $((${#snake}-1)); i > 0; i-- )); do
        (( ${xpt[0]} == ${xpt[$i]} && ${ypt[0]} == ${ypt[$i]} )) && return 1; #crash du serpent
    done

    echo -ne "\033[${xpt[0]};${ypt[0]}H\e[32m${snake[@]:0:1}\e[0m";
    return 0;
}

aleatoire() {                               #Génération points et nombres aléatoires
    xrand=$((RANDOM%(Lines-3)+2));
    yrand=$((RANDOM%(Cols-2)+2));
    foodscore=$((RANDOM%9+1));

    echo -ne "\033[$xrand;${yrand}H$foodscore";
    liveflag=0;    
}

nouvelle_partie() {                                
    initialisation;
    while true; do
        read -t ${speed[$spk]} -n 1 key;
        [[ $? -eq 0 ]] && Direction;

        ((liveflag==0)) || aleatoire;
        if (( sumnode > 0 )); then
            ((sumnode--));
            ajout_noeud; (($?==0)) || return 1;
        else
            maj 0; 
            echo -ne "\033[${xpt[0]};${ypt[0]}H\e[32m${snake[@]:0:1}\e[0m";

            for (( i = $((${#snake}-1)); i > 0; i-- )); do
                maj $i;
                echo -ne "\033[${xpt[$i]};${ypt[$i]}H\e[32m${snake[@]:$i:1}\e[0m";

                (( ${xpt[0]} == ${xpt[$i]} && ${ypt[0]} == ${ypt[$i]} )) && return 1; #crashed
                [[ ${pos[$((i-1))]} = ${pos[$i]} ]] || pos[$i]=${pos[$((i-1))]};
            done
        fi

        local x=${xpt[0]} y=${ypt[0]}
        (( ((x>=$((Lines-1)))) || ((x<=1)) || ((y>=Cols)) || ((y<=1)) )) && return 1; #collsion mur

        (( x==xrand && y==yrand )) && ((liveflag=1)) && ((sumnode+=foodscore)) && ((sumscore+=foodscore));

        echo -ne "\033[$xscore;$((yscore-2))H$sumscore";
    done
}

affichage() {
    local x=$((xcent-4)) y=$((ycent-25))
    for (( i = 0; i < 8; i++ )); do
        echo -ne "\033[$((x+i));${y}H\e[45m${perdue[$i]}\e[0m";
    done
    echo -ne "\033[$((x+3));$((ycent+1))H\e[45m${sumscore}\e[0m";
}

serpent() {
    initialisation;

    local x=$((xcent-5)) y=$((ycent-25))
    for (( i = 0; i < 10; i++ )); do
        echo -ne "\033[$((x+i));${y}H\e[45m${jeux[$i]}\e[0m";
    done

    while read -n 1 anykey; do
        [[ ${anykey:-enter} = enter ]] && break;
        [[ ${anykey:-enter} = q ]] && quitter;
        [[ ${anykey:-enter} = s ]] && vitesse;
    done
    
    while true; do
        nouvelle_partie;
        affichage;
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

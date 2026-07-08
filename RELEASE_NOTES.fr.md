## v1.7.0 (build 42) — 8 juillet 2026

Voici la version stable qui met entre toutes les mains ce qui a été mis au point tout au long des bêtas 1.7.0. Si vous veniez de la 1.6.0, voici ce qui a changé.

### En bref
- **Une toute nouvelle table de mixage par personne.** Pour chaque personne présente dans votre canal, vous réglez son volume de voix, son volume des médias, sa position gauche/droite, sa coupure et son solo — le tout au clavier et avec VoiceOver.
- **Connexion avec un compte BearWare.** Un identifiant gratuit bearware.dk suffit désormais pour vous connecter aux serveurs compatibles, sans créer un compte différent sur chacun.
- **Un moteur audio reconstruit, plus rapide et plus stable.** La connexion est de nouveau quasi instantanée, changer de casque ou d'enceintes ne fige plus le son, et les canaux chargés restent fluides.

### La table de mixage
- Chaque personne du canal a sa propre tranche : **volume de la voix, volume des médias, position stéréo, coupure et solo**.
- Tout se pilote au clavier lorsque vous êtes positionné sur une personne : Haut/Bas pour le volume de la voix, Commande+Haut/Bas pour son volume des médias, Gauche/Droite pour la déplacer dans l'espace stéréo, et V, P, M, S pour entendre ou réinitialiser le volume, la position, la coupure et le solo.
- **Nouveau : appuyez sur Commande+5 pour aller directement à la table de mixage** — elle rejoint les raccourcis de zones Commande+1 à Commande+4 en tant que cinquième zone. (Merci à Matthew Whitaker pour l'idée.)
- Les réglages de chaque personne sont mémorisés et reviennent la prochaine fois qu'elle se connecte.

### Audio
- **Changer de périphérique de sortie ne fige plus le son.** Basculez de casque ou d'enceintes en cours de connexion, le son suit tout simplement.
- **La connexion est de nouveau rapide.** Sur les Mac équipés de beaucoup de matériel audio, l'ouverture d'une connexion pouvait s'immobiliser une dizaine de secondes le temps d'inspecter chaque appareil — cette analyse a disparu, et le correctif est maintenant intégré à chaque version.
- **Les canaux chargés et en haute qualité restent fluides.** Les canaux qui utilisent de gros paquets audio pouvaient hacher pour tout le monde ; la lecture a été revue pour tenir la charge.
- **Votre micro et votre sortie choisis sont retenus de façon fiable**, même après un débranchement, un rebranchement ou un redémarrage, au lieu de retomber discrètement sur le mauvais appareil.
- **Réduction de bruit indépendante.** Un nouveau réglage Traitement du microphone (Préférences › Audio) vous laisse choisir entre Aucun, Réduction de bruit, ou Annulation d'écho avec réduction de bruit — et le changement s'applique en direct, même pendant que vous parlez.
- **Vous entendez désormais vos propres médias diffusés** lorsque vous jouez un fichier audio ou vidéo dans un canal.
- **Les volumes par personne sont maintenant conservés par serveur** : un volume réglé sur un serveur ne déborde plus sur un autre. Un nouveau réglage vous laisse décider s'ils sont retenus en permanence, seulement le temps de la session, ou pas du tout.

### Accessibilité
- L'application s'appelle désormais **tt-Accessible**, pour que VoiceOver et les synthèses vocales la prononcent correctement.
- **Appuyez sur VoiceOver+Espace pour rejoindre** le serveur ou le canal sélectionné.
- **Les curseurs et le bouton du microphone annoncent maintenant leur valeur** au fur et à mesure que vous les modifiez — gain, volume de sortie et les différents curseurs des Préférences.
- Les Préférences se lisent plus proprement avec VoiceOver : plus d'étiquettes en double, chaque section est un vrai titre, les zones de défilement sont nommées, et Échap ferme la fenêtre.

### Corrections
- **La connexion web BearWare aboutit de façon fiable**, y compris sur les serveurs qui répondent de manière un peu inhabituelle.
- **Un pseudo laissé vide** revient maintenant à votre pseudo par défaut au lieu d'empêcher la connexion.
- L'application **démarre plus vite**.

### Remerciements
Un grand merci à **Rocco Fiorentino**, qui a conçu et réalisé la refonte audio et la table de mixage, les améliorations d'accessibilité et VoiceOver, ainsi que la connexion plus rapide et plus stable de cette version. Merci à **Matthew Whitaker** pour la suggestion du Commande+5 — et à toutes les personnes qui ont testé les bêtas et fait remonter leurs retours.

### Installation

tt-Accessible installe cette mise à jour pour vous automatiquement. Pour l'installer à la main :

1. Téléchargez `ttaccessible-1.7.0-42.zip` ci-dessous.
2. Décompressez-le et glissez `ttaccessible.app` dans votre dossier `/Applications`, en remplaçant la version précédente.
3. Double-cliquez — aucun avertissement Gatekeeper grâce à la notarisation.

### Téléchargement
[ttaccessible-1.7.0-42.zip](https://github.com/math65/ttaccessible/releases/download/v1.7.0/ttaccessible-1.7.0-42.zip)

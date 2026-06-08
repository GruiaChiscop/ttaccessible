Améliorations d'accessibilité du chat : copie au clavier et liens accessibles à VoiceOver.

## Corrections

- **Cmd+C copie désormais le message sélectionné** — fonctionne aussi bien dans le chat de canal que dans la fenêtre des messages privés. Auparavant, copier un message nécessitait un clic droit → Copier le message ; le raccourci affiché à côté de l'élément de menu ne faisait rien par lui-même.
- **Les liens dans les messages sont accessibles depuis VoiceOver** — les URL détectées dans un message sont exposées comme actions d'accessibilité sur sa ligne. Placez le curseur VoiceOver sur un message contenant un lien, appuyez sur VO+Cmd+Espace pour ouvrir le rotor des actions, puis choisissez « Ouvrir le lien : … » pour le lancer. Cliquer un lien à la souris dans le texte continue de fonctionner comme avant.
- **L'aperçu du microphone ne se fige plus sur les interfaces audio duplex** — lorsque le même appareil servait à la fois d'entrée et de sortie système (par exemple Komplete Audio 6 MK2), démarrer l'aperçu dans Préférences > Audio pouvait bloquer l'application. La lecture est maintenant démarrée avant la capture, afin que la sortie n'attende pas un appareil que l'entrée a déjà réservé ; l'aperçu ne détruit plus non plus le moteur micro de la connexion via un redémarrage parasite lié à un changement d'appareil.

## Installation

Si vous êtes en 1.3.0, 1.3.1 ou 1.3.2, ttaccessible installera cette mise à jour pour vous — aucune action requise.

Installation manuelle :

1. Téléchargez `ttaccessible-1.3.3-25.zip` ci-dessous.
2. Décompressez l'archive et glissez `ttaccessible.app` dans votre dossier `/Applications`, en remplaçant la version précédente.
3. Double-cliquez — aucun avertissement Gatekeeper grâce à la notarisation.

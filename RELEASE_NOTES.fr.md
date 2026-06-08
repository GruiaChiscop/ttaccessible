Changement de périphérique audio plus fiable, import de fichiers `.tt` multi-serveurs, et notes de mise à jour qui suivent désormais votre langue.

## Corrections

- **Changer le périphérique d'entrée ou de sortie dans les Préférences fonctionne à nouveau** — choisir un nouvel appareil pendant que l'audio était actif était devenu sans effet. Le changement s'applique maintenant immédiatement, même si vous changez d'appareil deux fois de suite.
- **Moins de redémarrages audio intempestifs** — les changements fréquents dans la liste des périphériques audio (transfert Continuité, appareils virtuels, démarrage de l'annulation d'écho) ne redémarrent plus tout le système audio à chaque fois. Cela met aussi fin à la série de demandes d'autorisation du microphone que certains utilisateurs constataient. Les appareils que vous choisissez vous-même dans les Préférences continuent de s'appliquer sans délai.
- **Importer un fichier `.tt` contenant plusieurs serveurs les importe désormais tous** — auparavant, seul le premier serveur du fichier était ajouté et les autres étaient ignorés en silence (#15).

## Améliorations

- **Les notes de mise à jour suivent votre langue** — cette fenêtre de mise à jour affiche les notes en français pour les utilisateurs francophones, et en anglais pour les autres.
- Mise à jour de l'outil de mise à jour Sparkle vers la version 2.9.3.

## Installation

Si vous êtes en 1.3.x, ttaccessible installera cette mise à jour pour vous — aucune action requise.

Installation manuelle :

1. Téléchargez `ttaccessible-1.3.4-26.zip` ci-dessous.
2. Décompressez l'archive et glissez `ttaccessible.app` dans votre dossier `/Applications`, en remplaçant la version précédente.
3. Double-cliquez — aucun avertissement Gatekeeper grâce à la notarisation.

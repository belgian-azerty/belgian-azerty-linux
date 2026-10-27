# Aidez à tester : clavier AZERTY belge comme sous Windows, pour Linux Mint 22.3 et Zorin OS 18.1

*English: [TESTING.md](TESTING.md) · Nederlands: [TESTING.nl.md](TESTING.nl.md)*

Merci de votre aide. Ce projet n'a été testé que dans des émulateurs et sur un seul ordinateur portable : chaque vrai
ordinateur compte. Pas besoin d'être expert, ni de donner votre nom.

## Ce qui manque le plus

- **Un vrai ordinateur** (pas une machine virtuelle) avec Linux Mint 22.3 ou Zorin OS 18.1.
- **Linux Mint installé directement sur un ordinateur** (pas encore testé du tout).
- **Un deuxième clavier** branché en USB.
- **Un clavier avec pavé tactile intégré** (un seul appareil, comme certains ensembles sans fil). Lisez d'abord
  « Avant de commencer » : ce cas est un risque connu.
- Zorin OS dans sa session Wayland habituelle, et VS Code si vous l'utilisez.

Une machine virtuelle (VirtualBox, GNOME Boxes) avec Mint 22.3 ou Zorin OS 18.1 est utile aussi.

## Avant de commencer (1 minute)

- Ceci modifie des réglages du clavier. Une seule commande retire tout (étape 9) ; le clavier reste belge ensuite,
  car la disposition belge est un réglage standard de Linux.
- Uniquement sur **Linux Mint 22.3** ou **Zorin OS 18.1**. Pas testé sur d'autres versions ni d'autres distributions.
- **Clavier avec pavé tactile intégré** : tant que le correctif fonctionne, le défilement fluide et les gestes du pavé
  tactile peuvent cesser de fonctionner sur cet appareil-là. Le README (« Known issues ») explique comment exclure cet
  appareil. Dites-le-nous si cela arrive.
- **Si le clavier s'arrête un jour alors que la souris fonctionne encore** (jamais vu pendant les tests) : redémarrez
  l'ordinateur avec la souris depuis le menu du système.

## Test 1 : sur un système installé ou une machine virtuelle (environ 20 minutes)

**1. Télécharger.** Depuis la [page de la version](https://github.com/belgian-azerty/belgian-azerty-linux/releases/latest), téléchargez ces trois fichiers dans votre dossier
Téléchargements : `keyd-belgian-windows_…_all.deb`, `belgian-azerty-windows_…_all.deb` et `SHA256SUMS`.

**2. Ouvrir un terminal à cet endroit.** Ouvrez le dossier Téléchargements, clic droit dans un espace vide, choisissez
« Ouvrir dans un terminal » (ou un intitulé proche).

**3. Vérifier les fichiers.** Tapez :

```
sha256sum -c SHA256SUMS --ignore-missing
```

Chacune des deux lignes doit se terminer par `OK` (sur un système en français, ce peut être un mot traduit).

**4. Installer.** Tapez (le mot de passe est demandé) :

```
sudo add-apt-repository ppa:keyd-team/ppa
sudo apt install keyd ./keyd-belgian-windows_*.deb ./belgian-azerty-windows_*.deb
sudo be-azerty-fix system
```

La première ligne ajoute le PPA keyd-team, qui fournit keyd (le programme derrière Ctrl+Alt comme AltGr) pour Mint 22
et Zorin 18. Pour la virgule sur le pavé numérique, tapez `sudo DECIMAL=comma be-azerty-fix system` à la place de la dernière
ligne.

**5. Fermez la session et reconnectez-vous.**

**6. Tapez les lignes de test.** Ouvrez l'éditeur de texte. Pour chaque ligne, notez exactement ce qui apparaît.

| Ligne | Ce que vous faites | Ce que vous devriez voir |
|---|---|---|
| A | Maintenez **Ctrl gauche + Alt gauche**, appuyez sur `1` `2` `3` `9` `0` `E`, relâchez | `\|@#{}€` |
| B | Maintenez **AltGr**, appuyez sur `1` `2` `3` `9` `0` `E`, relâchez | `\|@#{}€` |
| C | Appuyez une fois sur **Verr. Maj.**. Tapez les lettres `A` `Z` `E`, puis les touches `1` `2` `3` de la rangée du haut. Appuyez de nouveau sur **Verr. Maj.** | Mint : `AZE123` · Zorin : `AZE&É"` (sur Zorin, le Verr. Maj. de Windows est désactivé sauf si vous l'activez) |
| D | Verr. Num. activé, appuyez sur la touche décimale du pavé numérique | `.` (ou `,` si vous avez choisi la virgule) |
| E | Appuyez sur **Ctrl+Alt+T** | un terminal s'ouvre |

**7. Redémarrez l'ordinateur.** À l'écran de connexion, tapez votre mot de passe comme d'habitude. Une fois connecté,
tapez de nouveau la ligne A.

**8. Rassemblez les informations.** Dans un terminal, tapez :

```
be-azerty-fix check 2>&1 | sed "s/\b$USER\b/USER/g" > ~/belgian-check.txt
echo "$XDG_SESSION_TYPE" >> ~/belgian-check.txt
```

Cela crée le fichier `belgian-check.txt` dans votre dossier personnel, avec votre nom d'utilisateur déjà remplacé
par `USER` (il figure dans quelques lignes et dans des chemins de dossiers). **Ouvrez-le et relisez-le avant de le
partager** : si votre nom d'utilisateur y figure encore quelque part, remplacez-le par `USER`. Rien d'autre n'y est
personnel.

**9. Retirer (ou garder).** Pour tout retirer :

```
sudo be-azerty-fix uninstall
```

Puis fermez la session et reconnectez-vous. La ligne B (AltGr) doit toujours donner `|@#{}€` : c'est Linux standard.

**En plus, si vous en avez :**
- Deuxième clavier USB : branchez-le et tapez la ligne A dessus.
- Frappe rapide : dans le terminal, maintenez Ctrl gauche + Alt gauche et appuyez sur `2` `E` `2` `E` … huit fois,
  aussi vite que vous tapez d'habitude. Attendu : `@€@€@€@€@€@€@€@€`. Notez chaque paire inversée.
- VS Code : tapez la ligne A dans un fichier vide.
- Zorin, Verr. Maj. de Windows : lisez « Caps Lock on Zorin » dans le README, puis
  `sudo CAPS=windows be-azerty-fix system`, fermez la session et reconnectez-vous, et tapez la ligne C (attendu
  `AZE123`).

## Test 2 : clé USB live sur un vrai ordinateur (pour ceux qui utilisent déjà Linux)

Il n'y a pas d'image toute faite. Vous construisez la clé sur un ordinateur sous Linux, à partir de l'ISO officielle
téléchargée par vous-même, avec une seule commande (README, « Live USB »). Démarrez l'ordinateur sur la clé, choisissez
votre langue et « Belge » dans le menu de démarrage, et faites les lignes A à E du Test 1 dans la session live (rien
n'est écrit sur le disque de l'ordinateur). Puis l'étape 8. **Ne cliquez pas sur « Installer »**, sauf pour le Test 3.

## Test 3 : installer depuis la clé (uniquement sur un ordinateur dont le disque peut être effacé)

L'installation efface le disque choisi. Uniquement sur un ordinateur de réserve ou un disque vide, jamais sur un
ordinateur contenant des fichiers dont vous avez besoin. Installez depuis la clé avec le clavier belge ; le premier
démarrage après l'installation est plus long (il termine la configuration une fois ; laissez-le faire). Puis les
lignes A à E, l'étape 7 et l'étape 8.

## Envoyer le résultat

Au choix, le plus simple pour vous :

- **Avec un compte GitHub :** [ouvrir un rapport de test](https://github.com/belgian-azerty/belgian-azerty-linux/issues/new?template=test-report.yml) (un formulaire avec les mêmes
  étapes).
- **Sans compte :** [le formulaire de test anonyme](https://cryptpad.fr/form/#/2/form/view/s+Hn2IgNJ4cU55Hgx+CHNMPwvcyeARYS+n+OxnQPke4/) (ni compte, ni nom, ni e-mail).
- **Par e-mail :** linuxbelgiumkeyboard.rc0g4@aleeas.com, avec les lignes obtenues et `belgian-check.txt`.

Indiquez : Mint ou Zorin, installé / machine virtuelle / clé live, ce que vous avez vu pour les lignes A à E, et tout
ce qui vous a semblé étrange. La marque et le modèle de l'ordinateur et du clavier aident, mais sont facultatifs.
N'envoyez ni nom, ni adresse e-mail, ni nom d'utilisateur, sauf si vous souhaitez une réponse par e-mail.

**Pas le temps de tester ?** Le questionnaire de 2 minutes aide aussi : [English](https://cryptpad.fr/form/#/2/form/view/A9o2MXPQHcgJr0e6Y0eG3Qy0fjz13WeJ1IHy-JGxTy0/) · [Nederlands](https://cryptpad.fr/form/#/2/form/view/mLakgWAFAMsQhn1VkX+rnDxlHPSzbZiloRZxeS6IYlQ/) · [Français](https://cryptpad.fr/form/#/2/form/view/Vs07SGZoahOJOklE8G6wDZaC4Kjdl9mKyBwYAshSCQA/).

Merci !

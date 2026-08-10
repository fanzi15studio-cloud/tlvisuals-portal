# tesla-display — un second écran Mac sur la Tesla

Diffuse un écran de ton Mac dans le **navigateur web de la Tesla**, en Wi‑Fi, et
renvoie le **tactile de l'écran Tesla** vers la souris et le clavier du Mac.

Combiné à un écran virtuel créé par **BetterDisplay**, tu obtiens un vrai second
écran quand tu bosses dans la voiture : Final Cut sur le MacBook, timeline ou
mails sur l'écran de la Tesla.

> ⚠️ **À utiliser uniquement à l'arrêt** (voiture en stationnement ou en charge).
> Le navigateur Tesla se ferme d'ailleurs de lui-même en roulant.

---

## Ce que fait ce dossier — et ce qu'il ne fait pas

| | |
|---|---|
| **BetterDisplay** (app tierce, gratuite) | crée l'écran virtuel côté macOS |
| **tesla-display** (ce code) | capture cet écran, le diffuse en Wi‑Fi, et renvoie le tactile |

L'écran virtuel ne peut pas être codé ici : il repose sur une extension système
signée par Apple. BetterDisplay fait ça très bien. En revanche, **rien n'existe
pour envoyer cet écran vers une Tesla** — c'est exactement ce que fait cet outil.

---

## Prérequis

- macOS 13 (Ventura) ou plus récent
- Outils de développement : `xcode-select --install`
- [BetterDisplay](https://github.com/waydabber/BetterDisplay/releases) (version gratuite suffisante)
- Un partage de connexion (iPhone) ou un Wi‑Fi commun au Mac et à la Tesla

---

## 1. Créer l'écran virtuel

```bash
cd tools/tesla-display
./scripts/setup-virtual-display.sh
```

Le script installe BetterDisplay si besoin et rappelle la marche à suivre :

1. Ouvrir BetterDisplay → icône d'écran dans la barre des menus
2. **Virtual Displays ▸ Create New Virtual Display**, type « Display »
3. Résolution selon ton modèle :
   - **Model 3 / Model Y** → **1920 × 1200** (l'écran 15" est en 16:10, pas en 16:9)
   - **Model S / X 2021+** → 1920 × 1136
   - **Model S / X ≤ 2020** → 1200 × 1600 (écran portrait)
4. Réglages système ▸ **Moniteurs** : mode **Étendre** (surtout pas « Recopie »),
   et place l'écran virtuel à droite du principal

## 2. Mettre le Mac et la Tesla sur le même réseau

Le plus simple en déplacement : **partage de connexion de l'iPhone**.

- iPhone : Réglages ▸ Partage de connexion ▸ activer
- Mac : se connecter à ce réseau
- Tesla : **Commandes ▸ Wi‑Fi** ▸ choisir le réseau de l'iPhone

## 3. Lancer le serveur

```bash
cd tools/tesla-display
./run.sh --list        # repère l'index de l'écran virtuel
./run.sh --display 2   # le diffuse
```

Sans `--display`, l'outil choisit tout seul l'écran secondaire (donc le virtuel
dans la plupart des cas). La console affiche l'adresse à saisir :

```
À saisir dans le navigateur de la Tesla :

   http://172.20.10.3:8765   ← Wi-Fi / Ethernet (en0)
```

## 4. Ouvrir la page sur la Tesla

**Applications ▸ Navigateur** → saisir l'adresse affichée → l'écran du Mac apparaît.

Astuce : ajoute la page aux favoris du navigateur Tesla. L'adresse IP change à
chaque fois que tu rejoins le partage de connexion, mais elle est souvent stable
(`172.20.10.x` chez Apple).

---

## Gestes sur l'écran de la Tesla

| Geste | Effet |
|---|---|
| Appui simple | clic |
| Double appui | double‑clic |
| Appui long | clic droit (mode Tactile) |
| Appui long puis glisser | glisser‑déposer, sélection de texte |
| Glisser un doigt | défilement (mode Tactile) / déplacement du curseur (mode Souris) |
| Deux doigts | zoomer et déplacer la vue (local, ne touche pas au Mac) |
| Bouton ☰ | qualité, clavier, zoom, mode |

Le **clavier virtuel de la Tesla** s'ouvre via ☰ ▸ « Ouvrir le clavier ». Les
touches ⏎ ⌫ ⇥ esc, les flèches et les raccourcis ⌘C / ⌘V / ⌘Z / ⌘A sont dans le panneau.

Si le défilement part à l'envers : ☰ ▸ **Défilement inversé**.

---

## Réglages de qualité

Quatre présélections, changeables en direct depuis la Tesla (☰) :

| Préset | Encodage | Débit approx. | Usage |
|---|---|---|---|
| Éco | 960 px · 10 i/s · q 0.40 | ~1,5 Mb/s | 4G faible, texte |
| **Normal** | 1280 px · 15 i/s · q 0.55 | ~4 Mb/s | par défaut |
| Net | 1600 px · 20 i/s · q 0.70 | ~10 Mb/s | lecture de code, retouche |
| Max | 1920 px · 24 i/s · q 0.80 | ~18 Mb/s | Wi‑Fi domestique |

En partage de connexion, **Éco** ou **Normal** : le flux passe par le Wi‑Fi de
l'iPhone, pas par la 4G, donc ça ne consomme pas de données mobiles.

---

## Options

```
./run.sh --help

  --list              Liste les écrans détectés puis quitte
  --display <n|id>    Écran à diffuser (index de --list, identifiant, ou "main")
  --port <n>          Port d'écoute (défaut : 8765)
  --preset <nom>      eco | normal | sharp | max
  --width <px>        Largeur d'encodage
  --fps <n>           Images par seconde
  --quality <0.1-1>   Qualité JPEG
  --token <secret>    Exige ?t=<secret> pour accéder au flux
  --no-input          Lecture seule : pas de contrôle souris/clavier
```

---

## Autorisations macOS

Deux autorisations sont demandées au premier lancement. Elles s'appliquent à
**l'application depuis laquelle tu lances la commande** (Terminal, iTerm, VS Code…),
pas au binaire lui-même.

Réglages système ▸ Confidentialité et sécurité :

- **Enregistrement de l'écran** → obligatoire (sinon aucune image)
- **Accessibilité** → nécessaire pour que le tactile pilote le Mac

Après avoir coché une case, **quitte complètement le terminal** (⌘Q) et relance.

---

## Sécurité

Le serveur écoute sur toutes les interfaces réseau. Sur un partage de connexion
personnel, seuls tes appareils y ont accès. Sur un Wi‑Fi partagé (hôtel, coworking,
borne de recharge), protège l'accès :

```bash
./run.sh --display 2 --token monsecret
# → http://172.20.10.3:8765/?t=monsecret
```

Ou diffuse sans donner le contrôle du Mac :

```bash
./run.sh --display 2 --no-input
```

Le flux est en HTTP simple (le navigateur Tesla n'accepte pas de certificat
auto‑signé sans avertissement bloquant) : à réserver aux réseaux de confiance.

---

## Dépannage

**Page blanche / « Mac injoignable »**
Vérifie que les deux appareils sont sur le même réseau. Depuis le Mac :
`curl http://<ton-ip>:8765/health` doit renvoyer `ok`. Un VPN actif sur le Mac
casse souvent la route — coupe-le.

**Image figée après quelques minutes**
Le navigateur Tesla suspend les onglets en arrière-plan. Reviens sur l'onglet,
ou touche ☰ ▸ Reconnecter. La page se reconnecte seule au bout de ~1,5 s.

**Le tactile ne fait rien**
Autorisation Accessibilité manquante (voir plus haut) — le flux vidéo continue
de marcher, ce qui rend le symptôme trompeur. La page affiche « lecture seule »
en haut à gauche quand `--no-input` est actif.

**Le curseur va sur le mauvais écran**
Tu diffuses le mauvais écran : `./run.sh --list` puis `--display <n>`.

**Beaucoup de latence**
Passe en Éco, rapproche-toi du téléphone, et privilégie un partage de connexion
5 GHz si la Tesla le supporte (Model 3/Y récents).

---

## Limites connues

- **Pas de son** : le navigateur Tesla ne lit pas de flux audio de ce type.
- **Latence ~80–200 ms** selon le réseau : parfait pour du texte, du montage
  léger, des mails ; pas pour du jeu ou du colorimétrage fin.
- **JPEG (MJPEG)** plutôt que H.264 : c'est le seul format que le navigateur
  Tesla affiche de façon fiable en direct, au prix d'un débit plus élevé.
- L'écran Tesla passe en veille au bout d'un moment sur certains firmwares ;
  un appui le réveille.

---

## Note sur cette première version

Le code a été écrit et relu attentivement, mais **il n'a pas pu être compilé ici** :
ScreenCaptureKit est exclusivement macOS et l'environnement de développement
utilisé est sous Linux. La première compilation est à faire sur ton Mac :

```bash
cd tools/tesla-display && swift build -c release
```

Si `swift build` remonte une erreur, envoie-la moi telle quelle : ce sera une
correction rapide (signature d'API, pas d'architecture).

---

## Architecture du code

```
Sources/TeslaDisplay/
  TeslaDisplayApp.swift   point d'entrée, options CLI, routage HTTP
  ScreenStreamer.swift    capture ScreenCaptureKit → JPEG
  FrameBroadcaster.swift  distribution des images aux clients connectés
  HTTPServer.swift        serveur HTTP + MJPEG (Network.framework, zéro dépendance)
  InputInjector.swift     gestes Tesla → événements souris/clavier macOS (CGEvent)
  ClientHTML.swift        la page affichée sur l'écran de la Tesla
  NetworkInfo.swift       détection des adresses IP locales
```

Points de conception :

- **Aucune dépendance externe** : uniquement les frameworks Apple, donc rien à
  installer et rien qui casse à la prochaine mise à jour de macOS.
- **Images abandonnées plutôt qu'accumulées** : si le Wi‑Fi sature, on saute des
  images au lieu de prendre du retard — la fraîcheur prime.
- **Coordonnées normalisées (0…1)** : le tactile reste juste quelle que soit la
  résolution d'encodage, le zoom appliqué, ou la taille de l'écran Tesla.
- **Battement de cœur d'une image par seconde** : ScreenCaptureKit n'émet rien
  sur un écran statique, et une connexion inactive finit par être coupée.

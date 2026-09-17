# Outil 2 — Stirling PDF sur votre MacBook

**Ce que c'est :** une boîte à outils PDF complète (fusionner, découper, compresser,
convertir, signer, OCR, filigrane…) qui tourne **sur votre Mac**. Aucun fichier
n'est envoyé sur internet : c'est l'intérêt principal par rapport aux sites
gratuits de manipulation de PDF, où vous déposez vos documents chez un inconnu.

**Durée :** environ 20 minutes, dont 10 de téléchargement.

---

## Étape 0 — Vérifier si Docker est installé

Ouvrez le **Terminal** (Cmd + Espace, tapez « Terminal », Entrée) et collez :

```bash
docker --version && docker compose version
```

- **Deux numéros de version s'affichent** → Docker est prêt, passez à l'étape 2.
- **`command not found`** → passez à l'étape 1.

---

## Étape 1 — Installer Docker (si absent)

Docker est le logiciel qui fait tourner des applications dans des « boîtes »
isolées, sans polluer votre système. Deux options pour un Mac Apple Silicon :

**Option A — Docker Desktop** (le plus courant)

1. Allez sur <https://www.docker.com/products/docker-desktop/>
2. Téléchargez **Mac with Apple Chip** (votre M4 Max est en arm64, pas Intel).
3. Ouvrez le `.dmg`, glissez Docker dans Applications, lancez-le.
4. Laissez l'icône baleine tourner dans la barre de menus : Docker doit être
   lancé pour que les commandes fonctionnent.

**Option B — OrbStack** (plus léger, plus rapide sur Mac)

```bash
brew install orbstack
```

Les commandes `docker` sont identiques ensuite. Sur un Mac de montage, OrbStack
consomme nettement moins de RAM que Docker Desktop — utile quand DaVinci ou
Premiere tournent en parallèle.

Vérifiez ensuite :

```bash
docker --version && docker compose version
```

---

## Étape 2 — Créer le dossier et récupérer la configuration

```bash
mkdir -p ~/Docker/stirling-pdf
cd ~/Docker/stirling-pdf
```

Copiez-y le fichier `docker-compose.yml` fourni dans ce dépôt
(`infra/2-stirling-pdf/docker-compose.yml`) ainsi que `test-fusion-pdf.sh`.

Si vous avez cloné le dépôt sur votre Mac :

```bash
cp ~/chemin/vers/tlvisuals-portal/infra/2-stirling-pdf/docker-compose.yml .
cp ~/chemin/vers/tlvisuals-portal/infra/2-stirling-pdf/test-fusion-pdf.sh .
```

Créez les dossiers de données (ils garderont vos réglages entre deux redémarrages) :

```bash
mkdir -p stirling-data/{configs,tessdata,logs,pipeline}
```

> **À quoi servent ces 4 dossiers ?**
> - `configs` : vos réglages et préférences
> - `tessdata` : les langues de la reconnaissance de texte (OCR)
> - `logs` : les journaux, utiles en cas de souci
> - `pipeline` : les traitements automatisés (ex. « tout PDF déposé ici est compressé »)

---

## Étape 3 — Lancer Stirling PDF

```bash
docker compose up -d
```

`up` = démarrer, `-d` = en arrière-plan (le Terminal vous rend la main).

Le premier lancement télécharge environ 2–3 Go, puis Java démarre : **comptez
1 à 2 minutes avant que la page réponde**. C'est normal, ne concluez pas trop vite.

Suivre le démarrage :

```bash
docker compose logs -f
```

(`Ctrl + C` pour quitter l'affichage des logs — ça n'arrête pas le conteneur.)

---

## Étape 4 — Ouvrir l'interface

<http://localhost:8080>

L'interface doit être **en français** (`SYSTEM_DEFAULTLOCALE=fr-FR`) et **sans
demande de mot de passe** (`SECURITY_ENABLELOGIN=false`), puisque c'est votre
ordinateur personnel.

> **Pourquoi sans mot de passe est acceptable ici, et seulement ici :** dans le
> fichier fourni, le port est publié sur `127.0.0.1:8080` et non `0.0.0.0:8080`.
> Autrement dit, le service n'est joignable que depuis votre Mac — même connecté
> au wifi d'un client ou d'un hôtel, personne d'autre ne peut y accéder.
> **Sur un serveur exposé à internet, ce réglage serait une faute grave** :
> utilisez alors `serveur/docker-compose.yml`, qui garde la connexion activée.

---

## Étape 5 — Vérifier en fusionnant deux PDF

**Vérification automatique** (recommandée) :

```bash
bash test-fusion-pdf.sh
```

Le script crée deux PDF d'une page, interroge l'API de votre instance, fusionne
les deux fichiers et vérifie que le résultat fait bien 2 pages. Vous obtenez
le fichier dans `test-pdf/resultat-fusion.pdf`.

**Vérification à la main** (pour voir l'outil en vrai) :

1. Sur <http://localhost:8080>, cherchez l'outil **Fusionner / Merge**.
2. Déposez deux PDF (par ex. deux devis, ou deux exports de votre CV).
3. Lancez la fusion, téléchargez le résultat, ouvrez-le : les pages des deux
   fichiers doivent se suivre.

---

## Étape 6 — OCR en français (optionnel mais utile)

L'OCR rend un scan « sélectionnable » et cherchable — pratique pour les contrats
signés reçus en scan. Le dossier `tessdata` monté est vide au départ, il faut y
mettre les langues :

```bash
cd ~/Docker/stirling-pdf
curl -L -o stirling-data/tessdata/fra.traineddata \
  https://github.com/tesseract-ocr/tessdata/raw/main/fra.traineddata
curl -L -o stirling-data/tessdata/eng.traineddata \
  https://github.com/tesseract-ocr/tessdata/raw/main/eng.traineddata
docker compose restart
```

> **Pourquoi c'est nécessaire :** en montant un dossier de votre Mac sur
> `/usr/share/tessdata`, on masque les langues livrées dans l'image. Sans ces
> deux fichiers, l'OCR ne trouve aucune langue et échoue. C'est exactement le
> genre de détail qui fait dire « ça ne marche pas » sans raison apparente.

---

## Commandes du quotidien

| Ce que vous voulez faire | Commande (depuis `~/Docker/stirling-pdf`) |
|---|---|
| Démarrer | `docker compose up -d` |
| Arrêter | `docker compose down` |
| Voir si ça tourne | `docker compose ps` |
| Lire les journaux | `docker compose logs -f` |
| Mettre à jour | `docker compose pull && docker compose up -d` |
| Tout supprimer sauf vos données | `docker compose down --rmi all` |

**Sauvegarde :** tout ce qui compte est dans le dossier `stirling-data/`.
Copiez-le sur votre SSD externe Extreme Pro de temps en temps ; il suffit à
retrouver vos réglages sur une nouvelle machine.

---

## Si ça ne marche pas

| Symptôme | Cause probable et solution |
|---|---|
| `Cannot connect to the Docker daemon` | Docker Desktop / OrbStack n'est pas lancé. Ouvrez l'application. |
| La page ne répond pas tout de suite | Java met 1–2 min au premier démarrage. `docker compose logs -f` et attendez la ligne `Started SPDFApplication`. |
| `port is already allocated` | Un autre logiciel occupe le 8080. Changez pour `"127.0.0.1:8081:8080"` dans le compose, puis ouvrez <http://localhost:8081>. |
| Interface en anglais | Vérifiez `SYSTEM_DEFAULTLOCALE: fr-FR` puis `docker compose up -d --force-recreate`. |
| L'OCR échoue | Les langues manquent : faites l'étape 6. |
| Un gros PDF est refusé | Augmentez `SYSTEM_MAXFILESIZE` (en Mo) puis `docker compose up -d`. |

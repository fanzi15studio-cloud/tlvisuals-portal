# Kit d'installation — Dokploy, Stirling PDF, DocuSeal

Kit préparé pour **Thomas Loiseau Visuals**, pensé pour un débutant : chaque
guide explique le *pourquoi* avant le *comment*, et chaque commande est à
copier-coller.

---

## À lire en premier : ce que j'ai pu faire, et ce que je n'ai pas pu faire

Cette session Claude Code tourne dans un **conteneur Linux temporaire dans le
cloud**, créé pour votre dépôt et détruit ensuite. Je n'ai **aucun accès SSH**
à votre MacBook ni à votre VPS. Les trois outils n'ont donc **pas** été
installés sur vos machines : personne ne peut le faire à distance sans vos
identifiants, et je ne vous les demanderai pas.

**Ce que j'ai réellement fait :**

| Travail | État |
|---|---|
| Audit du code des 3 projets (licences, installeurs, secrets, exposition réseau) | ✅ fait — voir `AUDIT-SECURITE.md` |
| Vérification des chemins de volumes et des variables dans les dépôts officiels | ✅ fait |
| Validation des `docker-compose.yml` par le moteur Docker Compose | ✅ fait |
| Script de diagnostic du VPS, exécuté pour vérifier qu'il ne plante pas | ✅ fait |
| Construction de votre application Next.js en mode serveur | ✅ fait, et **un bug bloquant a été trouvé** (voir plus bas) |
| Démarrage réel des conteneurs Stirling / DocuSeal | ❌ **impossible** : la politique réseau de la session bloque les registries Docker (403) |
| Installation sur votre VPS et votre Mac | ❌ **à faire par vous**, guides fournis, je vous accompagne pas à pas |

---

## Ordre à suivre

Vous m'avez demandé de terminer complètement un outil avant de passer au
suivant. L'ordre ci-dessous respecte aussi les dépendances techniques :
DocuSeal a besoin du HTTPS fourni par Dokploy.

### 1. Dokploy — sur le VPS → `1-dokploy/GUIDE.md`

⛔ **Bloqué en attente de votre diagnostic.** Votre bot CLAUDIO tourne déjà sur
ce VPS, et Dokploy réclame les ports 80, 443 et 3000. Lancez d'abord :

```bash
bash infra/00-diagnostic-vps.sh
```

et envoyez-moi le résultat. Ce script ne modifie rien.

### 2. Stirling PDF — sur le MacBook → `2-stirling-pdf/GUIDE.md`

✅ **Faisable immédiatement.** Indépendant du VPS et de CLAUDIO : vous pouvez
le faire pendant que le point 1 attend.

### 3. DocuSeal — sur le VPS → `3-docuseal/GUIDE.md`

⏸️ **À faire après Dokploy**, qui fournit le certificat HTTPS.

---

## Architecture retenue, et pourquoi

D'après vos réponses : Stirling en local, le reste sur le VPS, sous-domaines de
`thomasloiseauvisuals.com`, documents de clients.

```
   MacBook Pro M4 Max                    VPS (Ubuntu)
   ──────────────────                    ────────────────────────────────
   Stirling PDF                          Traefik  (ports 80 / 443)
   127.0.0.1:8080                           │   installé par Dokploy
   sans mot de passe                        ├── dokploy.thomasloiseauvisuals.com
   vos PDF ne sortent pas                   ├── sign.thomasloiseauvisuals.com  → DocuSeal
                                            └── portail.thomasloiseauvisuals.com → votre app
                                         CLAUDIO (déjà présent — à vérifier)
```

**Le point d'architecture à comprendre :** un seul programme peut écouter sur
un port donné. Dokploy installe Traefik sur les ports 80 et 443. Le fichier
officiel de DocuSeal, lui, lance son propre Caddy sur ces **mêmes** ports : les
deux sont donc incompatibles sur une même machine. D'où deux versions fournies
pour DocuSeal — c'est expliqué dans son guide.

---

## Bug trouvé dans votre dépôt (indépendant des 3 outils)

En préparant le déploiement de votre portail sur Dokploy, j'ai construit
l'application. **Sur `main`, `npm run build` échoue :**

```
Export encountered errors on following paths:
	/api/client/route: /api/client
```

`next.config.mjs` demande un export statique (`output: 'export'`) pour
l'hébergement FTP Hostinger, alors que `app/api/client/route.js` doit
s'exécuter côté serveur pour lire votre Google Sheet. Un site statique est un
dossier de fichiers : il ne peut pas exécuter de code. Next.js refuse donc de
construire, votre workflow GitHub casse avant l'envoi FTP, et le portail client
ne peut de toute façon pas fonctionner en statique.

**Ce que j'ai préparé sur cette branche** (rien n'est encore fusionné dans
`main`, votre site actuel n'est pas touché) :

- `next.config.mjs` accepte une variable `BUILD_TARGET` — sans elle, le
  comportement est **exactement celui d'aujourd'hui** ; avec
  `BUILD_TARGET=server`, l'application se construit avec un serveur Node.js.
- un `Dockerfile` à la racine pour le déploiement Dokploy.

**Vérifié :** le build serveur réussit, le serveur démarre, la page d'accueil
répond 200, et `/api/client` s'exécute bien côté serveur (elle réclame
`GOOGLE_SHEET_ID`). Détails dans `1-dokploy/GUIDE.md`, étape 9.

---

## Contenu du kit

```
infra/
├── README.md                    ce fichier
├── AUDIT-SECURITE.md            audit des 3 projets — à lire avant d'installer
├── 00-diagnostic-vps.sh         état du VPS, sans rien modifier
│
├── 1-dokploy/
│   ├── GUIDE.md                 guide pas-à-pas
│   ├── 05-pare-feu-ufw.sh       pare-feu (simulation par défaut)
│   └── 10-fermer-port-3000.sh   ferme le port 3000 sans vous enfermer dehors
│
├── 2-stirling-pdf/
│   ├── GUIDE.md
│   ├── docker-compose.yml       version MacBook (127.0.0.1, sans mot de passe)
│   ├── test-fusion-pdf.sh       vérification par fusion de 2 PDF
│   └── serveur/                 version exposée sur internet, avec Caddy
│
└── 3-docuseal/
    ├── GUIDE.md
    ├── via-dokploy/             version recommandée (Traefik gère le HTTPS)
    └── autonome/                version avec Caddy, si pas de Dokploy
```

---

## Règles de sécurité valables pour les trois outils

1. **Aucun secret dans Git.** Les fichiers `.env` sont exclus par `.gitignore`.
   Les secrets vont dans votre gestionnaire de mots de passe et dans
   l'interface de Dokploy.
2. **Un mot de passe unique par service**, généré aléatoirement :
   `openssl rand -base64 24`
3. **Sauvegardes dès le premier jour**, y compris la clé `SECRET_KEY_BASE` de
   DocuSeal — sans elle, une sauvegarde de base de données est illisible.
4. **Mises à jour régulières** : `docker compose pull && docker compose up -d`
   pour Stirling et DocuSeal ; bouton dédié dans l'interface Dokploy.
5. **Jamais de service sans authentification exposé à internet.** Le mode sans
   mot de passe de Stirling PDF est réservé à votre Mac, sur 127.0.0.1.

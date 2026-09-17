# Outil 1 — Dokploy sur votre VPS

**Ce que c'est :** un tableau de bord qui installe sur *votre* serveur ce que
Vercel, Netlify ou Heroku vous louent : vous connectez GitHub, vous cliquez
« Deploy », et votre application est en ligne avec un domaine et un certificat
HTTPS automatique. Vous payez votre VPS, rien d'autre.

**Durée :** 45 à 60 minutes.

> ## ⛔ À LIRE AVANT TOUT — votre bot CLAUDIO
>
> Vous m'avez indiqué que votre bot personnel **CLAUDIO tourne déjà sur ce
> VPS**. C'est le point de vigilance numéro un de cette installation, pour
> deux raisons que j'ai vérifiées dans le code source de l'installeur :
>
> 1. **Les ports.** Dokploy installe Traefik, qui prend les ports **80, 443 et
>    443/udp**, et publie son interface sur le port **3000**. Si CLAUDIO utilise
>    l'un de ces ports — le 3000 est le port par défaut de presque tous les
>    projets Node.js — l'un des deux tombera en panne. L'installeur se contente
>    d'un avertissement sur 80/443 et **continue quand même**.
> 2. **Docker Swarm.** L'installeur exécute `docker swarm init` sur la machine.
>    Vos conteneurs `docker compose` existants continuent de fonctionner, mais
>    le mode de fonctionnement de Docker change sur ce serveur.
>
> **Donc : lancez d'abord le diagnostic, et ne poursuivez pas seul si un port
> apparaît occupé.**
>
> ```bash
> bash infra/00-diagnostic-vps.sh
> ```
>
> Copiez-moi le résultat complet : je vous dirai si la voie est libre ou
> quelle solution adopter (déplacer CLAUDIO derrière Traefik, changer son port,
> ou dédier un second VPS).

---

## Étape 1 — Diagnostic (obligatoire)

Connectez-vous en SSH puis :

```bash
ssh root@IP_DE_VOTRE_VPS
bash 00-diagnostic-vps.sh
```

Ce script ne modifie rien. Il vérifie : l'OS, la RAM (2 Go minimum), le disque,
**les ports 80/443/3000**, Docker, les services web déjà présents, les processus
de type bot, le pare-feu et vos DNS.

Vous pouvez continuer si :
- ✅ 2 Go de RAM au moins (4 Go recommandés avec DocuSeal ensuite)
- ✅ ports 80, 443 **et** 3000 libres
- ✅ 10 Go d'espace disque libre au moins

---

## Étape 2 — Lire le script d'installation avant de l'exécuter

La documentation officielle propose :

```bash
curl -sSL https://dokploy.com/install.sh | sh
```

Cette formule télécharge un script et l'exécute **en root, immédiatement, sans
que personne ne l'ait lu**. Comme vous allez héberger des contrats clients sur
cette machine, prenez les trente secondes qui changent tout :

```bash
curl -sSL https://dokploy.com/install.sh -o dokploy-install.sh
less dokploy-install.sh     # q pour quitter
sh dokploy-install.sh
```

Le résultat est identique, mais vous aurez vu ce qui s'exécute. Ce que
l'installeur fait (je l'ai vérifié dans le code source du dépôt, fichier
`packages/server/src/setup/server-setup.ts`) :

| Action | Détail |
|---|---|
| Installe des utilitaires | `curl`, `wget`, `git`, `jq`, `openssl`, `unzip` |
| Installe Docker | via le script officiel `get.docker.com` s'il est absent |
| Active Docker Swarm | `docker swarm init` |
| Crée un réseau | `dokploy-network` (overlay) |
| Lance Traefik | conteneur avec les ports 80, 443, 443/udp |
| Lance PostgreSQL et Redis | à usage interne de Dokploy |
| Lance Dokploy | interface web sur le port 3000 |
| Installe des constructeurs d'images | Nixpacks, Railpack, Buildpacks, RClone — **chacun via son propre `curl ... \| bash`** |

> **Le point à connaître :** ce dernier point signifie que l'installation
> exécute du code téléchargé depuis plusieurs sites tiers
> (`nixpacks.com`, `railpack.com`, `rclone.org`, `get.docker.com`). C'est
> courant dans cet écosystème, mais cela élargit la surface de confiance :
> vous ne faites pas confiance à Dokploy seul, mais à quatre fournisseurs.
> C'est acceptable sur un serveur dédié à cet usage ; c'est une raison de plus
> de ne pas mélanger ce serveur avec quelque chose de critique.

---

## Étape 3 — Créer votre compte administrateur — tout de suite

Ouvrez dans votre navigateur :

```
http://IP_DE_VOTRE_VPS:3000
```

Un formulaire de création de compte s'affiche. **Remplissez-le immédiatement.**

> **Pourquoi l'urgence :** le port 3000 est ouvert sur internet et le premier
> compte créé est le compte propriétaire. Entre la fin de l'installation et
> votre inscription, n'importe qui connaissant l'IP peut créer ce compte et
> prendre le contrôle du serveur. Les scanners automatiques d'internet trouvent
> une nouvelle IP ouverte en quelques minutes. Ne partez pas déjeuner entre
> l'étape 2 et l'étape 3.

Mot de passe long et unique, dans votre gestionnaire de mots de passe.

---

## Étape 4 — Renseigner votre email Let's Encrypt

Dans **Settings → Server / Web Server (Traefik)**, indiquez votre véritable
adresse email pour les certificats.

> **Pourquoi :** j'ai vérifié dans le code (`traefik-setup.ts`) que la
> configuration par défaut utilise l'adresse `test@localhost.com`. Vous ne
> recevriez donc aucun avertissement de Let's Encrypt en cas d'échec de
> renouvellement — et vous découvririez le problème le jour où vos clients
> tombent sur une alerte de sécurité dans leur navigateur.

---

## Étape 5 — Créer le sous-domaine DNS

Chez votre gestionnaire DNS (celui qui héberge `thomasloiseauvisuals.com`) :

| Type | Nom | Valeur |
|---|---|---|
| A | `dokploy` | IP publique du VPS |

Vérifiez depuis le VPS :

```bash
dig +short dokploy.thomasloiseauvisuals.com
```

L'IP de votre VPS doit s'afficher avant de continuer.

---

## Étape 6 — Donner un domaine à Dokploy lui-même

Dans **Settings → Server → Domain** :

- Domain : `dokploy.thomasloiseauvisuals.com`
- Certificate : **Let's Encrypt**
- Enregistrez, patientez une minute

Testez <https://dokploy.thomasloiseauvisuals.com> : l'interface doit s'ouvrir
avec le cadenas. **Ne fermez pas le port 3000 avant que ce test soit
concluant.**

---

## Étape 7 — Fermer l'accès direct au port 3000

```bash
bash 10-fermer-port-3000.sh dokploy.thomasloiseauvisuals.com
```

Le script vérifie d'abord que votre domaine HTTPS répond et que le certificat
est valide ; il refuse d'agir sinon, pour ne pas vous enfermer dehors. Puis il
retire la publication du port et revérifie que l'interface répond toujours.

> **Pourquoi pas simplement `ufw deny 3000` ?** Parce que ça ne marcherait pas,
> tout en vous donnant l'impression du contraire. Docker écrit ses propres
> règles iptables, évaluées **avant** celles d'ufw : un port publié par un
> conteneur reste joignable depuis internet même si ufw affiche « deny ».
> La seule méthode fiable est de retirer la publication du port, ce que fait
> le script (`docker service update --publish-rm 3000 dokploy`). Le domaine
> continue de fonctionner car Traefik joint Dokploy par le réseau interne,
> sur `http://dokploy:3000` — vérifié dans leur code source.

Pare-feu général (optionnel mais recommandé), en simulation d'abord :

```bash
bash 05-pare-feu-ufw.sh              # affiche ce qui serait fait
bash 05-pare-feu-ufw.sh --appliquer  # applique, avec confirmation
```

---

## Étape 8 — Connecter GitHub

1. **Settings → Git → GitHub → Create GitHub App**
2. Dokploy vous redirige vers GitHub : installez l'application et **n'autorisez
   que le dépôt `tlvisuals-portal`** (« Only select repositories »).
   N'accordez pas l'accès à tous vos dépôts : si le serveur était compromis,
   la casse serait limitée à ce seul projet.
3. De retour dans Dokploy, le dépôt doit apparaître dans la liste.

---

## Étape 9 — Déployer votre portail : Nixpacks ou Dockerfile ?

Vous m'avez demandé de trancher moi-même. **Réponse : Dockerfile**, et voici
sur quoi je m'appuie — j'ai construit votre application pour vérifier.

**J'ai trouvé un problème réel dans votre dépôt :** sur la branche `main`,
`npm run build` **échoue** :

```
Export encountered errors on following paths:
	/api/client/route: /api/client
```

**La cause :** `next.config.mjs` contient `output: 'export'` (export statique,
pour l'hébergement FTP Hostinger), alors que `app/api/client/route.js` est une
route qui s'exécute **côté serveur** pour lire votre Google Sheet. Un site
statique est un simple dossier de fichiers : il ne peut pas exécuter de code.
Les deux sont donc incompatibles, et Next.js refuse de construire.

**Conséquences concrètes :** votre workflow GitHub « Build & Deploy to
Hostinger » casse à l'étape de construction, donc l'envoi FTP n'a jamais lieu ;
et même si le site était en ligne, `app/page.js` appelle `/api/client`, qui
n'existe pas en statique — la saisie du code d'accès client ne pouvait pas
fonctionner.

**Ce que j'ai préparé et vérifié :**

1. `next.config.mjs` accepte désormais une variable `BUILD_TARGET` :
   - sans rien (comportement actuel, inchangé) → export statique pour Hostinger
   - `BUILD_TARGET=server` → application Next.js complète avec serveur Node.js
2. Un `Dockerfile` à la racine, qui construit en mode serveur.

**Vérifications effectuées de mon côté :**

| Test | Résultat |
|---|---|
| `BUILD_TARGET=server npm run build` | ✅ réussit ; `/api/client` devient une route dynamique Node.js |
| Démarrage du serveur produit | ✅ page d'accueil en HTTP 200 |
| Appel de `/api/client?code=TEST` | ✅ répond `{"error":"Configuration serveur manquante."}` — la route s'exécute bien côté serveur, il ne lui manque que `GOOGLE_SHEET_ID` |
| Lecture du `Dockerfile` par Docker | ✅ se parse sans erreur |
| Construction réelle de l'image | ❌ **non testée** : la politique réseau de ma session bloque Docker Hub. C'est la seule étape que vous découvrirez en direct. |

**Le déploiement dans Dokploy :**

1. **Projects → Create Project** (nom : `TLV`)
2. **Create Service → Application**, nom : `portail`
3. **Provider : GitHub** → dépôt `fanzi15studio-cloud/tlvisuals-portal`,
   branche `main` (ou d'abord `claude/install-dokploy-stirling-docuseal-2dm5ps`
   pour tester sans toucher à `main`)
4. **Build Type : Dockerfile**, chemin : `Dockerfile`
5. **Environment** : ajoutez
   ```
   GOOGLE_SHEET_ID=votre_identifiant_de_google_sheet
   ```
6. **Deploy**, puis suivez les logs de construction
7. **Domains → Add Domain** : par exemple `portail.thomasloiseauvisuals.com`,
   port du conteneur **3000**, HTTPS **Let's Encrypt**

**Vérification finale :** ouvrez le domaine, saisissez un code client présent
dans votre Google Sheet. Si les projets, documents et paiements s'affichent,
tout fonctionne — et votre portail fait alors quelque chose qu'il ne pouvait
pas faire sur Hostinger.

> **Et Nixpacks ?** Nixpacks détecte Next.js et sait le construire. Mais il
> aurait exécuté `npm run build` sans `BUILD_TARGET=server`, donc il aurait
> reproduit exactement l'échec ci-dessus. Le Dockerfile rend la cible de
> construction explicite : c'est ce qui le rend fiable ici.

---

## Étape 10 — Base de données (si besoin un jour)

Votre portail lit un Google Sheet : il n'a **pas** besoin de base de données
aujourd'hui. Le jour où vous en voudrez une (pour ne plus dépendre de Google) :

1. **Create Service → Database → PostgreSQL**
2. Dokploy génère un mot de passe et affiche une URL interne de connexion
3. Copiez-la dans **Environment** de votre application sous `DATABASE_URL`
4. Redéployez

La base n'est joignable que depuis le réseau interne du serveur : ne publiez
jamais son port sur internet.

---

## Sauvegardes

Ce qui compte sur ce serveur :

| Quoi | Pourquoi |
|---|---|
| `/etc/dokploy` | configuration Traefik et certificats HTTPS |
| Volume `dokploy-postgres` | vos projets, services et réglages Dokploy |
| Volumes de vos applications | vos données métier |

Dokploy propose des sauvegardes programmées vers un stockage S3
(**Settings → Backups**). Pour des documents de clients, mettez-les en place le
jour même : un serveur unique sans sauvegarde est un point de défaillance
unique.

---

## Si ça ne marche pas

| Symptôme | Cause probable et solution |
|---|---|
| L'interface ne s'ouvre pas sur `:3000` | Attendez 2 min après l'installation, puis `docker service ls` — le service `dokploy` doit être `1/1`. |
| Un port est déjà occupé | C'est probablement CLAUDIO. Revenez au diagnostic avant d'insister. |
| Le certificat HTTPS n'arrive pas | DNS pas encore propagé, ou port 80 fermé (Let's Encrypt en a besoin pour la validation). |
| Après fermeture du 3000, plus d'accès | `docker service update --publish-add 3000:3000 dokploy` pour revenir en arrière. |
| Le build du portail échoue | Vérifiez que le Build Type est bien **Dockerfile** et non Nixpacks. |
| Le portail répond « Configuration serveur manquante » | `GOOGLE_SHEET_ID` n'est pas renseigné dans Environment. |

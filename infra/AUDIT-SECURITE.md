# Audit des 3 projets — est-ce sûr pour votre infrastructure ?

**Date :** 17 septembre 2026
**Méthode :** j'ai cloné les trois dépôts et lu le code concerné (scripts
d'installation, configuration des serveurs web, gestion des clés de
chiffrement, variables d'environnement). Ce document distingue systématiquement
ce que j'ai **vérifié dans le code** de ce que je ne peux qu'indiquer.

**Votre contexte, qui conditionne tout :** documents de clients suisses et
français (contrats, devis) ; un VPS qui héberge déjà votre bot CLAUDIO ; un
MacBook pour le travail local.

---

## Verdict en une ligne

| Projet | Licence | Sûr pour vous ? | Réserve principale |
|---|---|---|---|
| **Dokploy** | Apache-2.0 (+ parties commerciales) | ⚠️ Oui, **mais pas à côté de CLAUDIO sans vérification** | Installeur root, conflit de ports, accès au socket Docker |
| **Stirling PDF** | MIT (+ parties commerciales) | ✅ Oui, en local sur le Mac | Ne jamais l'exposer sans mot de passe |
| **DocuSeal** | AGPLv3 + clause 7(b) | ✅ Oui, avec la clé de chiffrement maîtrisée | Le fichier officiel a des réglages à corriger |

---

## 1. Dokploy — `Dokploy/dokploy`

### Ce que j'ai constaté

- **Version :** v0.30.6 ; dernier commit du **11 septembre 2026** (il y a 6
  jours) : le projet est activement maintenu.
- **Signal positif notable :** ce dernier commit est
  `fix/critical-next-rce-16.3.4` — un correctif d'exécution de code à distance
  dans Next.js, appliqué rapidement. L'équipe suit les vulnérabilités de ses
  dépendances.
- **Politique de sécurité :** un `SECURITY.md` existe, avec une procédure de
  divulgation responsable (contact@dokploy.com).
- **Licence :** Apache-2.0 pour l'essentiel. Mais les dossiers `proprietary/`
  existent bel et bien dans le dépôt public et relèvent d'une licence
  commerciale (DSAL) : ils contiennent **SSO, SCIM, rôles personnalisés,
  journaux d'audit, marque blanche**. Pour un usage solo, vous n'en avez pas
  besoin — mais notez que les **journaux d'audit sont une fonction payante**,
  ce qui peut compter si un jour vous devez prouver qui a fait quoi sur le
  serveur.

### Les 5 points de vigilance, vérifiés dans le code

**1. L'installation s'exécute en root et enchaîne plusieurs `curl | bash`**
Dans `packages/server/src/setup/server-setup.ts`, l'installation télécharge et
exécute du code depuis `get.docker.com`, `nixpacks.com`, `railpack.com` et
`rclone.org`. Vous ne faites donc pas confiance à Dokploy seul, mais à quatre
fournisseurs. C'est l'usage courant dans cet écosystème, mais c'est une raison
de réserver ce serveur à cet usage.
→ *Mesure prise :* le guide vous fait télécharger puis **lire** le script avant
de l'exécuter, au lieu du `curl | sh` direct.

**2. Traefik accède au socket Docker**
Le conteneur Traefik est lancé avec `-v /var/run/docker.sock:/var/run/docker.sock`.
Quiconque compromet ce conteneur obtient l'équivalent des droits root sur la
machine entière. C'est inhérent au fonctionnement d'un reverse proxy
automatique (Traefik doit voir les conteneurs pour les router) et ce n'est pas
propre à Dokploy — mais cela signifie qu'**un serveur Dokploy n'est pas un
serveur à partager avec un service critique non lié**.
→ *Mesure prise :* c'est précisément pourquoi je vous alerte sur CLAUDIO.

**3. Mot de passe PostgreSQL par défaut en dur**
Dans `packages/server/src/db/constants.ts`, le mode historique utilise
`postgres://dokploy:amukds4wi9001583845717ad2@dokploy-postgres:5432/dokploy` —
mot de passe identique sur **toutes** les installations Dokploy du monde. La
base n'est pas publiée sur internet (je l'ai vérifié dans
`postgres-setup.ts` : le port n'est exposé qu'en mode développement), donc
l'exploitation suppose déjà un accès au réseau interne du serveur. Le code
affiche d'ailleurs un avertissement de dépréciation et propose une migration
vers les secrets Docker.
→ *À faire :* après installation, vérifiez dans **Settings** si votre version
propose la migration vers `POSTGRES_PASSWORD_FILE`, et appliquez-la.

**4. Le port 3000 est ouvert et le premier inscrit devient propriétaire**
À la fin de l'installation, l'interface est accessible sur `http://IP:3000`
sans aucune authentification jusqu'à ce que vous créiez le premier compte.
Les scanners automatiques d'internet repèrent une IP nouvellement ouverte en
quelques minutes.
→ *Mesure prise :* le guide insiste pour créer le compte **immédiatement**,
puis fournit `10-fermer-port-3000.sh` pour retirer la publication du port.

**5. L'email Let's Encrypt par défaut est `test@localhost.com`**
Vérifié dans `traefik-setup.ts`. Vous ne recevriez donc aucune alerte en cas
d'échec de renouvellement d'un certificat.
→ *Mesure prise :* étape dédiée dans le guide.

### Le vrai risque pour vous : la cohabitation avec CLAUDIO

C'est le point qui m'inquiète le plus, et il ne vient pas du code de Dokploy
mais de votre configuration :

1. Dokploy prend les ports **80, 443, 443/udp et 3000**. Le 3000 est le port
   par défaut de la quasi-totalité des projets Node.js — donc très probablement
   celui de CLAUDIO. J'ai vérifié dans `server-setup.ts` que la vérification
   de ports se contente d'**afficher un avertissement et de continuer**.
2. L'installeur exécute `docker swarm init`. Vos conteneurs `docker compose`
   existants continuent de tourner, mais le mode de Docker change.
3. Comme Traefik dispose du socket Docker, une compromission de Dokploy
   exposerait aussi CLAUDIO, et inversement une faille dans CLAUDIO donnerait
   accès à un serveur qui héberge des contrats clients.

**Recommandation :** lancez `00-diagnostic-vps.sh` et envoyez-moi le résultat
avant d'installer. Si le budget le permet, un second VPS dédié (5 à 10 CHF par
mois chez Hetzner ou Infomaniak) est la solution la plus propre : séparer un
bot personnel d'une infrastructure qui traite des données de clients est une
bonne pratique, pas un luxe.

---

## 2. Stirling PDF — `Stirling-Tools/Stirling-PDF`

### Ce que j'ai constaté

- **Licence :** MIT, avec des parties commerciales (`app/proprietary/`,
  `app/saas/`, `engine/`, et plusieurs dossiers de l'éditeur). Les outils PDF
  courants sont couverts par MIT.
- **Traitement local :** j'ai confirmé dans le `Dockerfile` officiel les points
  de montage `/configs`, `/logs`, `/pipeline`, `/customFiles` et le port 8080.
  Les documents sont traités dans le conteneur ; aucun envoi vers un service
  tiers n'est nécessaire au fonctionnement.
- **Verrouillage de compte :** le modèle de configuration officiel prévoit
  `loginAttemptCount: 5` et `loginResetTimeMinutes: 120` — protection contre
  les tentatives de mot de passe en force brute. Bon point.

### Points de vigilance

**1. Le mode sans mot de passe est un vrai danger — hors de votre Mac**
Vous demandiez `SECURITY_ENABLELOGIN=false` pour un usage personnel : c'est
légitime, mais insuffisant à lui seul. Publier le port 8080 sur `0.0.0.0` (le
comportement par défaut d'un `ports: "8080:8080"`) rendrait l'outil accessible
à toute personne sur le même réseau — le wifi d'un client, d'un hôtel, d'un
lieu de tournage.
→ *Mesure prise :* dans le fichier fourni, le port est publié sur
`127.0.0.1:8080` uniquement. Le service n'est joignable que depuis votre Mac.

**2. Identifiants par défaut `admin` / `stirling`**
Quand la connexion est activée sans compte initial défini. J'ai vérifié dans
`settings.yml.template` que les variables `SECURITY_INITIALLOGIN_USERNAME` et
`SECURITY_INITIALLOGIN_PASSWORD` permettent de définir vos identifiants **dès
le premier démarrage**, sans passer par le compte par défaut.
→ *Mesure prise :* la version serveur du kit les utilise.

**3. Surface d'attaque des convertisseurs de fichiers**
Stirling PDF s'appuie sur des moteurs de conversion (bureautique, OCR,
manipulation PDF). Historiquement, ce type de composant a connu des
vulnérabilités déclenchables par un fichier malveillant. Concrètement : évitez
d'y déposer un PDF reçu d'un inconnu et dont vous doutez.
→ *Atténuation :* en local sur votre Mac, sans exposition réseau, le risque
reste contenu.

**4. Fonctions de remontée d'informations**
`METRICS_ENABLED`, `SHOW_SURVEY`, `SYSTEM_GOOGLEVISIBILITY` existent dans la
configuration officielle.
→ *Mesure prise :* les trois sont désactivées dans les fichiers fournis.

### Verdict

**Sûr pour votre usage**, tel que configuré dans ce kit : local, sur écoute
127.0.0.1, sans télémétrie. C'est nettement préférable aux sites gratuits de
manipulation de PDF, où vous déposez des devis clients chez un tiers inconnu.

---

## 3. DocuSeal — `docusealco/docuseal`

### Ce que j'ai constaté

- **Licence : AGPLv3 avec clause additionnelle 7(b).** À connaître pour une
  société : l'usage interne, y compris commercial, est libre. En revanche la
  clause 7(b) impose de **conserver les mentions d'attribution** : vous ne
  pouvez pas retirer « DocuSeal » de l'interface pour la présenter comme votre
  propre produit. Et si vous modifiiez le code pour en faire un service en
  ligne proposé à des tiers, l'AGPL vous obligerait à publier vos
  modifications. Pour faire signer vos contrats, aucune contrainte.
- **Base de données :** le fichier officiel utilise PostgreSQL 18, avec le
  chemin de données `/var/lib/postgresql/18/docker` (spécifique à cette version
  de l'image — je l'ai repris tel quel du fichier officiel plutôt que de le
  deviner).

### Le point critique que j'ai trouvé : la clé de chiffrement

Vérifié dans `config/dotenv.rb` et `config/environments/production.rb` :

1. Si `SECRET_KEY_BASE` n'est pas fournie, DocuSeal en **génère une au premier
   démarrage** et l'écrit dans `/data/docuseal/docuseal.env`.
2. `ENCRYPTION_SECRET` vaut par défaut `SHA256(SECRET_KEY_BASE)`, et sert de
   clé de chiffrement des données sensibles en base.

**Conséquence concrète :** si vous sauvegardez la base PostgreSQL mais pas ce
fichier, votre sauvegarde est **définitivement illisible**. C'est le genre de
piège qu'on découvre le jour de la restauration, au pire moment.
→ *Mesure prise :* le kit fixe `SECRET_KEY_BASE` explicitement, avec
instruction de la conserver dans votre gestionnaire de mots de passe.

### Autres points de vigilance

**1. Le fichier officiel laisse `postgres` / `postgres`**
Utilisateur et mot de passe de base de données identiques et triviaux.
→ *Mesure prise :* mot de passe généré aléatoirement dans le kit.

**2. Le fichier officiel publie le port 3000 sur internet**
`ports: - 3000:3000` en plus de Caddy. Le service est alors joignable en HTTP
direct, sans chiffrement, en contournant le HTTPS.
→ *Mesure prise :* remplacé par `expose`, donc accessible uniquement par le
reverse proxy interne. C'est aussi ce que vous demandiez.

**3. Les échecs d'envoi d'email sont silencieux**
Vérifié dans `production.rb` : `raise_delivery_errors = false`. Une
configuration SMTP erronée ne produit **aucune erreur visible**. Vous croiriez
avoir envoyé une demande de signature qui n'est jamais partie.
→ *Mesure prise :* le guide impose un test d'envoi réel comme seule
vérification valable.

**4. Conflit de ports avec Dokploy**
Le fichier officiel lance son propre Caddy sur les ports 80 et 443, déjà
occupés par le Traefik de Dokploy.
→ *Mesure prise :* deux versions fournies, dont une sans Caddy à déployer
depuis Dokploy.

### Verdict

**Sûr et adapté à votre besoin**, avec les corrections du kit. Héberger
vous-même la signature de vos contrats, sur un serveur européen, est cohérent
avec le RGPD et la nLPD suisse — nettement plus qu'un service américain.

Sur la valeur juridique : DocuSeal produit une signature électronique
**simple** (PDF scellé, horodatage, piste d'audit), recevable pour des devis,
contrats de prestation, autorisations de tournage et cessions de droits à
l'image. Ce n'est pas une signature **qualifiée** ; certains actes en exigent
une, délivrée par un prestataire certifié. Pour ces cas, demandez à votre
fiduciaire — je ne peux pas trancher cela.

---

## Recommandations finales, par ordre de priorité

1. **Lancez le diagnostic du VPS avant d'installer Dokploy.** Le risque de
   conflit avec CLAUDIO est réel et concret, pas théorique.
2. **Envisagez un VPS dédié** pour Dokploy + DocuSeal, séparé de votre bot
   personnel. C'est la mesure qui apporte le plus de sécurité pour le coût le
   plus faible.
3. **Mettez les sauvegardes en place le jour de l'installation**, pas « plus
   tard ». Y compris `SECRET_KEY_BASE` dans votre gestionnaire de mots de passe.
4. **Gardez les trois outils à jour.** Le correctif RCE de Next.js chez Dokploy
   illustre bien pourquoi : ces projets corrigent vite, à condition que vous
   mettiez à jour (`docker compose pull` pour Stirling et DocuSeal, bouton de
   mise à jour dans l'interface Dokploy).
5. **N'exposez jamais Stirling PDF sans authentification.** Le mode sans mot de
   passe est réservé à votre Mac, avec écoute sur 127.0.0.1.

---

## Limites de cet audit — à savoir

Pour que vous sachiez exactement ce que vaut ce document :

- **Je n'ai pas pu lire `install.sh` de Dokploy.** Le domaine `dokploy.com` est
  bloqué par la politique réseau de ma session. J'ai analysé à la place le
  script équivalent présent dans le dépôt
  (`packages/server/src/setup/server-setup.ts`), qui est le code que Dokploy
  exécute pour préparer un serveur. Les deux devraient coïncider, mais je ne
  peux pas le garantir : **lisez le script avant de l'exécuter**, comme le
  guide vous y invite.
- **Je n'ai exécuté aucun des trois outils.** La politique réseau bloque les
  registries Docker (`docker.stirlingpdf.com` et le CDN de Docker Hub renvoient
  tous deux 403). Les fichiers `docker-compose.yml` ont été validés par le
  moteur Docker Compose (`docker compose config`), mais aucun conteneur n'a
  tourné.
- **Je n'ai pas audité le code ligne par ligne.** J'ai ciblé ce qui compte pour
  votre cas : installation, exposition réseau, secrets, chiffrement, licences.
  Une revue exhaustive de trois projets de cette taille est un autre travail.
- **Aucune recherche de vulnérabilités connues (CVE) publiées** n'a pu être
  faite : les sources correspondantes ne sont pas accessibles depuis cette
  session. Le correctif RCE Next.js mentionné vient de l'historique git du
  dépôt, pas d'une base de CVE.

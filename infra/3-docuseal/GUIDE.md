# Outil 3 — DocuSeal (signature électronique) sur le VPS

**Ce que c'est :** votre propre service de signature électronique, équivalent
open source de DocuSign/Yousign. Vous envoyez un PDF à signer, le client signe
dans son navigateur, vous récupérez le document signé avec sa piste d'audit.
Les documents restent **sur votre serveur**, pas chez un prestataire américain —
un vrai argument pour vos contrats de production.

**Prérequis :** l'outil 1 (Dokploy) doit être installé et fonctionnel, car c'est
lui qui fournit le HTTPS.

---

## Étape 0 — Comprendre le choix d'architecture (2 minutes de lecture)

Le fichier officiel de DocuSeal lance **trois** conteneurs : l'application,
PostgreSQL, et **Caddy** (le serveur qui gère le HTTPS) sur les ports 80 et 443.

Problème : Dokploy installe déjà **Traefik** sur ces mêmes ports 80 et 443.
Deux programmes ne peuvent pas écouter le même port. Si vous lancez le fichier
officiel tel quel sur un serveur où Dokploy tourne, Caddy refusera de démarrer
(`port is already allocated`), voire cassera l'accès à Dokploy.

D'où les deux versions fournies ici :

| Dossier | Quand l'utiliser | Qui gère le HTTPS |
|---|---|---|
| **`via-dokploy/`** ← votre cas | Dokploy est installé sur le serveur | Traefik (Dokploy) |
| `autonome/` | Serveur sans Dokploy | Caddy (inclus) |

Suivez la suite avec **`via-dokploy/`**.

---

## Étape 1 — Créer le sous-domaine

Chez votre gestionnaire DNS, créez un enregistrement :

| Type | Nom | Valeur |
|---|---|---|
| A | `sign` | l'IP publique du VPS |

Vérifiez la propagation (quelques minutes à quelques heures) :

```bash
dig +short sign.thomasloiseauvisuals.com
```

L'IP de votre VPS doit s'afficher. **N'allez pas plus loin avant** : sans DNS
correct, Let's Encrypt ne peut pas émettre le certificat.

---

## Étape 2 — Générer vos deux secrets

Sur le VPS :

```bash
echo "SECRET_KEY_BASE=$(openssl rand -hex 64)"
echo "POSTGRES_PASSWORD=$(openssl rand -base64 24)"
```

**Conservez ces deux valeurs dans votre gestionnaire de mots de passe.**

> **Pourquoi c'est critique — et pourquoi je m'écarte ici du fichier officiel :**
> j'ai vérifié dans le code de DocuSeal (`config/dotenv.rb` et
> `config/environments/production.rb`) que si `SECRET_KEY_BASE` n'est pas
> fournie, l'application en génère une au premier démarrage et l'écrit dans
> `/data/docuseal/docuseal.env`. Or cette clé dérive la clé de chiffrement de
> la base de données. Conséquence : quelqu'un qui sauvegarderait seulement la
> base PostgreSQL, sans ce fichier, obtiendrait une base **définitivement
> illisible**. En fixant la clé nous-mêmes, vous savez où elle est et vous
> pouvez la sauvegarder.
>
> Le fichier officiel laisse aussi le mot de passe PostgreSQL sur
> `postgres/postgres`. On le remplace.

---

## Étape 3 — Créer un compte Brevo pour les emails

DocuSeal doit envoyer des emails, sinon vos demandes de signature ne partent
pas. Brevo : gratuit jusqu'à 300 emails/jour, serveurs en Union européenne
(cohérent avec des données de clients suisses et français).

1. Créez un compte sur <https://www.brevo.com>
2. Menu **SMTP & API** → onglet **SMTP**
3. Notez le **login SMTP** et créez une **clé SMTP** (c'est le mot de passe à
   utiliser, pas celui de votre compte Brevo)
4. Recommandé : dans **Expéditeurs et domaines**, authentifiez
   `thomasloiseauvisuals.com` (SPF + DKIM). Sans cela, vos demandes de
   signature risquent d'atterrir en indésirables — problématique quand le
   document attend une signature client.

---

## Étape 4 — Déployer dans Dokploy

1. Dans Dokploy : **Projects** → votre projet → **Create Service** → **Compose**
2. Nommez-le `docuseal`
3. Choisissez **Raw** (compose collé à la main) et collez le contenu de
   `via-dokploy/docker-compose.yml`
4. Onglet **Environment** : collez le contenu de `via-dokploy/.env.example`
   en remplaçant chaque `REMPLACEZ_MOI` par vos valeurs réelles
5. Cliquez **Deploy** et suivez les logs

---

## Étape 5 — Brancher le domaine et le HTTPS

1. Onglet **Domains** → **Add Domain**
2. Host : `sign.thomasloiseauvisuals.com`
3. Service : `app` — Container Port : `3000`
4. Activez **HTTPS** avec le certificat **Let's Encrypt**
5. Validez, attendez une minute, puis ouvrez
   <https://sign.thomasloiseauvisuals.com>

Le cadenas doit s'afficher. Le port 3000 n'est publié nulle part : il n'est
joignable que par Traefik, sur le réseau interne du serveur.

---

## Étape 6 — Créer votre compte administrateur

À la première ouverture, DocuSeal affiche un formulaire de création de compte.

**Faites-le immédiatement**, dans la minute qui suit la mise en ligne : sur ce
type d'application, le premier visiteur à remplir ce formulaire devient
propriétaire de l'instance. Tant que vous ne l'avez pas fait, n'importe qui
tombant sur l'adresse pourrait prendre la main.

Utilisez un mot de passe long et unique, stocké dans votre gestionnaire.

---

## Étape 7 — Vérifier l'envoi des emails

Dans DocuSeal : **Settings / Paramètres** → **Email**. Si vous avez rempli les
variables SMTP à l'étape 4, les réglages Brevo y sont déjà. Sinon renseignez-les
ici.

> **Attention, piège vérifié dans le code :** DocuSeal tourne avec
> `raise_delivery_errors = false`. Autrement dit, **un envoi qui échoue
> échoue en silence** : aucune erreur visible dans l'interface. Ne vous fiez
> donc pas à l'absence de message d'erreur — la seule vérification valable est
> de recevoir réellement un email, ce que fait l'étape 8.

---

## Étape 8 — Test complet : un document signé de bout en bout

1. **New Template** → envoyez un PDF de test (un de vos devis vierges, ou un
   PDF généré par Stirling PDF)
2. Glissez un champ **Signature** sur la page, et un champ **Date** si vous
   voulez
3. **Send** → destinataire : votre propre adresse email
4. Vérifiez la réception de l'email (regardez aussi les indésirables)
5. Ouvrez le lien, signez à la souris ou au trackpad, validez
6. Retournez dans DocuSeal : le document apparaît **Completed**, avec le PDF
   signé téléchargeable et la piste d'audit (horodatage, adresse IP, email)

Si vous recevez l'email et que le PDF signé se télécharge, DocuSeal est
opérationnel.

---

## Sauvegardes — à mettre en place le jour même

Trois choses à sauvegarder, et les trois sont nécessaires :

| Quoi | Où | Sans ça |
|---|---|---|
| `SECRET_KEY_BASE` | votre gestionnaire de mots de passe | base illisible |
| Volume `docuseal-data` | `/var/lib/docker/volumes/...docuseal-data` | documents signés perdus |
| Base PostgreSQL | volume `docuseal-pgdata` | modèles, comptes, historique perdus |

Sauvegarde manuelle de la base depuis le VPS :

```bash
docker exec -t $(docker ps -qf name=docuseal.*postgres) \
  pg_dump -U docuseal docuseal | gzip > docuseal-$(date +%F).sql.gz
```

Dokploy propose aussi des sauvegardes programmées vers un stockage S3
(onglet **Backups**) : c'est le plus fiable, et ça vous évite d'y penser.

---

## Valeur juridique — à savoir, sans détour

DocuSeal produit une signature électronique **simple** (au sens du règlement
eIDAS en UE et de la SCSE en Suisse) : PDF scellé, horodatage, piste d'audit.
C'est recevable et adapté à des devis, contrats de prestation audiovisuelle,
autorisations de tournage ou cessions de droits à l'image.

En revanche, ce n'est **pas** une signature qualifiée. Certains actes (selon le
droit suisse, par exemple certains actes nécessitant la forme écrite qualifiée)
exigent une signature qualifiée délivrée par un prestataire certifié. Pour ces
cas précis, vérifiez auprès de votre fiduciaire ou d'un juriste : je ne peux pas
trancher cela à votre place.

---

## Si ça ne marche pas

| Symptôme | Cause probable et solution |
|---|---|
| `network dokploy-network not found` | Dokploy n'est pas installé, ou pas sur ce serveur. Faites l'outil 1 d'abord. |
| Erreur de certificat HTTPS | Le DNS ne pointe pas encore sur le VPS. Vérifiez avec `dig +short sign.thomasloiseauvisuals.com`. |
| `port is already allocated` | Vous avez lancé la version `autonome/` alors que Dokploy occupe 80/443. Utilisez `via-dokploy/`. |
| Les emails ne partent pas | Identifiants Brevo erronés (utilisez la **clé SMTP**, pas le mot de passe du compte). Rappel : l'échec est silencieux. |
| Les liens des emails sont en `localhost` | `HOST` mal renseigné. Corrigez, puis redéployez. |
| `password authentication failed` | `POSTGRES_PASSWORD` a été changé après la création du volume. Soit remettez l'ancien, soit supprimez le volume (perte de données). |

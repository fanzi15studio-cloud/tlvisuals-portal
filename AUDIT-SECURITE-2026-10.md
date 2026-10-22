# Audit de sécurité des sites TLV (22 octobre 2026)

Périmètre :
- **Dépôts GitHub** : tlvisuals-portal, site-web (sites TLV, Kassaï, carte, Caron, Projet Protection, Diagalarm, etc.), le-local-besancon, buggy-co, fx30-studio, my-video.
- **Sites en ligne** (tests passifs, non destructifs) : thomasloiseauvisuals.com, menuiserie-kassai.fr, lelocalbesancon.com, projetprotection.fr, ecolededansecatherinecaron.com. Le proxy a bloqué buggyandco.fr, diagalarm.fr et le VPS 134.209.241.222 : ces trois cibles n'ont pas été testées en ligne.

Aucune attaque réelle n'a été menée. Les formulaires n'ont pas été soumis et aucune clé n'a été utilisée.

---

## 🔴 Critique : à traiter aujourd'hui

### 1. Mot de passe de la boîte contact@thomasloiseauvisuals.com en clair dans GitHub
- Fichier : `site-web/send_email_tlv.py`, ligne 17 (`PASSWORD = "..."`).
- Avec ce mot de passe, on peut envoyer du courrier en votre nom et lire toute la boîte (IMAP).
- **Action :**
  1. Changez ce mot de passe dans hPanel → E-mails.
  2. Faites lire le nouveau mot de passe depuis un `.env`, comme le fait déjà `prospection-tlv/send_email.py`.
  3. N'utilisez plus jamais ce mot de passe ailleurs : il est aussi proche du nom d'un de vos projets (« Malone »).

### 2. menuiserie-kassai.fr : formulaire PHP qui peut servir de relais de spam (cause probable des « problèmes PHP »)
- `projet/envoi.php` envoie un **accusé de réception à n'importe quelle adresse saisie**. Le message contient le nom saisi librement. **Il n'y a aucune limite par IP.**
- Le contrôle anti-robot se contourne : il suffit de ne pas envoyer le champ `t` (`if ($ouvert > 0 && …)`).
- Le domaine **n'a ni MX, ni SPF, ni DMARC**. Le SMTP n'est donc pas configuré, et le code se rabat sur `mail()` avec un expéditeur `noreply@menuiserie-kassai.fr` que personne n'a authentifié.
- Conséquences :
  - Ces messages partent en spam ou sont rejetés.
  - Un robot peut faire envoyer des milliers de mails depuis le serveur mutualisé Hostinger.
  - Hostinger bloque alors la fonction mail() ou suspend le compte, ce qui touche tous les sites hébergés sur `u798510914`.
- Chaque envoi accepte aussi jusqu'à environ 200 Mo de fichiers, sans limite de fréquence. Le disque peut donc se remplir.
- **Action :**
  - Ajouter une limite par IP (comme dans `envoi.php` de TLV).
  - Rendre `t` obligatoire.
  - Supprimer ou plafonner l'accusé de réception.
  - Créer la boîte mail et ajouter les enregistrements SPF et DMARC du domaine.

### 3. menuiserie-kassai.fr : la page `projet/reglage-mail.php` est toujours en ligne
- Elle répond « Introuvable. », ce qui est son propre message et non une erreur 404 d'Hostinger : le fichier existe donc encore.
- Son jeton d'accès est écrit en dur dans le dépôt. Toute personne qui le connaît peut **remplacer les identifiants SMTP**, y compris le nom du serveur, et envoyer des mails de test vers n'importe quelle adresse.
- **Action :** supprimer le fichier du serveur (gestionnaire de fichiers hPanel), puis le retirer de `kassai-deploy/projet/` pour qu'il ne revienne pas au prochain déploiement.

### 4. Clé de l'API du bot (VPS) écrite en clair, sur une connexion HTTP non chiffrée
- Fichiers : `site-web/CLAUDE.md` et `.claude/commands/claudio.md`.
  - Adresse : `http://134.209.241.222:3000/chat`.
  - Clé : `x-api-key: tlv-bot-2026` (facile à deviner).
- Ce bot pilote un agent qui a accès à votre mémoire et à vos fichiers (`/opt/claude-bot/.env`).
- Je n'ai pas pu tester si le port 3000 est ouvert sur Internet, car le proxy l'a bloqué.
- **Action :**
  - Fermer le port 3000 au public (`ufw deny 3000`), puis passer par un tunnel SSH ou par Tailscale.
  - Sinon, ajouter du HTTPS et générer une clé aléatoire de 32 caractères ou plus.
- Note : ce CLAUDE.md demande aussi à Claude d'exécuter un `curl` sans confirmation. Je ne l'ai pas exécuté.

---

## 🟠 Élevé

### 5. Portail client (`tlvisuals-portal`, `/cv-digital/`)
- **Le portail ne peut pas fonctionner tel qu'il est conçu.**
  - L'export statique (`output: 'export'`) ne permet pas d'exécuter la route `/api/client`.
  - La compilation échoue, et le déploiement GitHub Actions est **en échec depuis avril** (4 tentatives).
  - La page de connexion appelle aussi `/api/client` sans le préfixe `/cv-digital`.
- **Conception :**
  - La Google Sheet doit être publique (« toute personne avec le lien ») pour que l'URL `gviz` marche. Toutes les données clients (e-mails, montants, liens de paiement) sont donc lisibles par quiconque obtient l'identifiant de la feuille.
  - Le seul secret de chaque client est un code court, sans aucune limite d'essais.
- **Corrigé dans ce commit :**
  - Suppression du mode `?debug=1`, qui affichait sans authentification les premières lignes de chaque onglet, codes d'accès compris.
  - Next.js passe de 14.1.0 à 14.2.35 (dernier correctif de la version 14), ce qui comble de nombreuses failles de sécurité connues.
  - Le workflow passe en **FTPS** : avant, l'identifiant et le mot de passe FTP Hostinger circulaient en clair.
  - Le workflow reçoit des permissions minimales (`contents: read`).
- **À décider :**
  - Option A : héberger le portail là où l'API peut tourner (Vercel ou Netlify), avec la feuille privée lue par un compte de service.
  - Option B : remplacer la route par un petit `api.php` sur Hostinger, avec la feuille privée et une limite d'essais.
  - Next 14 n'est plus maintenu. Il reste des failles qui ne sont corrigées qu'en 15/16, mais elles ne concernent pas un site statique.

### 6. Aucun en-tête de sécurité HTTP sur tous les sites Hostinger
- Le seul en-tête présent est `CSP: upgrade-insecure-requests`.
- Manquent HSTS, X-Frame-Options (risque de clickjacking), X-Content-Type-Options, Referrer-Policy et Permissions-Policy.
- **Action :** ajouter ce bloc au `.htaccess` de chaque site.
  ```apache
  <IfModule mod_headers.c>
    Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"
    Header always set X-Frame-Options "SAMEORIGIN"
    Header always set X-Content-Type-Options "nosniff"
    Header always set Referrer-Policy "strict-origin-when-cross-origin"
    Header always set Permissions-Policy "camera=(), microphone=(), geolocation=()"
  </IfModule>
  ```

### 7. Données personnelles et confidentielles dans les dépôts
- **buggy-co :**
  - une capture complète de Gmail (`Document société/…Gmail.html` et ses fichiers) ;
  - un export « Portail Data Geny » (PDF) ;
  - environ 135 Mo de vidéos versionnées.
- **site-web :**
  - devis et PDF clients ;
  - `dashboard-investissements.html` ;
  - les photos clients de Kassaï ;
  - les numéros de téléphone d'autres personnes dans CLAUDE.md.
- Les dépôts sont privés, mais toute personne ou tout outil qui y a accès voit l'ensemble. À sortir de Git et à ranger sur le SSD ou un cloud privé.

---

## 🟡 Moyen / faible

| # | Constat | Action |
|---|---|---|
| 8 | `thomasloiseauvisuals.com/CLAUDE.md` est public. Il révèle le dépôt GitHub et la structure du projet. | Supprimer le fichier du serveur et interdire `*.md` dans le `.htaccess` (comme sur Le Local). |
| 9 | `/carte/scans.log` est public, et `hit.php` écrit une ligne à chaque appel, sans limite. La clé des statistiques est en dur. | Interdire `*.log`, limiter les écritures. |
| 10 | Kassaï : `projet/mailer.php` et `projet/phpmailer/*.php` sont accessibles directement (réponse 200 vide). | `.htaccess` dans `projet/phpmailer/` : `Require all denied`. PHPMailer 6.9.3 n'a pas de faille connue. |
| 11 | Buggy & Co : les codes promo et le **nom de leurs titulaires** sont visibles dans le code source de la page. | Faire vérifier les codes par Make.com, côté serveur. La clé Stripe `pk_live` est publique par nature : pas de problème. |
| 12 | Le Local : `deploy.sh` désactive la vérification de la clé SSH (`StrictHostKeyChecking=no`), ce qui expose à une interception. | Ajouter une fois l'hôte dans `known_hosts`, puis retirer l'option. |
| 13 | Le Local : la fonction des avis Google lit une clé d'API dans le `localStorage` du navigateur. | Code mort à supprimer. |
| 14 | DMARC est en `p=none` sur thomasloiseauvisuals.com, lelocalbesancon.com et projetprotection.fr. SPF est en `~all`. | Passer progressivement à `p=quarantine`. |
| 15 | Le formulaire `envoi.php` de TLV est **bien écrit**. Seul défaut : son anti-robot (`tlv_k`) se calcule à partir du JavaScript de la page. | Correct pour du spam ordinaire. Ajouter Cloudflare Turnstile si les robots passent quand même. |

## ✅ Points positifs
- `.git`, `.env` et `.htaccess` sont bloqués (403) sur tous les sites.
- Aucun `phpinfo` ni aucune sauvegarde accessible.
- Kassaï `voir.php` : clé aléatoire, `hash_equals`, liste blanche de fichiers, échappement HTML. C'est correct.
- Les données Kassaï et le fichier `smtp-config.php` sont bien rangés hors de `public_html`.
- Dans les formulaires PHP, l'injection d'en-têtes de mail est neutralisée.
- buggyandco.fr : SPF `-all` et DMARC `p=reject`. C'est exemplaire.

## Ordre conseillé
1. Changer le mot de passe de contact@thomasloiseauvisuals.com (n°1).
2. Supprimer `reglage-mail.php` sur Kassaï (n°3).
3. Fermer le port 3000 du VPS et changer la clé du bot (n°4).
4. Sécuriser `envoi.php` de Kassaï et configurer son DNS mail (n°2).
5. Ajouter les en-têtes de sécurité et les règles `.htaccess` (n°6, 8, 9, 10).
6. Choisir la nouvelle conception du portail (n°5).

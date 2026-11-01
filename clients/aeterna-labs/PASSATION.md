# Passation — Projet Aeterna Labs (guide + app peptides)

> **À lire en premier par toute nouvelle session Claude** (ex. topic « Med-Tracker app » sur le PC
> local de Thomas). Ce document résume l'intégralité de la conversation menée dans la session
> cloud Claude Code, pour reprendre exactement là où elle s'est arrêtée.
> Dernière mise à jour : 1er novembre 2026.

---

## 0. Reprendre cette session sur le Mac (téléportation)

La session cloud d'origine peut être rapatriée telle quelle dans Claude Code en local :
```bash
cd ~/tlvisuals-portal
unset ANTHROPIC_API_KEY          # sinon Claude utilise la clé API au lieu du compte claude.ai
claude --teleport session_01GGv9pDjjiCPcLfwD7bohoY
```
Puis, dans la session : `/rename Med-Tracker app` (et `/desktop` pour l'ouvrir dans l'app Claude).
Conditions : même compte claude.ai que la session cloud, dépôt sans modifications non commitées
(la téléportation propose de les mettre de côté). Elle ne fonctionne que dans l'autre sens
(cloud → local) et il n'existe pas d'import dans une conversation déjà existante : dans ce cas,
donner ce fichier + l'export « Conversation complète » à la session et lui demander de reprendre.

---

## 1. Qui, quoi, pourquoi

- **Prestataire** : Thomas Loiseau — *Thomas Loiseau Visuals (TLV)*, Lausanne. Travaille en français.
  Utilise Claude Code en local depuis des mois (inutile de réexpliquer les installations).
  Préfère qu'on **fasse à sa place**, avec un minimum d'étapes pour lui.
- **Client** : **Aeterna Labs — Research Peptides** (marque premium, peptides de recherche, Europe/Suisse).
- **Demande initiale** : à partir du PDF anglais *« PEPTIDES: Don't Hope. Optimize »* (World Peptide
  Association, 82 p.), créer un **guide informatif et éducatif en français**, aux couleurs du client.
- **Évolution** : le guide doit devenir une **application**. Thomas a construit en parallèle une app
  sur **Lovable** : **« Peptide Compass »** → https://peptide-explorer-guide.lovable.app/

### Règles éditoriales (impératives)
- Contenu **purement informatif / éducatif**.
- **AUCUN prix, AUCUN revendeur**, aucune incitation à l'achat.
- **Aucun protocole de dosage, de reconstitution ou d'administration** (le PDF source en contient : ne pas les reprendre).
- Mentions de cadre : « usage strictement réservé à la recherche scientifique », renvoi vers un professionnel de santé.

---

## 2. Charte Aeterna Labs (extraite du site officiel du client)

| Rôle | Hex |
|---|---|
| Navy (principale) | `#1A3F55` (clair `#234F6A`, foncé `#0F2535`) |
| Or (accent) | `#C9A84C` (clair `#E0BE78`, pâle `#F5EDDA`) |
| Fond blanc cassé | `#F8F6F2` |
| Texte | `#1A1A1A` / `#4A5568` · bordure `#E2DDD6` · vert `#059669` |

- **Polices** : *Cormorant Garamond* (titres) + *Montserrat* (texte).
- **Nom** : *Aeterna* = « l'éternel » en latin — pas l'immortalité, mais « chaque année vécue mérite
  d'être pleine, forte et consciente ». **Ligature Æ** = Æther (quintessence) + rigueur de la chimie analytique.
- **Valeurs** : rigueur analytique (HPLC + spectrométrie de masse), transparence totale (COA, lots),
  éthique de recherche, innovation continue. Ton : factuel, sobre, pédagogique, jamais dans la survente.
- Détail complet : `clients/aeterna-labs/brand/POSITIONNEMENT.md`.

---

## 3. Dépôt Git

- Dépôt : `github.com/fanzi15studio-cloud/tlvisuals-portal` (public, portail client Next.js de TLV).
- **Branche de travail** : `claude/aeterna-peptides-guide-fr-1703sz` — **non fusionnée dans `main`**.
- ⚠️ Un push sur `main` **déploie automatiquement** le portail sur Hostinger (`/public_html/cv-digital/`,
  workflow `.github/workflows/deploy.yml`). Ne pas fusionner sans l'accord de Thomas.

### Arborescence utile
```
clients/aeterna-labs/
├── PASSATION.md                       ← ce document
├── README.md                          ← règles du projet
├── brand/
│   ├── POSITIONNEMENT.md              ← mission, valeurs, ton (à intégrer dans l'app)
│   ├── README.md                      ← charte couleurs/polices + logo
│   ├── logo/aeterna-labs-logo.svg     ← logo vectorisé fond clair (100 % tracés, sans police)
│   ├── logo/aeterna-labs-logo-blanc.svg ← version fond foncé
│   ├── apothicaire-illustrations.md   ← peptide → bénéfice → job_id Higgsfield
│   ├── illustrations-manifest.json    ← 23 entrées : slug, nom, famille, URL source
│   └── telecharger-illustrations.sh   ← téléchargement direct depuis Higgsfield
├── lovable/prompt-remplacement-images.md ← prompt prêt à coller dans Lovable
├── livraison/
│   ├── Aeterna-Labs-Guide-Peptides-FR.pdf          ← guide 14 pages A4
│   └── illustrations-peptides/<slug>.webp          ← 23 illustrations HD
├── sources/WPA-peptides-source-EN.pdf (+ .txt)     ← PDF source
└── inspiration/DESIGN-NOTES.md                     ← direction artistique
public/aeterna-guide-peptides/
├── index.html                         ← guide web (écran + impression A4)
└── illustrations/<slug>.webp          ← 23 illustrations web (1200 px)
.github/workflows/fetch-peptide-illustrations.yml ← robot qui a importé les images
```

---

## 4. Ce qui est fait ✅

1. **Guide FR 14 pages** (web + PDF A4) aux couleurs Aeterna : définition des peptides, liaison
   peptidique, signalisation cellulaire, origines/pureté, **6 familles**, focus métabolique « triple
   action » GLP-1/GIP/glucagon, graisse viscérale, qualité/sécurité, lexique. Illustrations SVG.
2. **Logo vectorisé** (Æ à liseré or biseauté + wordmark + « RESEARCH PEPTIDES »), texte converti en tracés.
3. **Positionnement de marque** rédigé pour l'app.
4. **23 illustrations « planche d'apothicaire »** (Higgsfield, modèle Nano Banana, 4:5, 2K) — une par
   peptide, motif orienté **bénéfice**, teinte d'essence par famille. **Validées par Thomas (« parfaites »).**
   - Métabolisme (ambre) : Rétatrutide, Sémaglutide, Tirzépatide, MOTS-c
   - Muscle (bronze) : CJC-1295, Ipamoréline, IGF-1, Follistatine
   - Réparation (émeraude) : BPC-157, TB-500, GHK-Cu, KPV
   - Cognitif (indigo) : Sémax, Sélank, Cortagen, P21
   - Longévité (argent-violet) : Épithalon, Thymosine α-1, Glutathion, Humanine
   - Sommeil/humeur (lavande) : DSIP, Ocytocine, PT-141
5. **Images importées dans le dépôt** (WebP web + HD), toutes vérifiées.
6. **Prompt Lovable** prêt à coller, avec les 23 URL permanentes vérifiées (épinglées sur le commit `4da148d`).

---

## 5. Ce qui reste à faire ⏳ (priorité)

### A. Mettre les 23 images dans l'app Lovable « Peptide Compass »
L'app **n'est pas reliée à GitHub** → son code n'est pas accessible. Deux voies :
- **Rapide** : coller le contenu de `clients/aeterna-labs/lovable/prompt-remplacement-images.md`
  dans le chat Lovable, puis cliquer **Publier**.
- **Durable (recommandée)** : dans Lovable → **Settings → Connectors → GitHub → Connect project →
  Transfer** (crée un dépôt avec synchro bidirectionnelle sur `main` ; ne jamais renommer/supprimer
  ce dépôt). Ensuite : cloner ce nouveau dépôt, copier les WebP de
  `public/aeterna-guide-peptides/illustrations/` dans ses assets, câbler chaque peptide à son image,
  supprimer les anciennes, pousser → Lovable se synchronise → **Publier**.

### B. Retirer « lovable » de l'adresse
Le sous-domaine `xxx.lovable.app` **ne peut pas être supprimé** (URL de secours permanente), mais on
peut brancher un **domaine personnalisé** : Lovable → Project → **Settings → Domains** (via Entri,
enregistrements DNS A + TXT). Suggestion : `guide.aeternalabs.com` ou `compass.aeternalabs.com`.
Inclus dans l'abonnement Pro de Thomas (12 mois offerts). Alternative : héberger le dépôt GitHub sur Vercel.

### C. Retouches optionnelles proposées (non validées)
- **IGF-1** : image photographiée dans un cadre en bois sombre ; **MOTS-c** : épaisse bordure navy.
  Elles tranchent dans une grille de cartes → recadrer ou régénérer (job_id dans
  `brand/apothicaire-illustrations.md`, ~2 crédits Higgsfield par image).

---

## 6. Pièges rencontrés (à ne pas refaire)

- **Session cloud** : ne peut pas accéder au Mac de Thomas, à lovable.app ni au CDN Higgsfield
  (`d8j0ntlcm91z4.cloudfront.net`) → c'est la raison de cette passation. Les images ont été importées
  via un **workflow GitHub Actions** (les serveurs GitHub ont accès à Internet).
- **Remote Control sur le Mac** : `claude remote-control` échouait car la variable
  **`ANTHROPIC_API_KEY`** est définie dans le shell de Thomas (facturation API). Solution dans la
  fenêtre concernée : `unset ANTHROPIC_API_KEY` puis `claude auth login` (compte claude.ai), puis la commande.
- Dans le Terminal, taper les commandes **dans le shell (`%`)**, pas dans le prompt de Claude Code (`❯`).
- `npm install --no-save <pkg>` supprime les autres paquets installés de la même façon : installer ensemble.
- Export PDF Chromium : un **dégradé en contour de texte SVG** s'imprime comme un rectangle plein →
  utiliser une couleur pleine ou des tracés.

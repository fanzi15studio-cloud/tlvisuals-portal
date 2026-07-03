# Audit des sessions Claude Code — tlvisuals-portal

*Audit réalisé le 2026-07-03, à partir de l'historique git (9 branches `claude/*`, ~60 commits, fév–avril 2026), des 3 PRs GitHub et des runs GitHub Actions.*

---

## Friction n°1 — Du travail terminé qui n'arrive jamais en production

C'est la friction la plus grave, elle revient dans 3 sessions distinctes :

- **PR #3 (showreel, 11 avril) mergée dans la mauvaise branche.** Sa base était `claude/centralize-mac-project-Wd0ek`, pas `main`. Le nouveau showreel YouTube (`n7HvSJcgsKY`) n'a donc **jamais atteint `main`** ni le déploiement.
- **Le fix du build resté orphelin (6 avril).** Après le merge de la PR #2, la session a continué à pousser 6 commits sur la branche déjà mergée (`claude/nextjs-hostinger-deployment-ksU8J`), dont le commit critique `d0d1f01` qui remplace la route API par un fetch client — le seul commit qui répare le build. Il n'a jamais été re-mergé : **le build de `main` est cassé depuis le 6 avril** (vérifié : `next build` échoue sur `/api/client` avec `output: 'export'`).
- **8 branches `claude/*` sur 9 ne sont pas mergées**, dont certaines contiennent du contenu unique (photos carousel, CV, showreel).
- **Deux historiques git disjoints** : `main` (portail Next.js) et `claude/centralize-mac-project-Wd0ek` (site vitrine HTML : `index.html`, `style.css`, `img/`) n'ont *aucun ancêtre commun*. Le site vitrine n'existe tout simplement pas sur `main`.

**Cause racine** : pas de règle explicite « toute PR a `main` pour base, une branche mergée est morte », et rien ne signale qu'une branche a divergé.

## Friction n°2 — Un pipeline de déploiement cassé, contourné à la main

- Le workflow `deploy.yml` (FTP vers Hostinger) n'a **jamais réussi** : 1 seul run, 4 tentatives, 4 échecs, toujours à l'étape `next build` (le déploiement FTP n'a même jamais été atteint — impossible de savoir si les secrets FTP sont valides).
- Faute de CI, la session du 6 avril a **commité des zips de build dans git** : ajout → suppression → ré-ajout (`02ed1c1`, `0a7bb3a`, `6156475`), avec un « real Sheet ID » embarqué dans un binaire de 523 Ko toujours présent dans l'historique de la branche.
- Le `.gitignore` a été modifié en aller-retour pour accompagner ces zigzags.

**Cause racine** : le build n'était vérifié ni localement avant push, ni en CI avant merge (le workflow ne tourne que sur `push` vers `main`, donc l'erreur n'est découverte qu'*après* le merge).

## Friction n°3 — Boucles d'essai-erreur CSS commit par commit

Le 2 avril : **26 commits en une journée**, dont deux rafales caractéristiques :

- Cadrage des images « Expertise cards » : 6 commits successifs (`contain` → `cover + center top` → `right center` → hauteur fixe 260px → `background-position top` → 380px + 30%).
- Video wall : crop iframe à 400 % pour masquer l'UI YouTube, puis retour à 100 % deux commits plus tard.

Chaque tentative = un commit + un push + une vérification visuelle manuelle (probablement sur le site déployé ou le téléphone). C'est lent, ça pollue l'historique, et ça multiplie les allers-retours dans la conversation.

**Cause racine** : pas de boucle de vérification visuelle locale (screenshots) avant de pousser. Chromium + Playwright sont pourtant préinstallés dans l'environnement distant.

## Friction n°4 — Structure de repo instable et contexte périmé

- Réorganisations successives : Next.js déplacé dans `portal/`, site HTML à la racine, ancienne version supprimée puis restaurée (`ce6129f`, `2a7e795`, `436adf3`).
- Un `CLAUDE.md` existe déjà… mais uniquement sur `claude/centralize-mac-project-Wd0ek`, et il décrit une structure qui n'existe plus (`tlvisuals-site/`, `site-internet.md/`, `developer/`) et désigne une branche de dev périmée. Chaque nouvelle session part donc soit sans contexte (sur `main`), soit avec un contexte faux (sur la branche).

## Friction n°5 — Contraintes du projet redécouvertes à chaque session

La contrainte centrale du projet — **export statique** (`output: 'export'`, pas de routes API, pas de SSR, `basePath: '/cv-digital'`) — a été découverte en cassant le build, puis contournée, sans jamais être documentée. Idem pour la cible de déploiement (Hostinger FTP, `/public_html/cv-digital/`).

---

# Recommandations

## A. Fixes immédiats (à faire une fois, dette existante)

1. **Réparer le build de `main`** : cherry-pick `d0d1f01` (+ `9892e3a` pour le `.htaccess`) depuis `claude/nextjs-hostinger-deployment-ksU8J`, sans le zip. C'est le préalable à tout déploiement automatique.
2. **Rapatrier le showreel perdu** : reporter `4e34ae3` / la PR #3 sur l'emplacement réel du site vitrine, et décider une bonne fois où vit le site HTML (le rapatrier dans `main` — par ex. dans `site/` — ou dans un repo séparé).
3. **Purger** `cv-digital-out.zip` (et le Sheet ID qu'il contient) de la branche, puis supprimer les branches `claude/*` mortes après avoir vérifié qu'aucune ne contient de contenu unique.
4. **Vérifier les secrets FTP** (`FTP_SERVER`, `FTP_USERNAME`, `FTP_PASSWORD`) dans Settings → Secrets : l'étape FTP n'a jamais tourné, ils n'ont jamais été testés.

## B. Automatisations (ajoutées dans cette PR)

- **`.github/workflows/build-check.yml`** : `npm ci && npm run build` sur chaque pull request. La friction n°2 (build cassé découvert après merge) devient impossible : la PR est rouge avant le merge.
- À activer côté session : **s'abonner aux événements de la PR** (`subscribe_pr_activity`) après chaque création de PR, pour que la session corrige elle-même un CI rouge au lieu de le découvrir des jours plus tard.

## C. Skills (ajoutées dans `.claude/skills/`)

| Skill | Déclencheur | Ce qu'elle impose |
|---|---|---|
| `verif-build` | Avant tout push touchant `app/` ou la config | `npm run build` local ; rappel des contraintes export statique |
| `verif-visuelle` | Tout changement CSS/layout | Screenshots Playwright (390/768/1440 px), itérer localement, **un seul commit** final |
| `deployer` | Toute demande « mets en ligne / déploie » | Base de PR = `main`, CI vert obligatoire, vérification du site en ligne, jamais de zip dans git |

## D. CLAUDE.md (remplacé à la racine)

Le nouveau `CLAUDE.md` à la racine documente ce qui a coûté le plus cher à redécouvrir : contrainte d'export statique, chaîne de déploiement, règles de branches (base = `main`, branche mergée = morte), interdiction des artefacts de build, et l'existence du site HTML sur la branche disjointe tant qu'il n'est pas rapatrié.

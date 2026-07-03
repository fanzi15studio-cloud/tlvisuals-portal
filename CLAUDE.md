# TLVisuals Portal — Contexte projet

Portail client TLVisuals (login + données Google Sheets), déployé en site statique sur Hostinger.

## Stack

- Next.js 14 (App Router), JavaScript, React 18
- **Export statique** : `output: 'export'` + `basePath: '/cv-digital'` dans `next.config.mjs`
- Déploiement : GitHub Actions → FTP Hostinger `/public_html/cv-digital/` (`.github/workflows/deploy.yml`, déclenché par push sur `main`)

## ⚠️ Contrainte critique : export statique

`next build` produit un site 100 % statique dans `out/`. En conséquence :

- **Aucune route API** (`app/api/**`) — le build échoue avec `output: 'export'`. Toute donnée externe (Google Sheets…) se récupère **côté client** (fetch dans un composant `'use client'`).
- Pas de SSR, pas de `request.url`, pas de `dynamic = 'force-dynamic'`.
- Les URLs internes doivent tenir compte du `basePath` `/cv-digital`.
- État connu : `main` contient encore `app/api/client/route.js` qui casse le build ; le fix (fetch client) existe sur `claude/nextjs-hostinger-deployment-ksU8J` (commit `d0d1f01`) et doit être rapatrié.

## Commandes

```bash
npm ci          # installer (lockfile committé)
npm run dev     # dev local sur http://localhost:3000/cv-digital
npm run build   # OBLIGATOIRE avant tout push — doit passer sans erreur
```

## Règles git (issues de l'audit des sessions passées)

1. **Toute PR a `main` pour base.** Ne jamais merger une PR dans une autre branche `claude/*` (c'est comme ça que le showreel d'avril n'est jamais parti en prod).
2. **Une branche mergée est morte.** Après le merge d'une PR, ne plus pousser dessus : repartir de `main` sur une branche neuve.
3. **Jamais d'artefacts de build dans git** : ni `out/`, ni `.next/`, ni zip. Le déploiement passe par le CI, pas par des zips téléchargés à la main.
4. Pas de push direct sur `main` sans confirmation de l'utilisateur.

## Vérification avant push

- `npm run build` doit passer (le CI de PR le vérifie aussi : `build-check.yml`).
- Changement visuel (CSS, layout, images) → suivre la skill `verif-visuelle` : screenshots Playwright en 390/768/1440 px, itérer **localement**, puis un seul commit propre. Pas de rafale de commits « essai n°4 de cadrage ».
- Après création d'une PR : s'abonner à son activité (`subscribe_pr_activity`) et corriger le CI s'il est rouge.

## État du repo / pièges connus

- Le **site vitrine HTML** (`index.html`, `style.css`, `img/`) ne vit PAS sur `main` : il est sur la branche `claude/centralize-mac-project-Wd0ek`, dont l'historique est **disjoint** (aucun ancêtre commun avec `main`). Tant qu'il n'est pas rapatrié, toute modification du site vitrine doit cibler cette branche — et le signaler à l'utilisateur.
- Le workflow `deploy.yml` n'a encore jamais réussi (build cassé sur `main`) ; les secrets FTP (`FTP_SERVER`, `FTP_USERNAME`, `FTP_PASSWORD`) n'ont jamais été exercés.
- Voir `docs/AUDIT-SESSIONS.md` pour le détail des frictions passées et le plan d'assainissement.

---
name: verif-build
description: Vérifier que le build statique Next.js passe avant tout push. À utiliser avant de pousser un changement touchant app/, next.config.mjs, package.json ou public/.
---

# Vérification du build statique

Ce projet est en **export statique** (`output: 'export'`). Le build de `main` a déjà été cassé une fois pendant des semaines parce que personne ne lançait `next build` avant de pousser.

## Procédure

1. Installer si nécessaire : `npm ci --no-audit --no-fund`
2. Lancer : `npm run build`
3. Le build doit se terminer **sans** la section `Export encountered errors`. Vérifier que `out/` contient bien les pages attendues (`out/index.html`, `out/portal/index.html`, …).

## Erreurs connues et leurs causes

- `Page with dynamic = "error" couldn't be rendered statically because it used request.url` → une route API ou du code serveur dynamique existe sous `app/`. **Interdit en export statique.** Remplacer par un fetch côté client (composant `'use client'`) — voir le modèle `app/lib/fetchClientData.js` sur la branche `claude/nextjs-hostinger-deployment-ksU8J` (commit `d0d1f01`).
- Assets 404 en prod alors que le build passe → oubli du `basePath` `/cv-digital` dans une URL absolue, ou `.htaccess` manquant côté Hostinger.

## Règle

Ne jamais pousser ni ouvrir de PR si `npm run build` échoue. Le workflow `build-check.yml` refera la même vérification sur la PR — autant qu'elle soit verte du premier coup.

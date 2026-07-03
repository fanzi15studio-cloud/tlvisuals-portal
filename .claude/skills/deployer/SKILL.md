---
name: deployer
description: Mettre en ligne le site sur Hostinger. À utiliser pour toute demande « déploie », « mets en ligne », « publie » — impose le chemin PR → main → CI FTP, jamais de zip manuel.
---

# Déploiement Hostinger

La prod se met à jour par **un seul chemin** : merge dans `main` → workflow `deploy.yml` (build + FTP vers `/public_html/cv-digital/`). Les zips commités « à télécharger puis supprimer » sont interdits (ça a déjà mis un Sheet ID dans l'historique git).

## Procédure

1. Vérifier le build localement (skill `verif-build`).
2. Ouvrir une PR **avec `main` pour base** — jamais une autre branche `claude/*` (une PR mergée dans une branche `claude/*` en avril 2026 n'est jamais partie en prod).
3. S'abonner à la PR (`subscribe_pr_activity`) et vérifier que `build-check.yml` est vert avant de proposer le merge à l'utilisateur.
4. Après merge : vérifier que le run « Build & Deploy to Hostinger » réussit (`actions_list` / `get_job_logs`). S'il échoue à l'étape FTP, contrôler que les secrets `FTP_SERVER`, `FTP_USERNAME`, `FTP_PASSWORD` existent dans Settings → Secrets (ils n'ont encore jamais été exercés avec succès).
5. Vérifier le site en ligne (WebFetch sur l'URL de prod, chemin `/cv-digital/`) et confirmer à l'utilisateur avec ce qui a réellement changé.

## Si le CI échoue

Diagnostiquer, corriger, re-pousser — ne pas basculer sur un contournement manuel (zip, FTP à la main). Si le blocage vient d'un secret ou d'un accès Hostinger, le dire explicitement à l'utilisateur : lui seul peut le configurer.

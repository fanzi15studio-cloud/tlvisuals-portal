# Prompt Lovable — remplacement des illustrations peptides

Copier-coller tel quel dans le chat Lovable du projet **Peptide Compass**, puis cliquer **Publier**.

```text
Remplace toutes les illustrations des peptides de l'application par les nouvelles images officielles Aeterna (style planche d'apothicaire) listées ci-dessous.

Règles :
1. Associe chaque image au peptide correspondant par son NOM. Tolère les variantes d'écriture et d'accents (ex. Semaglutide = Sémaglutide, Thymosin Alpha-1 = Thymosine α-1, Oxytocin = Ocytocine, Epitalon = Épithalon, Ipamorelin = Ipamoréline).
2. Remplace l'image partout où ce peptide apparaît : cartes de la liste, page de détail, recherche, favoris, etc. Supprime les anciennes images de peptides qui ne sont plus utilisées.
3. Affichage : ratio 4:5, object-fit: cover, coins et ombres cohérents avec le design actuel, alt = nom du peptide, loading="lazy" (sauf images visibles dès l'arrivée sur la page).
4. Centralise toutes ces URL dans un seul fichier de données (par ex. src/data/peptideImages.ts) indexé par slug, et fais pointer les composants dessus.
5. Si un peptide de l'app n'a pas d'image dans cette liste, garde son image actuelle et donne-moi la liste de ces peptides. Si une image n'a aucun peptide correspondant dans l'app, ne crée rien : signale-le simplement.
6. Ne modifie RIEN d'autre : textes, mise en page, couleurs, logo, et les autres univers (Nutrition, etc.) restent identiques.

Images (une par peptide) :

[Métabolisme]
- Rétatrutide → https://raw.githubusercontent.com/fanzi15studio-cloud/tlvisuals-portal/4da148dfd218ea38438134e5b13020658ed0f8b2/public/aeterna-guide-peptides/illustrations/retatrutide.webp
- Sémaglutide → https://raw.githubusercontent.com/fanzi15studio-cloud/tlvisuals-portal/4da148dfd218ea38438134e5b13020658ed0f8b2/public/aeterna-guide-peptides/illustrations/semaglutide.webp
- Tirzépatide → https://raw.githubusercontent.com/fanzi15studio-cloud/tlvisuals-portal/4da148dfd218ea38438134e5b13020658ed0f8b2/public/aeterna-guide-peptides/illustrations/tirzepatide.webp
- MOTS-c → https://raw.githubusercontent.com/fanzi15studio-cloud/tlvisuals-portal/4da148dfd218ea38438134e5b13020658ed0f8b2/public/aeterna-guide-peptides/illustrations/mots-c.webp

[Muscle & performance]
- CJC-1295 → https://raw.githubusercontent.com/fanzi15studio-cloud/tlvisuals-portal/4da148dfd218ea38438134e5b13020658ed0f8b2/public/aeterna-guide-peptides/illustrations/cjc-1295.webp
- Ipamoréline → https://raw.githubusercontent.com/fanzi15studio-cloud/tlvisuals-portal/4da148dfd218ea38438134e5b13020658ed0f8b2/public/aeterna-guide-peptides/illustrations/ipamoreline.webp
- IGF-1 → https://raw.githubusercontent.com/fanzi15studio-cloud/tlvisuals-portal/4da148dfd218ea38438134e5b13020658ed0f8b2/public/aeterna-guide-peptides/illustrations/igf-1.webp
- Follistatine → https://raw.githubusercontent.com/fanzi15studio-cloud/tlvisuals-portal/4da148dfd218ea38438134e5b13020658ed0f8b2/public/aeterna-guide-peptides/illustrations/follistatine.webp

[Réparation & régénération]
- BPC-157 → https://raw.githubusercontent.com/fanzi15studio-cloud/tlvisuals-portal/4da148dfd218ea38438134e5b13020658ed0f8b2/public/aeterna-guide-peptides/illustrations/bpc-157.webp
- TB-500 → https://raw.githubusercontent.com/fanzi15studio-cloud/tlvisuals-portal/4da148dfd218ea38438134e5b13020658ed0f8b2/public/aeterna-guide-peptides/illustrations/tb-500.webp
- GHK-Cu → https://raw.githubusercontent.com/fanzi15studio-cloud/tlvisuals-portal/4da148dfd218ea38438134e5b13020658ed0f8b2/public/aeterna-guide-peptides/illustrations/ghk-cu.webp
- KPV → https://raw.githubusercontent.com/fanzi15studio-cloud/tlvisuals-portal/4da148dfd218ea38438134e5b13020658ed0f8b2/public/aeterna-guide-peptides/illustrations/kpv.webp

[Fonctions cognitives]
- Sémax → https://raw.githubusercontent.com/fanzi15studio-cloud/tlvisuals-portal/4da148dfd218ea38438134e5b13020658ed0f8b2/public/aeterna-guide-peptides/illustrations/semax.webp
- Sélank → https://raw.githubusercontent.com/fanzi15studio-cloud/tlvisuals-portal/4da148dfd218ea38438134e5b13020658ed0f8b2/public/aeterna-guide-peptides/illustrations/selank.webp
- Cortagen → https://raw.githubusercontent.com/fanzi15studio-cloud/tlvisuals-portal/4da148dfd218ea38438134e5b13020658ed0f8b2/public/aeterna-guide-peptides/illustrations/cortagen.webp
- P21 → https://raw.githubusercontent.com/fanzi15studio-cloud/tlvisuals-portal/4da148dfd218ea38438134e5b13020658ed0f8b2/public/aeterna-guide-peptides/illustrations/p21.webp

[Longévité & santé cellulaire]
- Épithalon → https://raw.githubusercontent.com/fanzi15studio-cloud/tlvisuals-portal/4da148dfd218ea38438134e5b13020658ed0f8b2/public/aeterna-guide-peptides/illustrations/epithalon.webp
- Thymosine α-1 → https://raw.githubusercontent.com/fanzi15studio-cloud/tlvisuals-portal/4da148dfd218ea38438134e5b13020658ed0f8b2/public/aeterna-guide-peptides/illustrations/thymosine-alpha1.webp
- Glutathion → https://raw.githubusercontent.com/fanzi15studio-cloud/tlvisuals-portal/4da148dfd218ea38438134e5b13020658ed0f8b2/public/aeterna-guide-peptides/illustrations/glutathion.webp
- Humanine → https://raw.githubusercontent.com/fanzi15studio-cloud/tlvisuals-portal/4da148dfd218ea38438134e5b13020658ed0f8b2/public/aeterna-guide-peptides/illustrations/humanine.webp

[Sommeil, humeur & vitalité]
- DSIP → https://raw.githubusercontent.com/fanzi15studio-cloud/tlvisuals-portal/4da148dfd218ea38438134e5b13020658ed0f8b2/public/aeterna-guide-peptides/illustrations/dsip.webp
- Ocytocine → https://raw.githubusercontent.com/fanzi15studio-cloud/tlvisuals-portal/4da148dfd218ea38438134e5b13020658ed0f8b2/public/aeterna-guide-peptides/illustrations/ocytocine.webp
- PT-141 → https://raw.githubusercontent.com/fanzi15studio-cloud/tlvisuals-portal/4da148dfd218ea38438134e5b13020658ed0f8b2/public/aeterna-guide-peptides/illustrations/pt-141.webp
```

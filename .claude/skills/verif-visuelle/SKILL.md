---
name: verif-visuelle
description: Vérifier visuellement un changement CSS/layout/images avec des screenshots Playwright AVANT de commiter. À utiliser pour tout changement d'apparence (cadrage d'images, responsive, grille, hero, cartes).
---

# Vérification visuelle locale

Historique du projet : le 2 avril 2026, 6 commits successifs ont été poussés pour cadrer les images des « Expertise cards » (contain → cover → hauteurs fixes → positions…), chaque essai étant vérifié à la main après push. Cette boucle se remplace par des screenshots locaux.

## Procédure

1. Lancer le serveur de dev en arrière-plan : `npm run dev` (le site est sous `http://localhost:3000/cv-digital/`). Pour le site vitrine HTML statique, servir le dossier avec `npx serve` ou `python3 -m http.server`.
2. Capturer les 3 largeurs de référence avec Playwright (Chromium est préinstallé, `PLAYWRIGHT_BROWSERS_PATH` est déjà configuré ; si le projet épingle une autre version de Playwright, utiliser `executablePath: '/opt/pw-browsers/chromium'`) :

```js
// screenshot.mjs — node screenshot.mjs <url> <prefix>
import { chromium } from 'playwright';
const [url, prefix = 'shot'] = process.argv.slice(2);
const browser = await chromium.launch();
for (const [name, width, height] of [['mobile', 390, 844], ['tablet', 768, 1024], ['desktop', 1440, 900]]) {
  const page = await browser.newPage({ viewport: { width, height } });
  await page.goto(url, { waitUntil: 'networkidle' });
  await page.screenshot({ path: `${prefix}-${name}.png`, fullPage: true });
}
await browser.close();
```

3. **Regarder les screenshots** (outil Read) et vérifier le point précis demandé (cadrage, absence de bande noire, colonnes équilibrées…).
4. Itérer CSS → screenshot → lecture **en local**, autant de fois que nécessaire.
5. Quand c'est bon sur les 3 largeurs : **un seul commit** décrivant le résultat final, et envoyer les screenshots à l'utilisateur (SendUserFile) pour validation.

## Règle

Jamais de commit « essai n°N » pour un réglage visuel. On ne pousse que l'état validé par screenshot.

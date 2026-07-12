# Éléments de marque — Aeterna Labs

Charte **extraite du site officiel** d'Aeterna Labs (`index.html` fourni par le client)
et appliquée au guide.

## Palette officielle

| Rôle | Variable | Hex |
|---|---|---|
| Navy (principale) | `--navy` | `#1A3F55` |
| Navy clair | `--navy-light` | `#234F6A` |
| Navy foncé | `--navy-dark` | `#0F2535` |
| Or (accent) | `--gold` | `#C9A84C` |
| Or clair | `--gold-light` | `#E0BE78` |
| Or pâle | `--gold-pale` | `#F5EDDA` |
| Blanc cassé (fond) | `--off-white` | `#F8F6F2` |
| Texte foncé | `--text-dark` | `#1A1A1A` |
| Texte intermédiaire | `--text-mid` | `#4A5568` |
| Bordure | `--border` | `#E2DDD6` |
| Vert (succès) | `--green` | `#059669` |

## Typographie

- **Titres** : *Cormorant Garamond* (serif) — 400 à 700, italique disponible.
- **Texte courant** : *Montserrat* (sans-serif) — 300 à 700.
- Chargées via Google Fonts.

## Logo (vectorisé, 100% tracés — sans dépendance de police)

Le logo du site étant composé en texte CSS (pas de fichier vectoriel réutilisable),
il a été **reconstruit en SVG puis converti en tracés** (chaque lettre est un `<path>`
figé, extrait des polices de marque exactes — Cormorant Garamond 700/600, Montserrat 500 —
via `opentype.js`). Le fichier ne charge donc **aucune police externe** : rendu identique
partout (Lovable, Figma, impression, tout logiciel), aucun risque de police de repli.

| Fichier | Usage |
|---|---|
| `logo/aeterna-labs-logo.svg` | Fond clair (Æ navy à liseré or) |
| `logo/aeterna-labs-logo-blanc.svg` | Fond foncé (Æ blanc à liseré or) |

> **Vectorisation « au trait » de l'artwork original du client :** si tu veux calquer le
> fichier logo original pixel par pixel (bevel doré exact, empattements précis), dépose le
> **PNG/JPG haute résolution** ici ou dans le chat. La version actuelle est une
> reconstruction fidèle à la charte (couleurs/polices exactes du site), déjà vectorielle
> et autonome.

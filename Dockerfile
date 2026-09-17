# =============================================================================
#  Image Docker du portail TLVisuals - pour deploiement sur Dokploy
#
#  Construit l'application en mode SERVEUR (BUILD_TARGET=server), afin que la
#  route /api/client (lecture du Google Sheet cote serveur) fonctionne.
#  L'export statique vers Hostinger n'est pas concerne : il continue d'utiliser
#  "npm run build" sans cette variable.
#
#  Variable d'environnement a renseigner dans Dokploy :
#      GOOGLE_SHEET_ID = identifiant de votre Google Sheet
# =============================================================================

# --- Etape 1 : dependances -------------------------------------------------
FROM node:20-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci

# --- Etape 2 : construction ------------------------------------------------
FROM node:20-alpine AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
# La cible serveur est portee par le script npm ci-dessous.
ENV NEXT_TELEMETRY_DISABLED=1
RUN npm run build:server

# --- Etape 3 : image finale, la plus legere possible -----------------------
FROM node:20-alpine AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
ENV PORT=3000
ENV HOSTNAME=0.0.0.0

# L'application ne tourne pas en root : si elle etait compromise, l'attaquant
# n'aurait pas les droits d'administration a l'interieur du conteneur.
RUN addgroup -g 1001 -S nodejs && adduser -S nextjs -u 1001

# Ces trois copies sont exactement celles verifiees en test : sans "static"
# et "public", les pages s'affichent sans style ni images.
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static
COPY --from=builder --chown=nextjs:nodejs /app/public ./public

USER nextjs
EXPOSE 3000

# Permet a Docker/Dokploy de savoir si l'application repond vraiment.
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD node -e "require('http').get('http://127.0.0.1:3000/',r=>process.exit(r.statusCode<500?0:1)).on('error',()=>process.exit(1))"

CMD ["node", "server.js"]

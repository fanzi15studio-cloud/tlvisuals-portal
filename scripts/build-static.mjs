/**
 * Construction de l'export statique (destination : hebergement FTP Hostinger).
 *
 * POURQUOI CE SCRIPT EXISTE
 * Un export statique Next.js produit un simple dossier de fichiers : il ne
 * peut pas executer de code cote serveur. Or app/api/client/route.js lit un
 * Google Sheet cote serveur. Next.js refuse donc de construire et affiche :
 *     Export encountered errors on following paths: /api/client
 *
 * Ce script met la route API de cote le temps du build statique, puis la
 * remet en place. Le fichier n'est jamais supprime du depot : il reste
 * utilise par la construction serveur (npm run build:server), celle que
 * Dokploy execute et ou la route fonctionne reellement.
 *
 * La restauration est garantie par un bloc finally et par l'interception des
 * signaux d'interruption : meme si le build echoue ou si vous faites Ctrl+C,
 * app/api revient a sa place.
 */
import { spawnSync } from 'node:child_process';
import { existsSync, renameSync } from 'node:fs';
import { join } from 'node:path';

const racine = process.cwd();
const dossierApi = join(racine, 'app', 'api');
const dossierMisDeCote = join(racine, '.api-mise-de-cote');

let deplace = false;

function remettreEnPlace() {
  if (deplace && existsSync(dossierMisDeCote)) {
    renameSync(dossierMisDeCote, dossierApi);
    deplace = false;
    console.log('[build-static] app/api remis en place.');
  }
}

// Filet de securite : une interruption ne doit pas laisser le depot abime.
for (const signal of ['SIGINT', 'SIGTERM', 'SIGHUP']) {
  process.on(signal, () => {
    remettreEnPlace();
    process.exit(1);
  });
}

try {
  // Reparation d'une execution precedente interrompue brutalement.
  if (existsSync(dossierMisDeCote) && !existsSync(dossierApi)) {
    renameSync(dossierMisDeCote, dossierApi);
    console.log('[build-static] Restauration apres une interruption precedente.');
  }

  if (existsSync(dossierApi)) {
    renameSync(dossierApi, dossierMisDeCote);
    deplace = true;
    console.log('[build-static] app/api mis de cote pour la duree du build statique.');
  }

  const resultat = spawnSync('npx', ['next', 'build'], {
    stdio: 'inherit',
    env: { ...process.env, BUILD_TARGET: '' },
  });

  if (resultat.status !== 0) {
    process.exitCode = resultat.status ?? 1;
  }
} finally {
  remettreEnPlace();
}

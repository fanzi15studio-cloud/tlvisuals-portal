/**
 * Deux cibles de construction, pour un seul code source :
 *
 *  - Par defaut (aucune variable) : export statique dans ./out, servi dans le
 *    sous-dossier /cv-digital. C'est le comportement historique, utilise par
 *    le deploiement FTP vers Hostinger. Rien ne change pour lui.
 *
 *  - Avec BUILD_TARGET=server : application Next.js complete avec serveur
 *    Node.js, necessaire pour que la route /api/client (lecture du Google
 *    Sheet cote serveur) fonctionne reellement. C'est la cible utilisee par
 *    le deploiement Docker/Dokploy.
 *
 *  Pourquoi ce choix : un export statique ne peut pas executer de route API.
 *  Le portail client appelle /api/client, donc il ne peut pas fonctionner en
 *  statique, et la construction echoue meme a la compilation.
 */
const cibleServeur = process.env.BUILD_TARGET === 'server';

/** @type {import('next').NextConfig} */
const nextConfig = cibleServeur
  ? {
      output: 'standalone',
    }
  : {
      output: 'export',
      basePath: '/cv-digital',
      trailingSlash: true,
    };

export default nextConfig;

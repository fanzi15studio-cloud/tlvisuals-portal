// Lecture des livrables rangés dans Google Drive (fichiers partagés « tous les utilisateurs disposant du lien »).
// La liste des dossiers passe par l'API Drive (clé GOOGLE_API_KEY, côté serveur) ;
// la lecture et le téléchargement se font en direct depuis Drive, sans passer par le serveur.

const KEY = process.env.GOOGLE_API_KEY;
const API = 'https://www.googleapis.com/drive/v3/files';
const FIELDS = 'id,name,mimeType,size,videoMediaMetadata(width,height,durationMillis)';


export function idDrive(lien) {
  const m = String(lien || '').match(/\/folders\/([\w-]{10,})|\/file\/d\/([\w-]{10,})|[?&]id=([\w-]{10,})/);
  if (!m) return null;
  return m[1] ? { dossier: m[1] } : { fichier: m[2] || m[3] };
}

async function drive(chemin) {
  const r = await fetch(`${API}${chemin}${chemin.includes('?') ? '&' : '?'}key=${KEY}`, { next: { revalidate: 60 } });
  if (!r.ok) throw new Error(`Drive ${r.status}`);
  return r.json();
}

const lister = async (id) => (await drive(
  `?q=${encodeURIComponent(`'${id}' in parents and trashed = false`)}&fields=${encodeURIComponent(`files(${FIELDS})`)}&pageSize=1000`
)).files || [];

const base = (nom) => nom.replace(/\.[^.]+$/, '');
const tri = (a, b) => a.localeCompare(b, 'fr', { numeric: true });

function version(f, label, poster) {
  const v = f.videoMediaMetadata || {};
  return {
    id: f.id, label, taille: Number(f.size) || 0,
    duree: v.durationMillis ? Number(v.durationMillis) / 1000 : 0,
    vertical: Number(v.height) > Number(v.width),
    poster: poster || f.id,
  };
}

// Regroupe les fichiers d'un dossier : « Titre.mp4 » et « Titre (variante).mp4 » forment une seule vidéo à deux versions ;
// « Titre.jpg » sert de vignette, « Titre.fr.srt » de sous-titres.
function assembler(fichiers, groupe) {
  const images = {}, soustitres = {}, videos = {};
  for (const f of fichiers) {
    if (f.mimeType.startsWith('image/')) images[base(f.name)] = f.id;
    else if (/\.srt$/i.test(f.name)) soustitres[f.name.replace(/(\.[a-z]{2})?\.srt$/i, '')] = f.id;
  }
  for (const f of fichiers.filter((f) => f.mimeType.startsWith('video/')).sort((a, b) => tri(a.name, b.name))) {
    const b = base(f.name);
    const m = b.match(/^(.*\S)\s*\(([^)]+)\)$/);
    const titre = m ? m[1] : b;
    const it = (videos[titre] ||= { titre, groupe, versions: [], srt: null });
    it.versions[m ? 'push' : 'unshift'](version(f, m ? m[2] : null, images[b] || images[titre]));
    it.srt ||= soustitres[titre] || soustitres[b] || null;
  }
  return Object.values(videos);
}

// Un dossier de livraison et ses sous-dossiers (un niveau) → vidéos, avec le nom du sous-dossier comme groupe.
export async function collection(id) {
  const fichiers = await lister(id);
  const sous = fichiers.filter((f) => f.mimeType === 'application/vnd.google-apps.folder').sort((a, b) => tri(a.name, b.name));
  const items = assembler(fichiers, null);
  for (const d of sous) items.push(...assembler(await lister(d.id), d.name));
  return { items, groupes: sous.map((d) => d.name) };
}

export async function fichier(id) {
  const f = await drive(`/${id}?fields=${encodeURIComponent(FIELDS)}`);
  return { mime: f.mimeType, ...version(f, null, null) };
}

export const driveActif = Boolean(KEY);

import { NextResponse } from 'next/server';

const KEY = process.env.GOOGLE_API_KEY;
const API = 'https://www.googleapis.com/drive/v3/files';

// Vignettes servies par le portail (API Drive officielle + cache CDN) : l'adresse directe
// lh3.googleusercontent.com répond 429 dès qu'une page affiche quelques dizaines d'images.
export async function GET(request) {
  const id = new URL(request.url).searchParams.get('id') || '';
  if (!/^[\w-]{10,}$/.test(id)) return new Response('id invalide', { status: 400 });
  if (!KEY) return NextResponse.redirect(`https://lh3.googleusercontent.com/d/${id}=w1280`);

  const meta = await fetch(`${API}/${id}?fields=mimeType,thumbnailLink&key=${KEY}`, { next: { revalidate: 86400 } });
  if (!meta.ok) return new Response('introuvable', { status: 404 });
  const { mimeType, thumbnailLink } = await meta.json();
  // une image (.jpg posée à côté de la vidéo) est servie telle quelle, sinon la miniature calculée par Drive
  const src = mimeType?.startsWith('image/') ? `${API}/${id}?alt=media&key=${KEY}`
    : thumbnailLink?.replace(/=s\d+$/, '=s1280');
  if (!src) return new Response('pas de vignette', { status: 404 });

  const r = await fetch(src, { cache: 'no-store' });
  if (!r.ok) return new Response('indisponible', { status: 502 });
  return new Response(r.body, {
    headers: {
      'content-type': r.headers.get('content-type') || 'image/jpeg',
      'cache-control': 'public, max-age=86400, s-maxage=604800, stale-while-revalidate=604800',
    },
  });
}

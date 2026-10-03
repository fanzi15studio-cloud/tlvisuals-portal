'use client';

import { useEffect, useMemo, useState } from 'react';
import { useRouter } from 'next/navigation';

/* ====== Drive ====== */
const fichierUrl = (id) => `https://drive.usercontent.google.com/download?id=${id}&export=download&confirm=t`;
const vignetteUrl = (id) => `https://lh3.googleusercontent.com/d/${id}=w1280`;
const dossierUrl = (id) => `https://drive.google.com/drive/folders/${id}`;
const lecteurUrl = (id) => `https://drive.google.com/file/d/${id}/preview`;

/* ====== Formats ====== */
const mmss = (s) => `${Math.floor(s / 60)}:${String(Math.round(s % 60)).padStart(2, '0')}`;
const duree = (s) => (s >= 60 ? `${Math.floor(s / 60)} min ${String(Math.round(s % 60)).padStart(2, '0')}` : `${Math.round(s)} s`);
const taille = (o) => (o >= 1e9 ? `${(o / 1e9).toFixed(1).replace('.', ',')} Go` : `${Math.max(1, Math.round(o / 1e6))} Mo`);
const joli = (t) => (/\s/.test(t) ? t : t.replace(/[-_]+/g, ' ').replace(/^./, (c) => c.toUpperCase()));
const groupeJoli = (g) => g.replace(/^(\d+)\s*-\s*/, '$1 · ');
const slug = (s) => s.normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');

function dateDe(s) {
  const m = String(s || '').match(/^(\d{1,2})\/(\d{1,2})\/(\d{4})/);
  const d = m ? new Date(+m[3], m[2] - 1, +m[1]) : s ? new Date(s) : null;
  return d && !isNaN(d) ? d : null;
}
const dateLongue = (s) => dateDe(s)?.toLocaleDateString('fr-FR', { day: 'numeric', month: 'long', year: 'numeric' }) || s || '';

function montant(m, devise) {
  const n = parseFloat(String(m).replace(/[^\d.,-]/g, '').replace(',', '.'));
  return isNaN(n) ? `${m} ${devise}` : `${n.toLocaleString('fr-CH', { maximumFractionDigits: 2 })} ${devise === 'EUR' ? '€' : devise}`;
}

function pastille(statut) {
  const s = statut.toLowerCase();
  if (/pay|sign|dispon/.test(s)) return ['ok', s.startsWith('pay') ? 'Payé' : s.startsWith('sign') ? 'Signé' : 'Disponible'];
  if (/envoy/.test(s)) return ['sent', 'Envoyé'];
  return ['wait', s.replace(/_/g, ' ').replace(/^./, (c) => c.toUpperCase())];
}

function couleurTexte(hex) {
  const m = String(hex).replace('#', '').match(/^([\da-f]{2})([\da-f]{2})([\da-f]{2})$/i);
  if (!m) return '#1b1c3a';
  const [r, g, b] = m.slice(1).map((x) => parseInt(x, 16));
  return 0.299 * r + 0.587 * g + 0.114 * b > 150 ? '#1b1c3a' : '#f3eee4';
}

const ETAPES = ['Tournage', 'Montage', 'Musique', 'Validation', 'Livraison'];

// Couleur du bandeau d'après le logo : un fond opaque est prolongé, un logo clair passe sur fond sombre.
function fondDuLogo(img) {
  try {
    const c = document.createElement('canvas');
    c.width = 48;
    c.height = Math.max(1, Math.round((48 * img.naturalHeight) / img.naturalWidth) || 48);
    const x = c.getContext('2d');
    x.drawImage(img, 0, 0, c.width, c.height);
    const d = x.getImageData(0, 0, c.width, c.height).data;
    if (d[3] > 250) return '#' + [d[0], d[1], d[2]].map((v) => v.toString(16).padStart(2, '0')).join('');
    // plus de 10 % de blanc ou d'argent : le logo se lit mal sur le crème, il passe sur fond sombre
    let clair = 0, n = 0;
    for (let i = 0; i < d.length; i += 4) {
      if (d[i + 3] <= 128) continue;
      n++;
      const [r, g, b] = [d[i], d[i + 1], d[i + 2]];
      if (0.299 * r + 0.587 * g + 0.114 * b > 185 && Math.max(r, g, b) - Math.min(r, g, b) < 40) clair++;
    }
    return n && clair / n > 0.1 ? '#141412' : null;
  } catch {
    return null; // logo hébergé ailleurs : illisible pour le canvas, on garde le fond par défaut
  }
}

/* ====== Icônes ====== */
const IcoDl = () => (<svg viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.8"><path d="M8 2v8m0 0 3.5-3.5M8 10 4.5 6.5M2.5 13.5h11" /></svg>);
const IcoLock = () => (<svg viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.8"><rect x="3" y="7" width="10" height="7" rx="1.5" /><path d="M5.5 7V5a2.5 2.5 0 0 1 5 0v2" /></svg>);

/* ====== Cartes ====== */
function Carte({ item, onOpen }) {
  const v = item.versions[0];
  const m = item.titre.match(/^(.+?)\s+·\s+(.+)$/);
  return (
    <button className="card" onClick={() => onOpen(item)}>
      <span className={`shot${v.vertical ? ' v' : ''}`}>
        <img src={vignetteUrl(v.poster)} alt="" loading="lazy" />
        <span className="play"><i /></span>
        {v.duree > 0 && <span className="dur mono">{mmss(v.duree)}</span>}
      </span>
      {m && !v.vertical && <span className="num">{m[1].toUpperCase()}</span>}
      <span className="t">{joli(m ? m[2] : item.titre)}</span>
      {!v.vertical && (
        <span className="sub">
          {item.versions.length > 1 && <span className="tag">{item.versions.length} versions</span>}
          {item.srt && <span className="tag">Sous-titres FR</span>}
        </span>
      )}
    </button>
  );
}

function Collection({ p, onOpen, verrou }) {
  const [groupe, setGroupe] = useState(null);
  const { items, groupes } = p.collection;
  const vus = items.filter((i) => !groupe || i.groupe === groupe);
  const paysage = vus.filter((i) => !i.versions[0].vertical);
  const vertical = vus.filter((i) => i.versions[0].vertical);
  return (
    <section className="block wrap" id={slug(p.nom)}>
      <div className="head">
        <div><span className="lbl">{vertical.length && !paysage.length ? 'Vidéos verticales' : 'Vidéos'}</span><h2>{p.nom}</h2></div>
        {!verrou && <a className="btn dl" href={dossierUrl(p.ref.dossier)} target="_blank" rel="noopener"><IcoDl /> Tout télécharger</a>}
      </div>
      {groupes.length > 0 && (
        <div className="chips">
          {[null, ...groupes].map((g) => (
            <button key={g || 'tout'} className={`chip${g === groupe ? ' on' : ''}`} onClick={() => setGroupe(g)}>
              {g ? groupeJoli(g) : 'Tout'}<small>{items.filter((i) => !g || i.groupe === g).length}</small>
            </button>
          ))}
        </div>
      )}
      {paysage.length > 0 && <div className="grid">{paysage.map((i) => <Carte key={i.versions[0].id} item={i} onOpen={onOpen} />)}</div>}
      {vertical.length > 0 && <div className="vgrid">{vertical.map((i) => <Carte key={i.versions[0].id} item={i} onOpen={onOpen} />)}</div>}
    </section>
  );
}

/* ====== Lecteur ====== */
function Lecteur({ item, verrou, onClose }) {
  const [n, setN] = useState(0);
  const v = item.versions[n];
  const m = item.titre.match(/^(.+?)\s+·\s+(.+)$/);
  useEffect(() => {
    const k = (e) => e.key === 'Escape' && onClose();
    document.addEventListener('keydown', k);
    document.body.style.overflow = 'hidden';
    return () => { document.removeEventListener('keydown', k); document.body.style.overflow = ''; };
  }, [onClose]);
  return (
    <div className="modal" onClick={(e) => e.target === e.currentTarget && onClose()}>
      <div className={`player${v.vertical ? ' vert' : ''}`} role="dialog" aria-modal="true" aria-label={item.titre}>
        <div className="screen">
          {/* lecteur intégrable de Drive : Drive refuse la lecture directe depuis un autre site, et adapte ici la qualité au débit */}
          <iframe key={v.id} src={lecteurUrl(v.id)} title={item.titre} allow="autoplay; fullscreen" allowFullScreen />
        </div>
        <div className="side">
          <div><span className="lbl">{m ? m[1] : item.groupe ? groupeJoli(item.groupe) : 'Vidéo'}</span><h2>{joli(m ? m[2] : item.titre)}</h2></div>
          {item.versions.length > 1 && (
            <div className="seg"><span className="lbl">Version</span>
              {item.versions.map((x, i) => <button key={x.id} className={i === n ? 'on' : ''} onClick={() => setN(i)}>{x.label ? x.label.replace(/^./, (c) => c.toUpperCase()) : 'Version principale'}</button>)}
            </div>
          )}
          <dl className="fiche mono">
            {v.duree > 0 && <><dt>Durée</dt><dd>{duree(v.duree)}</dd></>}
            <dt>Format</dt><dd>{v.vertical ? 'Vertical 9:16' : 'Paysage 16:9'}</dd>
            {item.srt && <><dt>Sous-titres</dt><dd>Français (.srt)</dd></>}
            {v.taille > 0 && <><dt>Fichier</dt><dd>MP4 · {taille(v.taille)}</dd></>}
          </dl>
          <div className="dlbox"><span className="lbl">Télécharger</span>
            {verrou ? (
              <div className="locked"><IcoLock /> Le téléchargement s'ouvre dès le règlement de la facture en attente. La lecture reste libre.</div>
            ) : (
              <>
                <a className="dlopt" href={fichierUrl(v.id)}><b>{joli(item.titre)}{v.label ? ` (${v.label})` : ''}</b><small>MP4{v.taille ? ` · ${taille(v.taille)}` : ''} · qualité de livraison</small><span><IcoDl /></span></a>
                {item.srt && <a className="dlopt" href={fichierUrl(item.srt)}><b>Sous-titres .srt</b><small>Français · pour YouTube</small><span><IcoDl /></span></a>}
              </>
            )}
          </div>
        </div>
        <button className="x" onClick={onClose} aria-label="Fermer le lecteur">×</button>
      </div>
    </div>
  );
}

/* ====== Page ====== */
export default function PortalPage() {
  const router = useRouter();
  const [data, setData] = useState(null);
  const [ouvert, setOuvert] = useState(null);
  const [essaiLogo, setEssaiLogo] = useState(0);
  const [fondAuto, setFondAuto] = useState(null);

  useEffect(() => {
    const code = sessionStorage.getItem('tlv_code');
    if (!code) return router.replace('/');
    fetch('/api/client?code=' + encodeURIComponent(code))
      .then((r) => { if (!r.ok) throw new Error(); return r.json(); })
      .then(setData)
      .catch(() => { sessionStorage.removeItem('tlv_code'); router.replace('/'); });
  }, [router]);

  const vue = useMemo(() => {
    if (!data) return null;
    const { projets, paiements, client } = data;
    const enCours = projets.filter((p) => p.statut === 'en_cours');
    const dispo = projets.filter((p) => p.statut !== 'en_cours');
    const collections = dispo.filter((p) => p.collection?.items.length);
    const filmsP = dispo.filter((p) => !p.collection && p.ref?.fichier && (p.media ? p.media.mime?.startsWith('video/') : /vid/i.test(p.type)));
    const films = filmsP.map((p) => ({ titre: p.nom, date: p.date, srt: null,
      versions: [{ id: p.ref.fichier, poster: p.ref.fichier, label: null, duree: p.media?.duree || 0, taille: p.media?.taille || 0, vertical: p.media?.vertical || false }] }));
    const liens = dispo.filter((p) => !collections.includes(p) && !filmsP.includes(p));
    // à la une : la livraison la plus récente (film seul, ou dernière vidéo paysage du dossier le plus récent)
    const candidats = [
      ...films.filter((f) => !f.versions[0].vertical).map((f) => [dateDe(f.date), f]),
      ...collections.map((c) => [dateDe(c.date), c.collection.items.filter((i) => !i.versions[0].vertical).at(-1)]),
    ].filter(([, it]) => it).sort((a, b) => (b[0] || 0) - (a[0] || 0));
    const toutes = [...films, ...collections.flatMap((c) => c.collection.items)];
    return {
      enCours, collections, films, liens,
      une: candidats[0] ? { item: candidats[0][1], date: candidats[0][0] } : null,
      verrou: client.telechargement.startsWith('apr') && paiements.some((p) => !/pay/i.test(p.statut)),
      nbPaysage: toutes.filter((i) => !i.versions[0].vertical).length,
      nbVertical: toutes.filter((i) => i.versions[0].vertical).length,
    };
  }, [data]);

  if (!vue) return <div className="etat"><span className="spin" aria-label="Chargement" /></div>;

  const { client, documents, paiements } = data;
  const { enCours, collections, films, liens, une, verrou } = vue;
  const fond = client.couleur || fondAuto || '#f3eee4';
  const idLogo = client.logo && client.logo.match(/[\w-]{25,}/)?.[0];
  const logos = !client.logo ? ['png', 'svg'].map((e) => `/logos/${slug(client.entreprise)}.${e}`)
    : [/drive\.google/.test(client.logo) && idLogo ? vignetteUrl(idLogo) : client.logo];
  const logo = logos[essaiLogo];
  const nav = [films.length && ['films', 'Films'], ...collections.map((c) => [slug(c.nom), c.nom]),
    enCours.length && ['en-cours', 'En cours'], (documents.length || paiements.length) && ['documents', 'Documents']].filter(Boolean);
  const prenom = (client.contact || '').split(/\s+/)[0];
  const initiales = (client.contact || client.entreprise).split(/\s+/).map((w) => w[0]).join('').slice(0, 2).toUpperCase();

  return (
    <>
      <header className="top">
        <div className="wrap">
          <a className="brand" href="#haut"><img src="/tlv.png" alt="TL Visuals" /><span>Espace client</span></a>
          <nav className="nav">{nav.map(([id, l]) => <a key={id} href={`#${id}`}>{l}</a>)}</nav>
          <div className="me">
            <span className="avatar" aria-hidden="true">{initiales}</span><span className="who">{client.contact}</span>
            <button className="ghost" onClick={() => { sessionStorage.removeItem('tlv_code'); router.replace('/'); }}>Déconnexion</button>
          </div>
        </div>
      </header>

      <main id="haut">
        <section className="cover" style={{ background: fond, color: couleurTexte(fond), '--fond': fond, '--txt': couleurTexte(fond) }}>
          <div className={`wrap${logo ? '' : ' nologo'}`}>
            {logo && <img key={logo} src={logo} alt={client.entreprise} onError={() => setEssaiLogo((n) => n + 1)} onLoad={(e) => setFondAuto(fondDuLogo(e.currentTarget))} />}
            <div>
              {prenom && <span className="lbl">Bonjour {prenom}</span>}
              <h1>{client.entreprise}</h1>
              <p>Tout ce que nous avons réalisé pour vous, à regarder ici ou à télécharger.</p>
              <div className="counts">
                {vue.nbPaysage > 0 && <span><b>{vue.nbPaysage}</b>{vue.nbPaysage > 1 ? 'vidéos' : 'vidéo'}</span>}
                {vue.nbVertical > 0 && <span><b>{vue.nbVertical}</b>{vue.nbVertical > 1 ? 'vidéos verticales' : 'vidéo verticale'}</span>}
                {enCours.length > 0 && <span className="live"><b>{enCours.length}</b>en cours</span>}
              </div>
            </div>
          </div>
        </section>

        {une && (
          <section className="hero wrap" aria-label="Dernière livraison">
            <div className="hero-card">
              <button className="hero-shot" onClick={() => setOuvert(une.item)} aria-label={`Lire ${une.item.titre}`}>
                <img src={vignetteUrl(une.item.versions[0].poster)} alt="" /><span className="play"><i /></span>
              </button>
              <div className="hero-txt">
                <span className="lbl new">Dernière livraison{une.date ? ` · ${une.date.toLocaleDateString('fr-FR', { day: 'numeric', month: 'long', year: 'numeric' })}` : ''}</span>
                <h2>{joli(une.item.titre)}</h2>
                <dl className="fiche mono">
                  {une.item.versions[0].duree > 0 && <><dt>Durée</dt><dd>{duree(une.item.versions[0].duree)}</dd></>}
                  {une.item.versions.length > 1 && <><dt>Versions</dt><dd>{une.item.versions.length} versions à choisir dans le lecteur</dd></>}
                  {une.item.srt && <><dt>Sous-titres</dt><dd>Français</dd></>}
                </dl>
                <div className="row"><button className="btn go" onClick={() => setOuvert(une.item)}>▶ Regarder</button></div>
              </div>
            </div>
          </section>
        )}

        {films.length > 0 && (
          <section className="block wrap" id="films">
            <div className="head"><div><span className="lbl">Films</span><h2>Vos films</h2></div></div>
            <div className="grid">{films.map((f) => <Carte key={f.versions[0].id} item={f} onOpen={setOuvert} />)}</div>
          </section>
        )}

        {collections.map((p) => <Collection key={p.nom} p={p} onOpen={setOuvert} verrou={verrou} />)}

        {enCours.length > 0 && (
          <section className="block wrap" id="en-cours">
            <div className="head"><div><span className="lbl">En cours</span><h2>Ce qui arrive</h2></div></div>
            <div className="wips">
              {enCours.map((p) => {
                const e = p.etape ? ETAPES.findIndex((x) => x.toLowerCase().startsWith(p.etape.toLowerCase().slice(0, 4))) : -1;
                return (
                  <div className={`wip${e >= 0 ? '' : ' seul'}`} key={p.nom}>
                    <div><span className="lbl new">En production</span><h3>{p.nom || 'Projet en préparation'}</h3>{p.date && <p>Prévu pour le {dateLongue(p.date)}</p>}</div>
                    {e >= 0 && (
                      <ol className="steps">
                        {ETAPES.map((x, i) => (
                          <li key={x} className={i < e ? 'done' : i === e ? 'now' : ''}>
                            <span className="dot">{i < e ? '✓' : ''}</span><span>{x}</span><span className="mono">{i < e ? 'fait' : i === e ? 'en cours' : 'à venir'}</span>
                          </li>
                        ))}
                      </ol>
                    )}
                  </div>
                );
              })}
            </div>
          </section>
        )}

        {liens.length > 0 && (
          <section className="block wrap" id="liens">
            <div className="head"><div><span className="lbl">Autres livrables</span><h2>Liens et fichiers</h2></div></div>
            <div className="docs">
              {liens.map((p, i) => (
                <div className="doc" key={i}>
                  <span className="ico">{(p.type || 'lien').slice(0, 4).toUpperCase()}</span>
                  <span><b>{p.nom}</b><small>{[p.type, dateLongue(p.date)].filter(Boolean).join(' · ')}</small></span>
                  <span />
                  {p.lien ? <a className="btn dl" href={p.lien} target="_blank" rel="noopener">Ouvrir ↗</a> : <span />}
                </div>
              ))}
            </div>
          </section>
        )}

        {(documents.length > 0 || paiements.length > 0) && (
          <section className="block wrap" id="documents">
            <div className="head"><div><span className="lbl">Documents</span><h2>Contrats et factures</h2></div></div>
            <div className="docs">
              {documents.map((d) => { const [c, l] = pastille(d.statut); return (
                <div className="doc" key={'d' + d.id}>
                  <span className="ico">PDF</span>
                  <span><b>{d.nom}</b><small>{[d.type, dateLongue(d.date)].filter(Boolean).join(' · ')}</small></span>
                  <span className={`pill ${c}`}>{l}</span>
                  {d.lien ? <a className="btn dl" href={d.lien} target="_blank" rel="noopener">Ouvrir ↗</a> : <span />}
                </div>
              ); })}
              {paiements.map((p) => { const [c, l] = pastille(p.statut); return (
                <div className="doc" key={'p' + p.id}>
                  <span className="ico">{p.devise === 'EUR' ? '€' : p.devise}</span>
                  <span><b>{p.label}</b><small>{[montant(p.montant, p.devise), dateLongue(p.date)].filter(Boolean).join(' · ')}</small></span>
                  <span className={`pill ${c}`}>{l}</span>
                  {p.lien ? <a className="btn dl" href={p.lien} target="_blank" rel="noopener">Ouvrir ↗</a> : <span />}
                </div>
              ); })}
            </div>
          </section>
        )}
      </main>

      <footer><div className="wrap"><span>TL Visuals · Thomas Loiseau · <a href="https://thomasloiseauvisuals.com" target="_blank" rel="noopener">thomasloiseauvisuals.com</a></span><span>Une question sur une livraison ? Écrivez-moi, je réponds vite.</span></div></footer>

      {ouvert && <Lecteur item={ouvert} verrou={verrou} onClose={() => setOuvert(null)} />}
    </>
  );
}

const CONTACT = {
  email: 'contact@thomasloiseauvisuals.com',
  telCh: '+41 78 608 27 24',
  telChHref: '+41786082724',
  tel: '+33 7 81 99 28 12',
  telHref: '+33781992812',
  site: 'https://thomasloiseauvisuals.com',
  youtube: 'https://www.youtube.com/@Fanzimotivation',
};

const STATS = [
  { value: '17', unit: 'ans', label: "d'image, du tournage à la livraison" },
  { value: '12,7', unit: 'M', label: 'de vues générées sur YouTube' },
  { value: '6', unit: 'sites', label: 'conçus pour des entreprises en 2026' },
  { value: 'CH', unit: '+ FR', label: 'Suisse romande & France' },
];

const REALISATIONS = [
  {
    tone: 'lune',
    size: 'wide',
    logo: 'doula.png',
    logoTight: true,
    tag: 'Vidéo · Formation de doulas',
    title: 'Doula des Lunes',
    text: 'Série de témoignages filmés en 4K, puis films d’interview et formats courts pour les réseaux sociaux : montage, sous-titres animés, habillage graphique et renvoi vers la chaîne YouTube.',
    points: ['4 films d’interview', '29 formats courts', 'Tournage 4K'],
  },
  {
    tone: 'prairie',
    logo: 'dietrich.png',
    tag: 'Photo & vidéo · Entreprise',
    title: 'Dietrich',
    text: 'Missions photo et vidéo pour la communication de l’entreprise : prises de vue sur le terrain, portraits et contenus pour les réseaux.',
    points: ['Photo', 'Vidéo'],
  },
  {
    tone: 'aube',
    logo: 'buggy.png',
    logoDark: true,
    tag: 'Réservation en ligne · Loisirs',
    title: 'Buggy & Co',
    text: 'Site de réservation avec empreinte bancaire, bons cadeaux et notifications automatiques, plus des vidéos dédiées mobile et ordinateur.',
    points: ['Paiement par carte', 'Automatisations'],
  },
  {
    tone: 'peche',
    size: 'wide',
    logo: 'lelocal.png',
    tag: 'Site + vidéo · Salle de sport',
    title: 'Le Local Besançon',
    text: "Refonte complète d'un site WordPress en site rapide et sur mesure, vidéo drone en ouverture, tunnel d'inscription en ligne intégré et redirection de toutes les anciennes pages pour garder le référencement. Tournage des portes ouvertes.",
    points: ['Vidéo drone', 'SEO préservé', 'Inscription en ligne'],
  },
  {
    tone: 'miel',
    logo: 'kassai.svg',
    tag: 'Identité + site · Artisan',
    title: 'Menuiserie Kassaï',
    text: 'Logo, cartes de visite et site vitrine. Formulaire de demande où le client envoie photos de sa pièce et message vocal.',
    points: ['Logo', 'Demande avec photos'],
  },
  {
    tone: 'ciel',
    logo: 'caron.png',
    tag: 'Site vitrine · Association',
    title: 'École de Danse Caron',
    text: "Quarante ans d'école racontés en un site clair : cours, tarifs, gala, danse de mariage.",
    points: ['Site vitrine'],
  },
  {
    tone: 'rose',
    logo: 'protection.png',
    tag: 'Deux sites · Sécurité',
    title: 'Projet Protection & DiagAlarm',
    text: "Deux sites pour des installateurs d'alarme et de vidéosurveillance dans le Var, pensés pour générer des demandes d'étude.",
    points: ['Génération de contacts'],
  },
  {
    tone: 'lune',
    size: 'wide',
    tag: 'Accompagnement · Startup',
    title: "Dossier de lancement d'une startup en sécurité IA",
    text: "Identité, devis, note d'innovation, feuille de route et budget publicitaire : tout le dossier présenté aux partenaires financiers.",
    points: ['Note d’innovation', 'Feuille de route', 'Budget pub'],
  },
  {
    tone: 'peche',
    tag: 'Motion design',
    title: 'Animations sur mesure',
    text: 'Carrousels Instagram, vidéo anniversaire, bande dessinée animée pour un mariage : des formats courts qui se partagent.',
    points: ['Réseaux sociaux'],
  },
  {
    tone: 'prairie',
    size: 'full',
    tag: 'Acquisition',
    title: 'Publicité & automatisations',
    text: 'Campagnes Google Ads et Meta Ads, suivi des contacts automatisé, carte de visite connectée avec compteur de scans.',
    points: ['Google Ads', 'Meta Ads', 'Make'],
  },
];

const COMPETENCES = [
  {
    img: 'video',
    pos: 'center 30%',
    title: 'Vidéo',
    text: 'Films d’entreprise, produit, événement, interview. Tournage 4K en Sony FX30, montage et étalonnage sur Final Cut Pro.',
  },
  {
    img: 'studio',
    pos: 'center 40%',
    title: 'Studio & packshot',
    text: 'Sony FX30 sur slider motorisé, moniteur de contrôle, softbox à grille : des plans produit précis, ici pour un tournage horlogerie.',
  },
  {
    img: 'photo',
    pos: 'center',
    title: 'Photo',
    text: 'Portrait, reportage, packshot, culinaire en macro. Ici, un reportage dans une salle de sport.',
  },
  {
    img: 'drone',
    pos: 'center 55%',
    title: 'Drone',
    text: 'Prises de vue aériennes de lieux, de bâtiments et d’événements.',
  },
  {
    img: 'web',
    pos: 'left center',
    title: 'Sites web',
    text: 'Sites rapides et sur mesure : réservation, paiement en ligne, formulaires, référencement.',
  },
  {
    img: 'ia',
    pos: 'center',
    title: 'Solutions IA',
    text: 'Visuels générés par IA, ici un home cinéma imaginé pour un menuisier avant le chantier, et automatisation des tâches répétitives.',
  },
];

const SECTEURS = [
  'Sport & bien-être',
  'Artisanat',
  'Loisirs & tourisme',
  'Restauration',
  'Immobilier',
  'Sécurité',
  'Danse & culture',
  'Événementiel',
];

const PARCOURS = [
  {
    period: 'Depuis janvier 2026',
    role: 'Fondateur & dirigeant',
    org: 'Thomas Loiseau Visuals',
    logo: true,
    text: 'Création et direction de la société : production photo et vidéo, sites web et solutions IA pour des entreprises en Suisse romande et en France.',
  },
  {
    period: '2009 — 2025',
    role: 'Vidéaste & photographe',
    org: 'Activité indépendante',
    text: 'Seize ans de tournages, de photos et de montages pour des marques, des événements et des réseaux sociaux.',
  },
  {
    period: '2015 — 2021',
    role: 'Coach sportif & créateur de contenus',
    org: 'Le Local, Besançon',
    text: "Accompagnement des adhérents et création de toute l'identité visuelle du centre : photos, vidéos, supports de communication.",
  },
  {
    period: '2013 — 2019',
    role: 'Gérant e-commerce',
    org: 'Air’Livre',
    text: 'Gestion complète d’une boutique en ligne : achats, vente multicanale, publicité, relation client.',
  },
  {
    period: '2011 — 2012',
    role: 'BEP puis Bac Pro Menuisier agenceur',
    org: 'Lycée Saint-Joseph, Besançon',
    text: 'Le goût du travail bien fait, et une vraie compréhension des métiers de l’artisanat.',
  },
];

const MATERIEL = [
  'Sony FX30 Cinema Line + rig',
  'Parc optique complet',
  'Éclairage LED 300 W + tubes RGB',
  'Drone',
  'MacBook Pro M4 Max',
  'Final Cut Pro',
];

const LANGUES = [
  { langue: 'Français', niveau: 'langue maternelle' },
  { langue: 'Anglais', niveau: 'niveau professionnel' },
];

const TL_PATHS = [
  'M459.165,1104.95 L471.163,1117.01 L477.877,1124.13 L513.783,1158.23 L513.967,853.497 L515.756,843.776 L562.696,843.549 L583.003,823.733 L602.313,804.029 L619.136,787.32 L661.392,744.714 L659.602,742.191 L247.831,742.322 L250.486,748.519 L256.258,753.87 L283.174,781.621 L336.695,835.303 L344.497,843.679 L407.983,843.813 L410.459,845.906 L410.874,864.504 L411.168,1056.67 L421.218,1066.99 L447.942,1093.88 L459.165,1104.95 Z',
  'M552.122,1158.15 L860.464,1158.09 L869.777,1158.37 L868.358,1155.72 L861.927,1149.23 L842.919,1130.16 L837.811,1125.08 L829.359,1116.71 L768.877,1056.63 L640.435,1056.57 L640.394,798.378 L636.88,798.808 L627.631,808.513 L616.032,820.16 L606.643,829.623 L584.125,852.163 L576.876,859.1 L571.002,864.438 L538.091,864.771 L538.288,1136.04 L538.59,1149.72 L539.707,1158.14 L552.122,1158.15 Z',
];

function Monogram() {
  return (
    <svg viewBox="247 742 633 418" aria-hidden="true">
      {TL_PATHS.map((d) => (
        <path key={d.slice(0, 12)} d={d} />
      ))}
    </svg>
  );
}

export default function CvPage() {
  return (
    <>
      <header className="nav">
        <a className="nav-brand" href="#top" aria-label="Haut de page">
          <span className="monogram">
            <Monogram />
          </span>
          <span>Thomas Loiseau</span>
        </a>
        <nav className="nav-links" aria-label="Sections">
          <a href="#realisations">2026</a>
          <a href="#competences">Compétences</a>
          <a href="#parcours">Parcours</a>
        </nav>
        <a className="btn btn-small" href="#contact">Contact</a>
      </header>

      <main id="top">
        {/* HERO */}
        <section className="hero">
          <div className="hero-text">
            <p className="eyebrow">Curriculum vitae · 2026</p>
            <h1>
              Thomas <em>Loiseau</em>
            </h1>
            <p className="lead">
              Vidéaste, photographe et créateur de sites web. Dix-sept ans d’expérience de l’image, du
              tournage à la livraison, et aujourd’hui à la tête de ma propre société.
            </p>
            <div className="company">
              <img src="/cv-digital/img/tlv-logo.svg" alt="Thomas Loiseau Visuals" width="96" height="73" />
              <div>
                <p className="company-role">Fondateur & dirigeant</p>
                <p className="company-since">Thomas Loiseau Visuals · depuis janvier 2026</p>
              </div>
            </div>
            <div className="hero-actions">
              <a className="btn" href="#contact">Me contacter</a>
              <a className="btn btn-ghost" href={CONTACT.site} target="_blank" rel="noopener noreferrer">
                Voir mon portfolio →
              </a>
            </div>
            <p className="hero-meta">Frontière franco-suisse · Permis B · Mobile</p>
          </div>

          <div className="hero-visual">
            <div className="portrait">
              <div className="portrait-frame" aria-hidden="true" />
              <img src="/cv-digital/thomas.webp" alt="Portrait de Thomas Loiseau" width="976" height="1200" />
            </div>
            <span className="chip chip-1">Vidéaste</span>
            <span className="chip chip-2">12,7 M de vues</span>
            <span className="chip chip-3">Sites web & automatisations IA</span>
          </div>
        </section>

        {/* STATS */}
        <section className="stats" aria-label="En chiffres">
          {STATS.map((s) => (
            <div key={s.label} className="stat">
              <p className="stat-value">
                {s.value}
                <span>{s.unit}</span>
              </p>
              <p className="stat-label">{s.label}</p>
            </div>
          ))}
        </section>

        {/* RÉALISATIONS */}
        <section id="realisations" className="section">
          <div className="section-head">
            <p className="kicker">L’année 2026</p>
            <h2>
              Mes réalisations <em>cette année</em>
            </h2>
            <p className="section-lead">Une sélection de projets menés avec Thomas Loiseau Visuals.</p>
          </div>
          <div className="bento">
            {REALISATIONS.map((r) => (
              <article key={r.title} className={`card tone-${r.tone} ${r.size || ''}`}>
                {r.logo && (
                  <span className={`card-logo${r.logoDark ? ' dark' : ''}${r.logoTight ? ' tight' : ''}`}>
                    <img src={`/cv-digital/img/logos/${r.logo}`} alt={`Logo ${r.title}`} loading="lazy" />
                  </span>
                )}
                <p className="card-tag">{r.tag}</p>
                <h3>{r.title}</h3>
                <p>{r.text}</p>
                <ul className="pills">
                  {r.points.map((p) => (
                    <li key={p}>{p}</li>
                  ))}
                </ul>
              </article>
            ))}
          </div>
        </section>

        {/* COMPÉTENCES */}
        <section id="competences" className="section">
          <div className="section-head">
            <p className="kicker">Compétences</p>
            <h2>
              De l’idée <em>à la mise en ligne</em>
            </h2>
          </div>
          <div className="skills">
            {COMPETENCES.map((c) => (
              <figure key={c.title} className="skill">
                <div className="skill-media">
                  <img src={`/cv-digital/img/${c.img}.webp`} alt="" loading="lazy" style={{ objectPosition: c.pos }} />
                </div>
                <figcaption>
                  <h3>{c.title}</h3>
                  <p>{c.text}</p>
                </figcaption>
              </figure>
            ))}
          </div>

          <div className="for-who">
            <p className="for-who-title">Secteurs</p>
            <ul className="tags">
              {SECTEURS.map((c) => (
                <li key={c}>{c}</li>
              ))}
            </ul>
          </div>
        </section>

        {/* YOUTUBE */}
        <section className="section">
          <div className="youtube">
            <div>
              <p className="kicker kicker-light">Projet personnel</p>
              <h2>
                Ma chaîne <em>YouTube</em>
              </h2>
              <p>
                Avec @Fanzimotivation, j’ai appris ce qui fait qu’une vidéo est regardée jusqu’au bout :
                le rythme, l’accroche, le montage.
              </p>
              <a className="btn btn-light" href={CONTACT.youtube} target="_blank" rel="noopener noreferrer">
                Voir la chaîne
              </a>
            </div>
            <div className="yt-stats">
              <p><strong>12,7 M</strong> vues</p>
              <p><strong>65,7 k</strong> abonnés</p>
              <p><strong>14</strong> vidéos seulement</p>
            </div>
          </div>
        </section>

        {/* PARCOURS */}
        <section id="parcours" className="section split">
          <div className="section-head">
            <p className="kicker">Parcours</p>
            <h2>
              Un profil <em>hybride</em>
            </h2>
            <p className="section-lead">Image, terrain, commerce, artisanat.</p>
            <div className="gear">
              <p className="for-who-title">Matériel</p>
              <ul className="tags tags-small">
                {MATERIEL.map((m) => (
                  <li key={m}>{m}</li>
                ))}
              </ul>
            </div>
            <div className="gear">
              <p className="for-who-title">Langues</p>
              <ul className="langues">
                {LANGUES.map((l) => (
                  <li key={l.langue}>
                    <strong>{l.langue}</strong> {l.niveau}
                  </li>
                ))}
              </ul>
            </div>
          </div>
          <ol className="timeline">
            {PARCOURS.map((p) => (
              <li key={p.role} className={p.logo ? 'tl-current' : ''}>
                <p className="tl-period">{p.period}</p>
                <h3>{p.role}</h3>
                {p.logo ? (
                  <img className="tl-logo" src="/cv-digital/img/tlv-logo.svg" alt={p.org} width="84" height="64" />
                ) : (
                  <p className="tl-org">{p.org}</p>
                )}
                <p>{p.text}</p>
              </li>
            ))}
          </ol>
        </section>

        {/* CONTACT */}
        <section id="contact" className="contact">
          <h2>
            Me <em>joindre</em>
          </h2>
          <p>Références et portfolio complet sur demande.</p>
          <div className="contact-actions">
            <a className="btn" href={`mailto:${CONTACT.email}`}>{CONTACT.email}</a>
            <a className="btn btn-ghost" href={`tel:${CONTACT.telChHref}`}>Suisse · {CONTACT.telCh}</a>
            <a className="btn btn-ghost" href={`tel:${CONTACT.telHref}`}>France · {CONTACT.tel}</a>
          </div>
          <a className="contact-site" href={CONTACT.site} target="_blank" rel="noopener noreferrer">
            thomasloiseauvisuals.com
          </a>
        </section>
      </main>

      <footer className="footer">© 2026 Thomas Loiseau · Thomas Loiseau Visuals</footer>
    </>
  );
}

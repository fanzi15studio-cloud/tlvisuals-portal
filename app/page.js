const CONTACT = {
  email: 'contact@thomasloiseauvisuals.com',
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
    tone: 'apricot',
    size: 'wide',
    tag: 'Site + vidéo · Salle de sport',
    title: 'Le Local Besançon',
    text: "Refonte complète d'un site WordPress en site rapide et sur mesure, vidéo drone en ouverture, tunnel d'inscription en ligne intégré et redirection de toutes les anciennes pages pour garder le référencement. Tournage des portes ouvertes.",
    points: ['Vidéo drone', 'SEO préservé', 'Inscription en ligne'],
  },
  {
    tone: 'sage',
    tag: 'Réservation en ligne · Loisirs',
    title: 'Buggy & Co',
    text: 'Site de réservation avec empreinte bancaire, bons cadeaux et notifications automatiques, plus des vidéos dédiées mobile et ordinateur.',
    points: ['Paiement par carte', 'Automatisations'],
  },
  {
    tone: 'butter',
    tag: 'Identité + site · Artisan',
    title: 'Menuiserie Kassaï',
    text: 'Logo, cartes de visite et site vitrine. Formulaire de demande où le client envoie photos de sa pièce et message vocal.',
    points: ['Logo', 'Demande avec photos'],
  },
  {
    tone: 'sky',
    tag: 'Site vitrine · Association',
    title: 'École de Danse Caron',
    text: "Quarante ans d'école racontés en un site clair : cours, tarifs, gala, danse de mariage.",
    points: ['Site vitrine'],
  },
  {
    tone: 'rose',
    tag: 'Deux sites · Sécurité',
    title: 'Projet Protection & DiagAlarm',
    text: "Deux sites pour des installateurs d'alarme et de vidéosurveillance dans le Var, pensés pour générer des demandes d'étude.",
    points: ['Génération de contacts'],
  },
  {
    tone: 'lilac',
    size: 'wide',
    tag: 'Accompagnement · Startup',
    title: "Dossier de lancement d'une startup en sécurité IA",
    text: "Identité, devis, note d'innovation, feuille de route et budget publicitaire : tout le dossier présenté aux partenaires financiers.",
    points: ['Note d’innovation', 'Feuille de route', 'Budget pub'],
  },
  {
    tone: 'apricot',
    tag: 'Motion design',
    title: 'Animations sur mesure',
    text: 'Carrousels Instagram, vidéo anniversaire, bande dessinée animée pour un mariage : des formats courts qui se partagent.',
    points: ['Réseaux sociaux'],
  },
  {
    tone: 'sage',
    size: 'full',
    tag: 'Acquisition',
    title: 'Publicité & automatisations',
    text: 'Campagnes Google Ads et Meta Ads, suivi des contacts automatisé, carte de visite connectée avec compteur de scans.',
    points: ['Google Ads', 'Meta Ads', 'Make'],
  },
];

const SAVOIR_FAIRE = [
  { icon: '🎬', title: 'Vidéo', text: 'Films d’entreprise, produit, événement, interviews. Tournage 4K en Sony FX30 Cinema Line.' },
  { icon: '📸', title: 'Photo', text: 'Portrait, packshot, culinaire en macro, reportage. Retouche soignée.' },
  { icon: '🚁', title: 'Drone', text: 'Prises de vue aériennes pour lieux, bâtiments et événements.' },
  { icon: '✂️', title: 'Montage', text: 'Final Cut Pro, étalonnage, motion design, déclinaisons tous formats.' },
  { icon: '💻', title: 'Sites web', text: 'Sites rapides et sur mesure, réservation, paiement, formulaires, référencement.' },
  { icon: '📈', title: 'Visibilité', text: 'Réseaux sociaux, publicité en ligne, automatisation de la prise de contact.' },
];

const CLIENTS = [
  'Artisans',
  'Commerces & restaurants',
  'Salles de sport & bien-être',
  'PME & industrie',
  'Startups',
  'Loisirs & tourisme',
  'Associations & écoles',
  'Événements',
];

const PARCOURS = [
  {
    period: '2009 — aujourd’hui',
    role: 'Fondateur & directeur de production',
    org: 'Thomas Loiseau Visuals',
    text: "Production photo et vidéo de A à Z, puis création de sites et d'outils de communication pour des entreprises en Suisse romande et en France.",
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

export default function CvPage() {
  return (
    <>
      <header className="nav">
        <a className="nav-brand" href="#top" aria-label="Haut de page">
          <span className="monogram">TL</span>
          <span>Thomas Loiseau</span>
        </a>
        <nav className="nav-links" aria-label="Sections">
          <a href="#realisations">2026</a>
          <a href="#savoir-faire">Savoir-faire</a>
          <a href="#parcours">Parcours</a>
        </nav>
        <a className="btn btn-small" href="#contact">Me contacter</a>
      </header>

      <main id="top">
        {/* HERO */}
        <section className="hero">
          <div className="hero-text">
            <p className="eyebrow">
              <span className="dot" /> Disponible pour de nouveaux projets
            </p>
            <h1>
              Je donne envie de pousser <em>votre</em> porte.
            </h1>
            <p className="lead">
              Vidéaste, photographe et créateur de sites. Depuis 17 ans, je raconte des entreprises en
              images, puis je construis les outils qui transforment ces images en clients.
            </p>
            <div className="hero-actions">
              <a className="btn" href="#contact">Parlons de votre projet</a>
              <a className="btn btn-ghost" href={CONTACT.site} target="_blank" rel="noopener noreferrer">
                Voir le portfolio →
              </a>
            </div>
            <p className="hero-meta">Frontière franco-suisse · Permis B · Mobile partout</p>
          </div>

          <div className="hero-visual">
            <div className="blob" aria-hidden="true" />
            <img src="/cv-digital/thomas.webp" alt="Portrait de Thomas Loiseau" width="848" height="1264" />
            <span className="chip chip-1">🎥 Sony FX30</span>
            <span className="chip chip-2">▶ 12,7 M de vues</span>
            <span className="chip chip-3">💻 Sites sur mesure</span>
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
              Ce que j’ai réalisé <em>cette année</em>
            </h2>
            <p className="section-lead">
              Une sélection de projets menés avec Thomas Loiseau Visuals, de l’image jusqu’au site qui
              fait venir les clients.
            </p>
          </div>
          <div className="bento">
            {REALISATIONS.map((r) => (
              <article key={r.title} className={`card tone-${r.tone} ${r.size || ''}`}>
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

        {/* SAVOIR-FAIRE */}
        <section id="savoir-faire" className="section">
          <div className="section-head">
            <p className="kicker">Savoir-faire</p>
            <h2>
              Un seul interlocuteur, <em>de l’idée à la mise en ligne</em>
            </h2>
          </div>
          <div className="skills">
            {SAVOIR_FAIRE.map((s) => (
              <div key={s.title} className="skill">
                <span className="skill-icon" aria-hidden="true">{s.icon}</span>
                <h3>{s.title}</h3>
                <p>{s.text}</p>
              </div>
            ))}
          </div>

          <div className="for-who">
            <p className="for-who-title">Pour qui ?</p>
            <ul className="tags">
              {CLIENTS.map((c) => (
                <li key={c}>{c}</li>
              ))}
            </ul>
          </div>
        </section>

        {/* YOUTUBE */}
        <section className="section">
          <div className="youtube">
            <div>
              <p className="kicker kicker-light">La preuve par l’exemple</p>
              <h2>
                Des contenus qui <em>trouvent leur public</em>
              </h2>
              <p>
                Avec ma chaîne @Fanzimotivation, j’ai appris ce qui fait qu’une vidéo est regardée
                jusqu’au bout. Je mets ce savoir au service de vos réseaux.
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
            <p className="section-lead">
              Image, terrain, commerce, artisanat : je parle le langage des entreprises que je filme.
            </p>
            <div className="gear">
              <p className="for-who-title">Mon matériel</p>
              <ul className="tags tags-small">
                {MATERIEL.map((m) => (
                  <li key={m}>{m}</li>
                ))}
              </ul>
            </div>
          </div>
          <ol className="timeline">
            {PARCOURS.map((p) => (
              <li key={p.role}>
                <p className="tl-period">{p.period}</p>
                <h3>{p.role}</h3>
                <p className="tl-org">{p.org}</p>
                <p>{p.text}</p>
              </li>
            ))}
          </ol>
        </section>

        {/* CONTACT */}
        <section id="contact" className="contact">
          <h2>
            Un projet, une idée, <em>une envie&nbsp;?</em>
          </h2>
          <p>Racontez-moi votre entreprise. Je vous réponds sous 24 heures.</p>
          <div className="contact-actions">
            <a className="btn" href={`mailto:${CONTACT.email}`}>{CONTACT.email}</a>
            <a className="btn btn-ghost" href={`tel:${CONTACT.telHref}`}>{CONTACT.tel}</a>
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

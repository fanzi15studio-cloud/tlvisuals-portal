/**
 * SavoirFaireSection
 *
 * Remplace l'image JPEG "Chaque projet est unique".
 * Usage :
 *   import SavoirFaireSection from '@/app/components/SavoirFaireSection';
 *   <SavoirFaireSection photoSrc="/thomas.png" />
 *
 * photoSrc : chemin vers la photo de Thomas (fond transparent recommandé)
 * photoAlt : texte alternatif pour l'accessibilité
 */
export default function SavoirFaireSection({
  photoSrc = '/thomas.png',
  photoAlt = 'Thomas Loiseau — Thomas Loiseau Visuals',
}) {
  return (
    <section className="sf-section">
      {/* ─── Contenu texte (gauche) ─── */}
      <div className="sf-content">
        <p className="sf-eyebrow">Chaque projet est unique</p>

        <h2 className="sf-heading">
          Je mets mon savoir-faire
          <br />
          à votre <span className="sf-accent">service.</span>
        </h2>

        <div className="sf-divider" aria-hidden="true" />

        <ul className="sf-list">
          <li>Réalisation vidéo &amp; montage dynamique</li>
          <li>Photographie corporate, lifestyle &amp; sport</li>
          <li>Mise en valeur immobilière &amp; architecturale</li>
          <li>Captations aériennes par drone</li>
        </ul>
      </div>

      {/* ─── Photo (droite) ─── */}
      <div className="sf-photo-wrap" aria-hidden="true">
        <img
          src={photoSrc}
          alt={photoAlt}
          className="sf-photo"
          loading="lazy"
          draggable="false"
        />
      </div>
    </section>
  );
}

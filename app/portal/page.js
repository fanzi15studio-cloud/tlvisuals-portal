'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';

/* ====== SVG ICONS ====== */
const VideoIcon = () => (
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
    <rect x="2" y="2" width="20" height="20" rx="2.18" ry="2.18" />
    <path d="m10 8 6 4-6 4V8z" />
  </svg>
);

const DocIcon = () => (
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
    <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" />
    <polyline points="14 2 14 8 20 8" />
    <line x1="16" y1="13" x2="8" y2="13" />
    <line x1="16" y1="17" x2="8" y2="17" />
  </svg>
);

const PayIcon = () => (
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
    <rect x="1" y="4" width="22" height="16" rx="2" ry="2" />
    <line x1="1" y1="10" x2="23" y2="10" />
  </svg>
);

const DownloadIcon = () => (
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
    <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" />
    <polyline points="7 10 12 15 17 10" />
    <line x1="12" y1="15" x2="12" y2="3" />
  </svg>
);

const SignIcon = () => (
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
    <path d="M17 3a2.85 2.83 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5Z" />
  </svg>
);

const CheckSmall = () => (
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
    <polyline points="20 6 9 17 4 12" />
  </svg>
);

const ClockSmall = () => (
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
    <circle cx="12" cy="12" r="10" />
    <polyline points="12 6 12 12 16 14" />
  </svg>
);

const LogoutIcon = () => (
  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
    <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" />
    <polyline points="16 17 21 12 16 7" />
    <line x1="21" y1="12" x2="9" y2="12" />
  </svg>
);

/* ====== STATUS BADGE ====== */
function StatusBadge({ status }) {
  const isGreen = ['disponible', 'signé', 'signe', 'payé', 'paye'].includes(status);
  const labels = {
    disponible: 'Disponible',
    en_cours: 'En cours',
    signé: 'Signé',
    signe: 'Signé',
    en_attente: 'En attente',
    payé: 'Payé',
    paye: 'Payé',
  };

  return (
    <span className={`badge ${isGreen ? 'green' : 'orange'}`}>
      {isGreen ? <CheckSmall /> : <ClockSmall />}
      {labels[status] || status}
    </span>
  );
}

/* ====== FORMAT HELPERS ====== */
function formatDate(dateStr) {
  if (!dateStr) return '';
  // Try parsing various formats
  const d = new Date(dateStr);
  if (isNaN(d.getTime())) return dateStr;
  return d.toLocaleDateString('fr-FR', { day: 'numeric', month: 'long', year: 'numeric' });
}

function formatMontant(montant, devise) {
  const num = parseFloat(String(montant).replace(/[^\d.,\-]/g, '').replace(',', '.'));
  if (isNaN(num)) return `${montant} ${devise}`;
  return `${num.toLocaleString('fr-CH', { minimumFractionDigits: 2, maximumFractionDigits: 2 })} ${devise}`;
}

function getInitials(name) {
  if (!name) return '?';
  return name
    .split(' ')
    .map((w) => w[0])
    .join('')
    .toUpperCase()
    .slice(0, 2);
}

/* ====== TABS ====== */
const TABS = [
  { id: 'livrables', label: 'Livrables', icon: <VideoIcon /> },
  { id: 'documents', label: 'Documents', icon: <DocIcon /> },
  { id: 'paiements', label: 'Paiements', icon: <PayIcon /> },
];

/* ====== PORTAL PAGE ====== */
export default function PortalPage() {
  const router = useRouter();
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [activeTab, setActiveTab] = useState('livrables');

  useEffect(() => {
    const code = sessionStorage.getItem('tlv_code');
    if (!code) {
      router.replace('/');
      return;
    }

    fetch(`/api/client?code=${encodeURIComponent(code)}`)
      .then((res) => {
        if (!res.ok) throw new Error('invalid');
        return res.json();
      })
      .then((d) => {
        setData(d);
        setLoading(false);
      })
      .catch(() => {
        sessionStorage.removeItem('tlv_code');
        router.replace('/');
      });
  }, [router]);

  function handleLogout() {
    sessionStorage.removeItem('tlv_code');
    router.replace('/');
  }

  if (loading) {
    return (
      <div className="loading-page">
        <div className="spinner" />
      </div>
    );
  }

  if (error) {
    return (
      <div className="loading-page">
        <p style={{ color: '#888' }}>{error}</p>
      </div>
    );
  }

  if (!data) return null;

  const { client, projets, documents, paiements } = data;
  const disponibles = projets.filter((p) => p.statut === 'disponible').length;

  // Calculate total
  const total = paiements.reduce((sum, p) => {
    const num = parseFloat(String(p.montant).replace(/[^\d.,\-]/g, '').replace(',', '.'));
    return sum + (isNaN(num) ? 0 : num);
  }, 0);
  const devise = paiements[0]?.devise || 'CHF';

  return (
    <div className="portal-page">
      {/* HEADER */}
      <header className="portal-header">
        <div className="portal-header-inner">
          <div className="portal-brand">
            <div className="portal-brand-logo">TL</div>
            <span className="portal-brand-name">Thomas Loiseau Visuals</span>
          </div>
          <div className="portal-user">
            <div className="portal-user-avatar">{getInitials(client.contact)}</div>
            <span>{client.contact}</span>
            <button
              onClick={handleLogout}
              title="Se déconnecter"
              style={{
                background: 'none',
                border: 'none',
                color: '#aaa',
                padding: 4,
                marginLeft: 4,
                cursor: 'pointer',
              }}
            >
              <LogoutIcon />
            </button>
          </div>
        </div>
      </header>

      {/* MAIN */}
      <main className="portal-main">
        {/* Welcome */}
        <div className="portal-welcome">
          <h1>Bonjour, {(client.contact || '').split(' ')[0]} 👋</h1>
          <p>
            Bienvenue sur votre espace projet — <strong>{client.entreprise}</strong>
          </p>
        </div>

        {/* Progress */}
        {projets.length > 0 && (
          <div className="progress-card">
            <div className="progress-header">
              <span className="progress-label">Avancement des livrables</span>
              <span className="progress-count">
                {disponibles}/{projets.length} terminés
              </span>
            </div>
            <div className="progress-track">
              <div
                className="progress-fill"
                style={{ width: `${(disponibles / projets.length) * 100}%` }}
              />
            </div>
          </div>
        )}

        {/* Tabs */}
        <div className="tabs">
          {TABS.map((tab) => (
            <button
              key={tab.id}
              className={`tab-btn ${activeTab === tab.id ? 'active' : ''}`}
              onClick={() => setActiveTab(tab.id)}
            >
              {tab.icon}
              {tab.label}
            </button>
          ))}
        </div>

        {/* Content */}
        <div className="content-card">
          {/* ====== LIVRABLES ====== */}
          {activeTab === 'livrables' && (
            <>
              <div className="content-header">Vos vidéos</div>
              {projets.length === 0 ? (
                <div className="empty-state">Aucun livrable pour le moment.</div>
              ) : (
                projets.map((p) => (
                  <div key={p.id} className="content-row">
                    <div className="row-left">
                      <div className={`row-icon ${p.statut === 'disponible' ? 'green' : 'orange'}`}>
                        <VideoIcon />
                      </div>
                      <div className="row-info">
                        <div className="row-title">{p.nom}</div>
                        <div className="row-sub">{p.type}</div>
                      </div>
                    </div>
                    <div className="row-right">
                      <StatusBadge status={p.statut} />
                      {p.statut === 'disponible' && p.lien && (
                        <a href={p.lien} target="_blank" rel="noopener noreferrer" className="btn btn-primary">
                          <DownloadIcon /> Télécharger
                        </a>
                      )}
                    </div>
                  </div>
                ))
              )}
            </>
          )}

          {/* ====== DOCUMENTS ====== */}
          {activeTab === 'documents' && (
            <>
              <div className="content-header">Documents contractuels</div>
              {documents.length === 0 ? (
                <div className="empty-state">Aucun document pour le moment.</div>
              ) : (
                documents.map((d) => {
                  const isSigned = ['signé', 'signe'].includes(d.statut);
                  return (
                    <div key={d.id} className="content-row">
                      <div className="row-left">
                        <div className={`row-icon ${isSigned ? 'green' : 'neutral'}`}>
                          <DocIcon />
                        </div>
                        <div className="row-info">
                          <div className="row-title">{d.nom}</div>
                          <div className="row-sub">
                            {d.date ? `Ajouté le ${formatDate(d.date)}` : ''}
                          </div>
                        </div>
                      </div>
                      <div className="row-right">
                        <StatusBadge status={d.statut} />
                        {d.statut === 'en_attente' && d.lien ? (
                          <a href={d.lien} target="_blank" rel="noopener noreferrer" className="btn btn-primary">
                            <SignIcon /> Signer
                          </a>
                        ) : d.lien ? (
                          <a href={d.lien} target="_blank" rel="noopener noreferrer" className="btn btn-ghost">
                            <DownloadIcon /> PDF
                          </a>
                        ) : null}
                      </div>
                    </div>
                  );
                })
              )}
            </>
          )}

          {/* ====== PAIEMENTS ====== */}
          {activeTab === 'paiements' && (
            <>
              <div className="content-header">Facturation</div>
              {paiements.length === 0 ? (
                <div className="empty-state">Aucune facture pour le moment.</div>
              ) : (
                <>
                  {paiements.map((p) => {
                    const isPaid = ['payé', 'paye'].includes(p.statut);
                    return (
                      <div key={p.id} className="content-row">
                        <div className="row-left">
                          <div className={`row-icon ${isPaid ? 'green' : 'orange'}`}>
                            <PayIcon />
                          </div>
                          <div className="row-info">
                            <div className="row-title">{p.label}</div>
                            <div className="row-sub">
                              {p.date ? `Échéance : ${formatDate(p.date)}` : ''}
                            </div>
                          </div>
                        </div>
                        <div className="row-right">
                          <span className="amount">
                            {formatMontant(p.montant, p.devise)}
                          </span>
                          <StatusBadge status={p.statut} />
                          {!isPaid && p.lien && (
                            <a href={p.lien} target="_blank" rel="noopener noreferrer" className="btn btn-success">
                              Payer maintenant
                            </a>
                          )}
                        </div>
                      </div>
                    );
                  })}
                  <div className="total-bar">
                    <span className="total-label">Total projet</span>
                    <span className="total-amount">
                      {formatMontant(total, devise)}
                    </span>
                  </div>
                </>
              )}
            </>
          )}
        </div>

        {/* Partners */}
        <div className="partners-section">
          <div className="partners-label">Ils nous font confiance</div>
          <div className="partners-logos">
            <img src="/logos/aopb.png" alt="AOPB" className="partner-logo" />
            <img src="/logos/mnx.png" alt="MNX" className="partner-logo" />
            <img src="/logos/eiyolab.png" alt="EIYÖLAB" className="partner-logo" />
            <img src="/logos/lelocal.png" alt="[LE] LOCAL" className="partner-logo" />
            <img src="/logos/dietrich.png" alt="Dietrich" className="partner-logo" />
          </div>
        </div>

        {/* Footer */}
        <div className="portal-footer">
          <div className="portal-footer-logo">TL</div>
          <span>© 2026 Thomas Loiseau Visuals — Lausanne, Suisse</span>
          <a href="https://thomasloiseauvisuals.com" target="_blank" rel="noopener">
            thomasloiseauvisuals.com
          </a>
          <a href="mailto:contact@thomasloiseauvisuals.com">
            contact@thomasloiseauvisuals.com
          </a>
        </div>
      </main>
    </div>
  );
}

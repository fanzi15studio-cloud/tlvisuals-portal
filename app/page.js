'use client';

import { useState } from 'react';
import Link from 'next/link';

const services = [
  {
    num: '01',
    title: 'VIDEO',
    desc: 'Captation fluide avec Sony FX30 Cinema Line, montage soigné et color grading professionnel pour raconter votre histoire.',
    img: '/images/service-video.jpg', // Replace with your actual photo
    href: '/login',
  },
  {
    num: '02',
    title: 'PHOTO',
    desc: "Portraits, événements corporate et images d'architecture au rendu naturel et élégant. Une seule image peut suffire.",
    img: '/images/service-photo.jpg', // Replace with your actual photo
    href: '/login',
  },
  {
    num: '03',
    title: 'CONSULTING',
    desc: "Stratégie visuelle, direction artistique et accompagnement pour aligner votre image à votre ambition.",
    img: '/images/service-consulting.jpg', // Replace with your actual photo
    href: '/login',
  },
];

export default function HomePage() {
  const [menuOpen, setMenuOpen] = useState(false);

  return (
    <div className="home-page">
      {/* Nav */}
      <nav className="home-nav">
        <div className="home-nav-inner">
          <Link href="/" className="home-nav-logo">
            <svg width="48" height="40" viewBox="0 0 48 40" fill="none" xmlns="http://www.w3.org/2000/svg" aria-label="TL Visuals">
              <text x="0" y="30" fontFamily="'Playfair Display', serif" fontSize="28" fontWeight="700" fill="#fff">TL</text>
            </svg>
          </Link>
          <button
            className="home-nav-burger"
            onClick={() => setMenuOpen(!menuOpen)}
            aria-label="Menu"
          >
            <span /><span /><span />
          </button>
        </div>
        {menuOpen && (
          <div className="home-nav-menu">
            <Link href="/#video" onClick={() => setMenuOpen(false)}>Vidéo</Link>
            <Link href="/#photo" onClick={() => setMenuOpen(false)}>Photo</Link>
            <Link href="/#consulting" onClick={() => setMenuOpen(false)}>Consulting</Link>
            <Link href="/login" onClick={() => setMenuOpen(false)}>Espace client</Link>
          </div>
        )}
      </nav>

      {/* Services */}
      <main className="home-services">
        {services.map((s) => (
          <Link
            key={s.num}
            href={s.href}
            id={s.title.toLowerCase()}
            className="service-card"
          >
            {/* Background image */}
            <div
              className="service-card-bg"
              style={{ backgroundImage: `url(${s.img})` }}
            />
            {/* Dark gradient overlay */}
            <div className="service-card-overlay" />
            {/* Content */}
            <div className="service-card-content">
              <span className="service-num">{s.num}</span>
              <h2 className="service-title">{s.title}</h2>
              <p className="service-desc">{s.desc}</p>
            </div>
          </Link>
        ))}
      </main>

      {/* Footer */}
      <footer className="home-footer">
        <p>© 2026 Thomas Loiseau Visuals — Lausanne, Suisse</p>
        <Link href="/login">Espace client</Link>
      </footer>
    </div>
  );
}

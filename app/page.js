'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';

export default function LoginPage() {
  const [code, setCode] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const router = useRouter();

  async function handleSubmit(e) {
    e.preventDefault();
    if (!code.trim()) return;
    setLoading(true);
    setError('');
    try {
      const res = await fetch('/api/client?code=' + encodeURIComponent(code.trim()));
      const data = await res.json();
      if (!res.ok) {
        setError(data.error || 'Une erreur est survenue.');
        setLoading(false);
        return;
      }
      sessionStorage.setItem('tlv_code', code.trim().toUpperCase());
      router.push('/portal');
    } catch {
      setError('Impossible de se connecter. Réessayez.');
      setLoading(false);
    }
  }

  return (
    <div className="login-page">
      <div className="login-card">
        <div className="login-logo">TL</div>
        <h1 className="login-title">Espace Client</h1>
        <p className="login-subtitle">Accédez à vos livrables, documents et factures</p>
        <form className="login-form" onSubmit={handleSubmit}>
          <input className="login-input" type="text" placeholder="Votre code d'accès" value={code} onChange={(e) => { setCode(e.target.value.toUpperCase()); setError(''); }} autoFocus autoComplete="off" spellCheck="false" />
          <button className="login-button" type="submit" disabled={loading || !code.trim()}>{loading ? 'Connexion...' : 'Accéder à mon espace'}</button>
        </form>
        {error && <p className="login-error">{error}</p>}
        <div className="login-footer">
          <p>© 2026 Thomas Loiseau Visuals — Lausanne, Suisse</p>
          <p style={{ marginTop: 4 }}><a href="https://thomasloiseauvisuals.com" target="_blank" rel="noopener">thomasloiseauvisuals.com</a></p>
        </div>
      </div>
    </div>
  );
}

import { NextResponse } from 'next/server';

const SHEET_ID = process.env.GOOGLE_SHEET_ID;

async function fetchSheet(sheetName) {
  const url = `https://docs.google.com/spreadsheets/d/${SHEET_ID}/gviz/tq?tqx=out:json&sheet=${encodeURIComponent(sheetName)}`;
  const res = await fetch(url, { next: { revalidate: 30 } });
  if (!res.ok) throw new Error('Cannot read sheet');
  const text = await res.text();
  const match = text.match(/google\.visualization\.Query\.setResponse\(([\s\S]*?)\);?\s*$/);
  if (!match) throw new Error('Unexpected format');
  const data = JSON.parse(match[1]);
  if (!data.table || !data.table.cols || !data.table.rows) return [];
  const headers = data.table.cols.map((col) => (col.label || '').trim().toLowerCase());
  return data.table.rows.map((row) => {
    const obj = {};
    (row.c || []).forEach((cell, i) => {
      if (i < headers.length && headers[i]) {
        if (!cell) obj[headers[i]] = '';
        else if (cell.f !== undefined && cell.f !== null) obj[headers[i]] = cell.f;
        else if (cell.v !== undefined && cell.v !== null) obj[headers[i]] = String(cell.v);
        else obj[headers[i]] = '';
      }
    });
    return obj;
  });
}

export async function GET(request) {
  const { searchParams } = new URL(request.url);
  const code = (searchParams.get('code') || '').trim().toUpperCase();
  if (!code) return NextResponse.json({ error: "Code requis." }, { status: 400 });
  if (!SHEET_ID) return NextResponse.json({ error: 'Config manquante.' }, { status: 500 });
  try {
    const [clients, projets, documents, paiements] = await Promise.all([
      fetchSheet('clients'), fetchSheet('projets'), fetchSheet('documents'), fetchSheet('paiements'),
    ]);
    const client = clients.find((c) => (c.code || '').trim().toUpperCase() === code);
    if (!client) return NextResponse.json({ error: "Code invalide." }, { status: 404 });
    return NextResponse.json({
      client: { entreprise: client.entreprise || '', contact: client.contact || '', email: client.email || '' },
      projets: projets.filter((p) => (p.code || '').trim().toUpperCase() === code).map((p, i) => ({ id: i+1, nom: p.nom||'', type: p.type||'', statut: (p.statut||'en_cours').trim().toLowerCase(), date: p.date||'', lien: p.lien||'' })),
      documents: documents.filter((d) => (d.code || '').trim().toUpperCase() === code).map((d, i) => ({ id: i+1, nom: d.nom||'', type: (d.type||'').trim().toLowerCase(), statut: (d.statut||'en_attente').trim().toLowerCase(), date: d.date||'', lien: d.lien||'' })),
      paiements: paiements.filter((p) => (p.code || '').trim().toUpperCase() === code).map((p, i) => ({ id: i+1, label: p.label||'', montant: p.montant||'0', devise: (p.devise||'CHF').trim(), statut: (p.statut||'en_attente').trim().toLowerCase(), date: p.date||'', lien: p.lien||'' })),
    });
  } catch (err) {
    console.error('API Error:', err);
    return NextResponse.json({ error: 'Service indisponible.' }, { status: 500 });
  }
}

import { NextResponse } from 'next/server';

const SHEET_ID = process.env.GOOGLE_SHEET_ID;

// Fetch a tab from the published Google Sheet
async function fetchSheet(sheetName) {
  const url = `https://docs.google.com/spreadsheets/d/${SHEET_ID}/gviz/tq?tqx=out:json&sheet=${encodeURIComponent(sheetName)}`;
  
  const res = await fetch(url, { next: { revalidate: 30 } });
  
  if (!res.ok) {
    throw new Error(`Impossible de lire l'onglet "${sheetName}"`);
  }

  const text = await res.text();

  // Strip the JSONP wrapper Google returns
  const match = text.match(/google\.visualization\.Query\.setResponse\(([\s\S]*?)\);?\s*$/);
  if (!match) {
    throw new Error(`Format inattendu pour l'onglet "${sheetName}"`);
  }

  const data = JSON.parse(match[1]);

  if (!data.table || !data.table.rows) {
    return { headers: [], rows: [] };
  }

  // Extract headers from col labels
  const headers = (data.table.cols || []).map((col) => (col.label || '').trim().toLowerCase());

  // Map rows to arrays of cell values
  const rows = data.table.rows.map((row) => {
    return (row.c || []).map((cell) => {
      if (!cell) return '';
      if (cell.f !== undefined && cell.f !== null) return String(cell.f).trim();
      if (cell.v !== undefined && cell.v !== null) return String(cell.v).trim();
      return '';
    });
  });

  return { headers, rows };
}

// Get cell value by header name OR by column index (fallback)
function getVal(row, headers, name, fallbackIndex) {
  // Try by header name first
  const idx = headers.indexOf(name);
  if (idx >= 0 && idx < row.length) return row[idx];
  // Fallback to column position
  if (fallbackIndex !== undefined && fallbackIndex < row.length) return row[fallbackIndex];
  return '';
}

export async function GET(request) {
  const { searchParams } = new URL(request.url);
  const code = (searchParams.get('code') || '').trim().toUpperCase();
  const debug = searchParams.get('debug') === '1';

  if (!code && !debug) {
    return NextResponse.json({ error: "Code d'accès requis." }, { status: 400 });
  }

  if (!SHEET_ID) {
    return NextResponse.json({ error: 'Configuration serveur manquante.' }, { status: 500 });
  }

  try {
    // Fetch all tabs in parallel
    const [clientsData, projetsData, documentsData, paiementsData] = await Promise.all([
      fetchSheet('clients'),
      fetchSheet('projets'),
      fetchSheet('documents'),
      fetchSheet('paiements'),
    ]);

    // Debug mode: show what we read
    if (debug) {
      return NextResponse.json({
        clients: { headers: clientsData.headers, rows: clientsData.rows.slice(0, 3) },
        projets: { headers: projetsData.headers, rows: projetsData.rows.slice(0, 3) },
        documents: { headers: documentsData.headers, rows: documentsData.rows.slice(0, 3) },
        paiements: { headers: paiementsData.headers, rows: paiementsData.rows.slice(0, 3) },
      });
    }

    const cH = clientsData.headers;
    const cRows = clientsData.rows;

    // Find client: check "code" header, or first column as fallback
    // Also check if first row is actually headers (skip it)
    let client = null;
    let skipFirst = false;

    // Check if first data row looks like headers
    if (cRows.length > 0) {
      const firstVal = (cRows[0][0] || '').toLowerCase();
      if (firstVal === 'code' || firstVal === 'code client' || firstVal === 'code_client') {
        skipFirst = true;
      }
    }

    const dataRows = skipFirst ? cRows.slice(1) : cRows;

    for (const row of dataRows) {
      const rowCode = getVal(row, cH, 'code', 0).toUpperCase();
      if (rowCode === code) {
        client = {
          entreprise: getVal(row, cH, 'entreprise', 1),
          contact: getVal(row, cH, 'contact', 2),
          email: getVal(row, cH, 'email', 3),
        };
        break;
      }
    }

    if (!client) {
      return NextResponse.json({ error: "Code d'accès invalide." }, { status: 404 });
    }

    // Filter projets
    const pH = projetsData.headers;
    const pSkip = projetsData.rows.length > 0 && (projetsData.rows[0][0] || '').toLowerCase() === 'code';
    const pRows = pSkip ? projetsData.rows.slice(1) : projetsData.rows;
    
    const clientProjets = pRows
      .filter((row) => getVal(row, pH, 'code', 0).toUpperCase() === code)
      .map((row, i) => ({
        id: i + 1,
        nom: getVal(row, pH, 'nom', 1),
        type: getVal(row, pH, 'type', 2),
        statut: getVal(row, pH, 'statut', 3).toLowerCase() || 'en_cours',
        date: getVal(row, pH, 'date', 4),
        lien: getVal(row, pH, 'lien', 5),
      }));

    // Filter documents
    const dH = documentsData.headers;
    const dSkip = documentsData.rows.length > 0 && (documentsData.rows[0][0] || '').toLowerCase() === 'code';
    const dRows = dSkip ? documentsData.rows.slice(1) : documentsData.rows;
    
    const clientDocs = dRows
      .filter((row) => getVal(row, dH, 'code', 0).toUpperCase() === code)
      .map((row, i) => ({
        id: i + 1,
        nom: getVal(row, dH, 'nom', 1),
        type: getVal(row, dH, 'type', 2).toLowerCase(),
        statut: getVal(row, dH, 'statut', 3).toLowerCase() || 'en_attente',
        date: getVal(row, dH, 'date', 4),
        lien: getVal(row, dH, 'lien', 5),
      }));

    // Filter paiements
    const paH = paiementsData.headers;
    const paSkip = paiementsData.rows.length > 0 && (paiementsData.rows[0][0] || '').toLowerCase() === 'code';
    const paRows = paSkip ? paiementsData.rows.slice(1) : paiementsData.rows;
    
    const clientPaiements = paRows
      .filter((row) => getVal(row, paH, 'code', 0).toUpperCase() === code)
      .map((row, i) => ({
        id: i + 1,
        label: getVal(row, paH, 'label', 1),
        montant: getVal(row, paH, 'montant', 2),
        devise: getVal(row, paH, 'devise', 3) || 'CHF',
        statut: getVal(row, paH, 'statut', 4).toLowerCase() || 'en_attente',
        date: getVal(row, paH, 'date', 5),
        lien: getVal(row, paH, 'lien', 6),
      }));

    return NextResponse.json({
      client,
      projets: clientProjets,
      documents: clientDocs,
      paiements: clientPaiements,
    });
  } catch (err) {
    console.error('Erreur API:', err);
    return NextResponse.json(
      { error: 'Service temporairement indisponible. Réessayez dans quelques instants.' },
      { status: 500 }
    );
  }
}

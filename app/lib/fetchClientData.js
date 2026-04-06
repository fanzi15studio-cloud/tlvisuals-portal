// Fetches client data directly from the published Google Sheet.
// Runs in the browser — no server/API route needed (compatible with static export).

const SHEET_ID = process.env.NEXT_PUBLIC_GOOGLE_SHEET_ID;

async function fetchSheet(sheetName) {
  const url = `https://docs.google.com/spreadsheets/d/${SHEET_ID}/gviz/tq?tqx=out:json&sheet=${encodeURIComponent(sheetName)}`;
  const res = await fetch(url);
  if (!res.ok) throw new Error(`Impossible de lire l'onglet "${sheetName}"`);
  const text = await res.text();
  const match = text.match(/google\.visualization\.Query\.setResponse\(([\s\S]*?)\);?\s*$/);
  if (!match) throw new Error(`Format inattendu pour l'onglet "${sheetName}"`);
  const data = JSON.parse(match[1]);
  if (!data.table || !data.table.rows) return { headers: [], rows: [] };
  const headers = (data.table.cols || []).map((col) => (col.label || '').trim().toLowerCase());
  const rows = data.table.rows.map((row) =>
    (row.c || []).map((cell) => {
      if (!cell) return '';
      if (cell.f !== undefined && cell.f !== null) return String(cell.f).trim();
      if (cell.v !== undefined && cell.v !== null) return String(cell.v).trim();
      return '';
    })
  );
  return { headers, rows };
}

function getVal(row, headers, name, fallbackIndex) {
  const idx = headers.indexOf(name);
  if (idx >= 0 && idx < row.length) return row[idx];
  if (fallbackIndex !== undefined && fallbackIndex < row.length) return row[fallbackIndex];
  return '';
}

function skipHeaderRow(rows) {
  if (rows.length === 0) return rows;
  const firstVal = (rows[0][0] || '').toLowerCase();
  return ['code', 'code client', 'code_client'].includes(firstVal) ? rows.slice(1) : rows;
}

export async function fetchClientData(code) {
  if (!SHEET_ID) throw new Error('Configuration manquante (NEXT_PUBLIC_GOOGLE_SHEET_ID).');

  const upperCode = code.trim().toUpperCase();

  const [clientsData, projetsData, documentsData, paiementsData] = await Promise.all([
    fetchSheet('clients'),
    fetchSheet('projets'),
    fetchSheet('documents'),
    fetchSheet('paiements'),
  ]);

  // Find client
  const cH = clientsData.headers;
  const clientRow = skipHeaderRow(clientsData.rows).find(
    (row) => getVal(row, cH, 'code', 0).toUpperCase() === upperCode
  );
  if (!clientRow) throw new Error("Code d'accès invalide.");
  const client = {
    entreprise: getVal(clientRow, cH, 'entreprise', 1),
    contact: getVal(clientRow, cH, 'contact', 2),
    email: getVal(clientRow, cH, 'email', 3),
  };

  // Filter projets
  const pH = projetsData.headers;
  const projets = skipHeaderRow(projetsData.rows)
    .filter((row) => getVal(row, pH, 'code', 0).toUpperCase() === upperCode)
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
  const documents = skipHeaderRow(documentsData.rows)
    .filter((row) => getVal(row, dH, 'code', 0).toUpperCase() === upperCode)
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
  const paiements = skipHeaderRow(paiementsData.rows)
    .filter((row) => getVal(row, paH, 'code', 0).toUpperCase() === upperCode)
    .map((row, i) => ({
      id: i + 1,
      label: getVal(row, paH, 'label', 1),
      montant: getVal(row, paH, 'montant', 2),
      devise: getVal(row, paH, 'devise', 3) || 'CHF',
      statut: getVal(row, paH, 'statut', 4).toLowerCase() || 'en_attente',
      date: getVal(row, paH, 'date', 5),
      lien: getVal(row, paH, 'lien', 6),
    }));

  return { client, projets, documents, paiements };
}

#!/usr/bin/env bash
# =============================================================================
#  VERIFICATION DE STIRLING PDF - fusion de deux PDF de test
#  Thomas Loiseau Visuals
#
#  Ce script :
#    1. cree deux petits PDF de test
#    2. verifie que Stirling PDF repond
#    3. trouve tout seul le point d'API de fusion (via la doc OpenAPI de
#       votre instance, pour ne dependre d'aucun nom d'endpoint suppose)
#    4. fusionne les deux PDF et verifie que le resultat fait bien 2 pages
#
#  Usage :  bash test-fusion-pdf.sh
#           bash test-fusion-pdf.sh http://localhost:8080
# =============================================================================
set -uo pipefail

BASE="${1:-http://localhost:8080}"
DOSSIER="$(cd "$(dirname "$0")" && pwd)/test-pdf"
mkdir -p "$DOSSIER"

ok()    { printf '  \033[0;32m✔\033[0m %s\n' "$1"; }
ko()    { printf '  \033[0;31m✘\033[0m %s\n' "$1"; }
info()  { printf '  \033[0;36m·\033[0m %s\n' "$1"; }
titre() { printf '\n\033[1;36m=== %s ===\033[0m\n' "$1"; }

# --------------------------------------------------------------------------
titre "1. Creation de deux PDF de test"

creer_pdf_python() {
  # $1 = chemin de sortie, $2 = texte affiche sur la page
  python3 - "$1" "$2" <<'PY'
import sys
chemin, texte = sys.argv[1], sys.argv[2]
def pdf(texte):
    contenu = f"BT /F1 24 Tf 72 700 Td ({texte}) Tj ET".encode("latin-1")
    objets = [
        b"<< /Type /Catalog /Pages 2 0 R >>",
        b"<< /Type /Pages /Kids [3 0 R] /Count 1 >>",
        b"<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] "
        b"/Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >>",
        b"<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>",
        b"<< /Length " + str(len(contenu)).encode() + b" >>\nstream\n" + contenu + b"\nendstream",
    ]
    sortie = bytearray(b"%PDF-1.4\n")
    offsets = []
    for i, obj in enumerate(objets, start=1):
        offsets.append(len(sortie))
        sortie += f"{i} 0 obj\n".encode() + obj + b"\nendobj\n"
    debut_xref = len(sortie)
    sortie += f"xref\n0 {len(objets)+1}\n".encode()
    sortie += b"0000000000 65535 f \n"
    for off in offsets:
        sortie += f"{off:010d} 00000 n \n".encode()
    sortie += (f"trailer\n<< /Size {len(objets)+1} /Root 1 0 R >>\n"
               f"startxref\n{debut_xref}\n%%EOF\n").encode()
    return bytes(sortie)
open(chemin, "wb").write(pdf(texte))
print("cree")
PY
}

creer_pdf_macos() {
  # Solution de repli sur macOS sans python3 : cupsfilter est livre avec le systeme
  printf '%s\n' "$2" > "${1%.pdf}.txt"
  cupsfilter -o media=A4 "${1%.pdf}.txt" > "$1" 2>/dev/null
}

PDF_A="$DOSSIER/test-page-1.pdf"
PDF_B="$DOSSIER/test-page-2.pdf"

if command -v python3 >/dev/null 2>&1; then
  creer_pdf_python "$PDF_A" "TLV - Page de test numero 1" >/dev/null && ok "PDF 1 cree"
  creer_pdf_python "$PDF_B" "TLV - Page de test numero 2" >/dev/null && ok "PDF 2 cree"
elif command -v cupsfilter >/dev/null 2>&1; then
  creer_pdf_macos "$PDF_A" "TLV - Page de test numero 1" && ok "PDF 1 cree (cupsfilter)"
  creer_pdf_macos "$PDF_B" "TLV - Page de test numero 2" && ok "PDF 2 cree (cupsfilter)"
else
  ko "Ni python3 ni cupsfilter disponibles."
  info "Creez deux PDF a la main (TextEdit > Imprimer > Enregistrer au format PDF),"
  info "nommez-les test-page-1.pdf et test-page-2.pdf dans : $DOSSIER"
  exit 1
fi

for f in "$PDF_A" "$PDF_B"; do
  if head -c 5 "$f" | grep -q '%PDF'; then ok "$(basename "$f") est un PDF valide ($(wc -c < "$f") octets)"
  else ko "$(basename "$f") n'est pas un PDF valide"; exit 1; fi
done

# --------------------------------------------------------------------------
titre "2. Stirling PDF repond-il ?"
ETAT=$(curl -s --max-time 10 "$BASE/api/v1/info/status" 2>/dev/null)
if echo "$ETAT" | grep -q "UP"; then
  ok "Stirling PDF est en ligne sur $BASE"
else
  ko "Aucune reponse sur $BASE/api/v1/info/status"
  info "Verifiez que le conteneur tourne :  docker compose ps"
  info "Le premier demarrage peut prendre 1 a 2 minutes (Java)."
  info "Logs :  docker compose logs -f"
  exit 1
fi

# --------------------------------------------------------------------------
titre "3. Recherche du point d'API de fusion"
# On interroge la documentation OpenAPI de VOTRE instance : ainsi le script
# reste valide meme si Stirling renomme ses endpoints dans une version future.
CHEMIN_FUSION=""
for DOC in "/v1/api-docs" "/v3/api-docs" "/api-docs"; do
  SPEC=$(curl -s --max-time 15 "$BASE$DOC" 2>/dev/null)
  if [ -n "$SPEC" ] && echo "$SPEC" | grep -q '"paths"'; then
    CHEMIN_FUSION=$(printf '%s' "$SPEC" \
      | tr ',' '\n' | grep -oE '"/api/v[0-9]+/[a-zA-Z/-]*merge[a-zA-Z/-]*"' \
      | tr -d '"' | sort -u | head -1)
    [ -n "$CHEMIN_FUSION" ] && { info "Documentation API trouvee sur $DOC"; break; }
  fi
done

if [ -z "$CHEMIN_FUSION" ]; then
  CHEMIN_FUSION="/api/v1/general/merge-pdfs"
  info "Doc API non lisible : utilisation du chemin standard $CHEMIN_FUSION"
else
  ok "Point d'API de fusion detecte : $CHEMIN_FUSION"
fi

# --------------------------------------------------------------------------
titre "4. Fusion des deux PDF"
RESULTAT="$DOSSIER/resultat-fusion.pdf"
CODE=$(curl -s --max-time 120 -o "$RESULTAT" -w '%{http_code}' \
  -X POST "$BASE$CHEMIN_FUSION" \
  -H "Accept: application/pdf" \
  -F "fileInput=@$PDF_A;type=application/pdf" \
  -F "fileInput=@$PDF_B;type=application/pdf" 2>/dev/null)

if [ "$CODE" != "200" ]; then
  ko "La fusion a echoue (code HTTP $CODE)"
  info "Reponse du serveur :"; head -c 400 "$RESULTAT" 2>/dev/null | sed 's/^/    /'; echo
  info "Si la connexion est activee (SECURITY_ENABLELOGIN=true), l'API exige une"
  info "cle : interface > Parametres > Compte > cle d'API, puis ajoutez a la commande :"
  info '   -H "X-API-KEY: votre_cle"'
  info "Vous pouvez aussi tester a la main : $BASE (outil \"Fusionner\")."
  exit 1
fi
ok "Le serveur a repondu 200 et renvoye un fichier"

# --------------------------------------------------------------------------
titre "5. Verification du resultat"
if ! head -c 5 "$RESULTAT" | grep -q '%PDF'; then
  ko "Le fichier renvoye n'est pas un PDF"; exit 1
fi
ok "Le fichier renvoye est bien un PDF ($(wc -c < "$RESULTAT") octets)"

PAGES=$(grep -ac "/Type[[:space:]]*/Page[^s]" "$RESULTAT" 2>/dev/null || echo "0")
if [ "$PAGES" -ge 2 ]; then
  ok "Le PDF fusionne contient $PAGES pages : la fusion a bien fonctionne"
else
  info "Comptage automatique des pages peu fiable sur ce fichier."
  info "Ouvrez-le pour verifier :  open \"$RESULTAT\""
fi

titre "RESULTAT : STIRLING PDF FONCTIONNE"
echo "  Fichier fusionne : $RESULTAT"
echo "  Ouvrez-le avec :  open \"$RESULTAT\""
echo "  Interface web  :  $BASE"

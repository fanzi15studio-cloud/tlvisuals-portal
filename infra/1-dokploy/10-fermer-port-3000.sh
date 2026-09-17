#!/usr/bin/env bash
# =============================================================================
#  FERMER L'ACCES DIRECT AU PORT 3000 DE DOKPLOY - Thomas Loiseau Visuals
#
#  A lancer UNIQUEMENT apres avoir associe un domaine a Dokploy et verifie
#  que https://votre-domaine fonctionne. Le script le verifie lui-meme et
#  refuse d'agir sinon : sans cette precaution vous perdriez l'acces a
#  l'interface.
#
#  Methode : on retire la publication du port du service Docker Swarm.
#  On ne passe PAS par ufw, qui serait sans effet sur un port publie par
#  Docker (ses regles iptables sont evaluees avant celles de ufw).
#
#  Usage :  bash 10-fermer-port-3000.sh dokploy.thomasloiseauvisuals.com
# =============================================================================
set -uo pipefail

DOMAINE="${1:-}"
titre() { printf '\n\033[1;36m=== %s ===\033[0m\n' "$1"; }
ok()    { printf '  \033[0;32m✔\033[0m %s\n' "$1"; }
ko()    { printf '  \033[0;31m✘\033[0m %s\n' "$1"; }
info()  { printf '  \033[0;36m·\033[0m %s\n' "$1"; }

[ "$(id -u)" -ne 0 ] && { ko "A lancer en root (ou avec sudo)."; exit 1; }

if [ -z "$DOMAINE" ]; then
  ko "Indiquez le domaine de Dokploy."
  info "Exemple :  bash 10-fermer-port-3000.sh dokploy.thomasloiseauvisuals.com"
  exit 1
fi

titre "1. Le service Dokploy existe-t-il ?"
if ! docker service inspect dokploy >/dev/null 2>&1; then
  ko "Service Docker Swarm 'dokploy' introuvable."
  info "Dokploy est-il bien installe sur CE serveur ?  docker service ls"
  exit 1
fi
ok "Service 'dokploy' trouve"

titre "2. Le port 3000 est-il publie actuellement ?"
PUBLIE=$(docker service inspect dokploy \
  --format '{{range .Endpoint.Spec.Ports}}{{.PublishedPort}} {{end}}' 2>/dev/null | tr -s ' ')
info "Ports publies : ${PUBLIE:-aucun}"
if ! echo " $PUBLIE " | grep -q " 3000 "; then
  ok "Le port 3000 n'est deja plus publie : rien a faire."
  exit 0
fi

titre "3. VERIFICATION DE SECURITE : l'acces par domaine fonctionne-t-il ?"
info "Test de https://$DOMAINE ..."
CODE=$(curl -sS -o /dev/null -w '%{http_code}' --max-time 20 "https://$DOMAINE" 2>/dev/null || echo "000")
if [ "$CODE" = "000" ]; then
  ko "Aucune reponse HTTPS sur https://$DOMAINE"
  info "N'allez pas plus loin : en fermant le port 3000 maintenant, vous"
  info "n'auriez plus AUCUN acces a l'interface Dokploy."
  info "Verifiez d'abord : le DNS pointe-t-il sur ce serveur, et le domaine"
  info "est-il bien renseigne dans Dokploy (Settings > Server > Domain) ?"
  exit 1
fi
CERT=$(curl -sS -o /dev/null -w '%{ssl_verify_result}' --max-time 20 "https://$DOMAINE" 2>/dev/null || echo "1")
if [ "$CERT" != "0" ]; then
  ko "Le certificat HTTPS n'est pas valide (code $CERT)."
  info "Attendez que Let's Encrypt ait emis le certificat, puis relancez."
  exit 1
fi
ok "https://$DOMAINE repond (code HTTP $CODE) avec un certificat valide"

titre "4. Fermeture du port 3000"
printf '  Le port 3000 va cesser d etre publie. L interface restera joignable\n'
printf '  uniquement sur https://%s\n' "$DOMAINE"
printf '  Confirmer ? Tapez exactement OUI puis Entree : '
read -r REPONSE
[ "$REPONSE" != "OUI" ] && { info "Annule, rien n'a ete modifie."; exit 0; }

if docker service update --publish-rm 3000 dokploy >/dev/null 2>&1; then
  ok "Publication du port 3000 retiree"
else
  ko "La commande a echoue. Etat inchange, verifiez :  docker service inspect dokploy"
  exit 1
fi

titre "5. Verification finale"
sleep 6
RESTE=$(docker service inspect dokploy \
  --format '{{range .Endpoint.Spec.Ports}}{{.PublishedPort}} {{end}}' 2>/dev/null | tr -s ' ')
info "Ports publies desormais : ${RESTE:-aucun}"
if echo " $RESTE " | grep -q " 3000 "; then
  ko "Le port 3000 apparait encore publie."
else
  ok "Le port 3000 n'est plus publie"
fi

CODE2=$(curl -sS -o /dev/null -w '%{http_code}' --max-time 20 "https://$DOMAINE" 2>/dev/null || echo "000")
if [ "$CODE2" = "000" ]; then
  ko "ATTENTION : https://$DOMAINE ne repond plus."
  info "Republier le port immediatement pour recuperer l'acces :"
  info "   docker service update --publish-add 3000:3000 dokploy"
else
  ok "https://$DOMAINE repond toujours (code $CODE2)"
fi

titre "TERMINE"
echo "  Interface Dokploy : https://$DOMAINE"
echo "  Pour revenir en arriere :  docker service update --publish-add 3000:3000 dokploy"

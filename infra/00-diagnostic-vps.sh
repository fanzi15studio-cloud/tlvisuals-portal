#!/usr/bin/env bash
# =============================================================================
#  DIAGNOSTIC DU VPS - A LANCER AVANT TOUTE INSTALLATION
#  Thomas Loiseau Visuals - aucune modification n'est faite par ce script.
#  Il ne fait que LIRE l'etat du serveur et afficher un rapport.
#
#  Usage sur le VPS :
#     bash 00-diagnostic-vps.sh
#  Puis copiez-collez tout l'affichage dans la conversation.
# =============================================================================
set -u

titre() { printf '\n\033[1;36m=== %s ===\033[0m\n' "$1"; }
ok()    { printf '  \033[0;32mOK\033[0m      %s\n' "$1"; }
attn()  { printf '  \033[1;33mATTENTION\033[0m %s\n' "$1"; }
stop()  { printf '  \033[0;31mBLOQUANT\033[0m  %s\n' "$1"; }

titre "1. Systeme d'exploitation"
if [ -r /etc/os-release ]; then
  . /etc/os-release
  echo "  Distribution : ${PRETTY_NAME:-inconnue}"
  case "${ID:-}" in
    ubuntu|debian) ok "Distribution supportee par l'installeur Dokploy." ;;
    *)             attn "Dokploy supporte aussi RHEL/Fedora/Arch/Alpine, mais Ubuntu LTS est le mieux teste." ;;
  esac
else
  attn "Impossible de lire /etc/os-release."
fi
echo "  Noyau        : $(uname -r)"
echo "  Architecture : $(uname -m)"

titre "2. Memoire vive (Dokploy exige 2 Go minimum)"
if command -v free >/dev/null 2>&1; then
  free -h | sed 's/^/  /'
  RAM_MO=$(free -m | awk '/^Mem:/{print $2}')
  echo "  Total detecte : ${RAM_MO} Mo"
  if   [ "$RAM_MO" -lt 1800 ]; then stop "Moins de 2 Go de RAM : Dokploy risque de ne pas tenir."
  elif [ "$RAM_MO" -lt 3800 ]; then attn "2 Go : suffisant pour Dokploy seul, juste si on ajoute DocuSeal + PostgreSQL. 4 Go recommandes."
  else ok "RAM confortable pour Dokploy + DocuSeal."
  fi
else
  attn "Commande 'free' absente."
fi

titre "3. Espace disque"
df -h / | sed 's/^/  /'
DISPO_GO=$(df -BG --output=avail / 2>/dev/null | tail -1 | tr -dc '0-9')
if [ -n "${DISPO_GO:-}" ]; then
  if [ "$DISPO_GO" -lt 10 ]; then stop "Moins de 10 Go libres : insuffisant (images Docker + documents signes)."
  elif [ "$DISPO_GO" -lt 25 ]; then attn "${DISPO_GO} Go libres : ca passe, surveillez la place."
  else ok "${DISPO_GO} Go libres."
  fi
fi

titre "4. PORTS OCCUPES (le point critique : votre bot CLAUDIO)"
echo "  Dokploy a besoin des ports 80, 443 et 3000."
if command -v ss >/dev/null 2>&1; then
  OUTIL="ss -tulnp"
elif command -v netstat >/dev/null 2>&1; then
  OUTIL="netstat -tulnp"
else
  OUTIL=""
  attn "Ni 'ss' ni 'netstat' : installez-les avec  apt-get install -y iproute2"
fi
if [ -n "$OUTIL" ]; then
  echo "  --- Tout ce qui ecoute sur le serveur ---"
  $OUTIL 2>/dev/null | sed 's/^/  /'
  echo "  --- Verdict port par port ---"
  for PORT in 80 443 3000; do
    LIGNE=$($OUTIL 2>/dev/null | grep -E "[:.]${PORT}[[:space:]]" || true)
    if [ -n "$LIGNE" ]; then
      stop "Port ${PORT} DEJA OCCUPE par :"
      echo "$LIGNE" | sed 's/^/            /'
    else
      ok "Port ${PORT} libre."
    fi
  done
fi

titre "5. Docker"
if command -v docker >/dev/null 2>&1; then
  ok "Docker present : $(docker --version 2>/dev/null)"
  if docker compose version >/dev/null 2>&1; then
    ok "Docker Compose (plugin v2) present : $(docker compose version --short 2>/dev/null)"
  else
    attn "Plugin 'docker compose' absent (l'installeur Dokploy s'en occupe)."
  fi
  if docker info 2>/dev/null | grep -q 'Swarm: active'; then
    attn "Docker Swarm DEJA ACTIF sur ce serveur. Dokploy le reutilisera tel quel."
  else
    echo "  Swarm : inactif (l'installeur Dokploy fera 'docker swarm init')."
  fi
  echo "  --- Conteneurs en cours d'execution ---"
  docker ps --format '  {{.Names}} | image={{.Image}} | ports={{.Ports}}' 2>/dev/null || echo "  (lecture impossible)"
  echo "  --- Reseaux Docker ---"
  docker network ls --format '  {{.Name}} ({{.Driver}})' 2>/dev/null
else
  echo "  Docker absent (l'installeur Dokploy l'installera)."
fi

titre "6. Services web deja installes (conflit possible sur 80/443)"
for SVC in nginx apache2 httpd caddy traefik lighttpd; do
  if command -v systemctl >/dev/null 2>&1 && systemctl is-active --quiet "$SVC" 2>/dev/null; then
    stop "Le service '$SVC' est ACTIF : il occupe probablement le port 80/443."
  elif command -v "$SVC" >/dev/null 2>&1; then
    attn "'$SVC' est installe mais pas actif."
  fi
done

titre "7. Processus type 'bot' (recherche de CLAUDIO)"
echo "  Processus node / python / bun / pm2 en cours :"
ps -eo pid,pcpu,pmem,etime,cmd --sort=-pmem 2>/dev/null \
  | grep -Ei 'node|python|bun|deno|pm2|claudio' \
  | grep -vE 'grep|diagnostic-vps|shell-snapshot|environment-manager' \
  | head -15 | sed 's/^/  /' \
  || echo "  (aucun)"
if command -v pm2 >/dev/null 2>&1; then
  echo "  --- pm2 list ---"; pm2 list 2>/dev/null | sed 's/^/  /'
fi
if command -v systemctl >/dev/null 2>&1; then
  echo "  --- Services systemd personnalises actifs ---"
  systemctl list-units --type=service --state=running --no-legend --no-pager 2>/dev/null \
    | grep -viE 'systemd|dbus|cron|ssh|network|resolved|logind|journal|udev|polkit|rsyslog|snapd|unattended|getty|multipathd|chrony|apparmor' \
    | head -15 | sed 's/^/  /'
fi

titre "8. Pare-feu"
if command -v ufw >/dev/null 2>&1; then
  ufw status verbose 2>/dev/null | sed 's/^/  /'
else
  echo "  ufw non installe."
fi

titre "9. Adresse IP publique et DNS"
IP4=$(curl -4 -s --max-time 5 https://ifconfig.io 2>/dev/null || echo "")
[ -n "$IP4" ] && echo "  IPv4 publique : $IP4" || attn "IPv4 publique non determinee."
for SD in dokploy sign; do
  H="${SD}.thomasloiseauvisuals.com"
  R=$(getent hosts "$H" 2>/dev/null | awk '{print $1}' | head -1)
  if [ -n "$R" ]; then
    if [ "$R" = "$IP4" ]; then ok "$H -> $R (pointe bien sur ce serveur)"
    else attn "$H -> $R (ne pointe PAS sur ce serveur : $IP4)"; fi
  else
    echo "  $H : aucun enregistrement DNS pour l'instant (normal avant configuration)."
  fi
done

titre "FIN DU DIAGNOSTIC"
echo "  Copiez-collez TOUT cet affichage dans la conversation."
echo "  Aucune modification n'a ete faite sur le serveur."

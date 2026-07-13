#!/usr/bin/env bash
# Télécharge les 23 illustrations "apothicaire" par peptide (Higgsfield / Nano Banana).
# À lancer EN LOCAL (le CDN est bloqué depuis la session cloud).
# Usage : bash telecharger-illustrations.sh   → crée ./illustrations-peptides/*.png
set -euo pipefail
DIR="illustrations-peptides"
mkdir -p "$DIR"
B="https://d8j0ntlcm91z4.cloudfront.net/user_35l09F9jlOjjQja9Tn7oygadouN"

dl () { echo "→ $2"; curl -fsSL "$B/$1" -o "$DIR/$2"; }

# ⚖️ Métabolisme
dl "hf_20260713_110044_aa93b024-fbff-4151-8d02-a1b120514af5.png" "retatrutide.png"
dl "hf_20260713_121653_f3cc8462-e190-4264-ab0c-d98d89be7743.png" "semaglutide.png"
dl "hf_20260713_121716_2e1717c8-b62f-45d6-b95a-c8cb52867948.png" "tirzepatide.png"
dl "hf_20260713_121719_fb29a5c2-12e0-443d-8f03-2590dd423234.png" "mots-c.png"
# 💪 Muscle & performance
dl "hf_20260713_121723_241d5e36-6c25-4d52-aed2-d5bcc349b71e.png" "cjc-1295.png"
dl "hf_20260713_121727_5b0ef870-b7c7-4421-ba79-a064f5f40c0f.png" "ipamoreline.png"
dl "hf_20260713_121735_f986d76b-4a40-477f-89db-79d2af87443a.png" "igf-1.png"
dl "hf_20260713_121739_47a78e8c-33fd-4b5f-9417-540da8e3bbe8.png" "follistatine.png"
# 🩹 Réparation & régénération
dl "hf_20260713_110048_025785cc-43e2-4d89-a039-d677f1b61f1c.png" "bpc-157.png"
dl "hf_20260713_121742_ba0ed5ea-35d6-4410-9cff-b3f9e289f406.png" "tb-500.png"
dl "hf_20260713_121745_b290a83a-c068-4da6-b4f4-685205183252.png" "ghk-cu.png"
dl "hf_20260713_121748_c4403c38-2e3c-462c-b837-8cad78fe7d52.png" "kpv.png"
# 🧠 Fonctions cognitives
dl "hf_20260713_121809_0dd0760f-a0fc-44a6-8abe-9774cb3d712f.png" "semax.png"
dl "hf_20260713_121817_69335e12-238c-4af6-a505-e95781333b9c.png" "selank.png"
dl "hf_20260713_121824_6aa75ff9-e0d7-45c2-9193-f90e34c0500e.png" "cortagen.png"
dl "hf_20260713_121829_61b4113f-c132-4d0b-b8d9-a590069d27f5.png" "p21.png"
# ⏳ Longévité & santé cellulaire
dl "hf_20260713_110052_931fd4b4-b0de-47b2-a99b-50fd9e244e42.png" "epithalon.png"
dl "hf_20260713_121834_fd39d1f1-c7cf-4948-b07c-ba884514deb8.png" "thymosine-alpha1.png"
dl "hf_20260713_121837_c8401958-cf39-4448-9a7f-3ff6c55d4444.png" "glutathion.png"
dl "hf_20260713_121842_ad0455a0-37c9-40d1-8046-dbbf1d1120c8.png" "humanine.png"
# 🌙 Sommeil, humeur & vitalité
dl "hf_20260713_121849_58aa607c-1e45-4129-8a07-1fb72bab0cdd.png" "dsip.png"
dl "hf_20260713_121852_89ef0945-652e-48a3-b45f-44f0433b0861.png" "ocytocine.png"
dl "hf_20260713_121859_391e803c-c724-4f9e-bc0c-6fd700b880c7.png" "pt-141.png"

echo "✅ 23 illustrations téléchargées dans ./$DIR/"

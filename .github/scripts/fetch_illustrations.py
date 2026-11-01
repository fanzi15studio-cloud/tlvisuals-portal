"""Télécharge les illustrations Higgsfield listées dans le manifeste et les importe
dans le dépôt en WebP optimisé.

- Web (app)   : public/aeterna-guide-peptides/illustrations/<slug>.webp  (1200 px, q82)
- HD (archive): clients/aeterna-labs/livraison/illustrations-peptides/<slug>.webp (pleine résolution, q90)

Écrit un rapport JSON ; ne s'arrête pas sur une image en échec (les autres sont conservées).
"""
import io
import json
import sys
import time
import urllib.request
from pathlib import Path

from PIL import Image

MANIFEST = Path("clients/aeterna-labs/brand/illustrations-manifest.json")
WEB_DIR = Path("public/aeterna-guide-peptides/illustrations")
HD_DIR = Path("clients/aeterna-labs/livraison/illustrations-peptides")
REPORT = Path("clients/aeterna-labs/livraison/illustrations-peptides/_rapport.json")
WEB_WIDTH = 1200


def download(url: str, tries: int = 4) -> bytes:
    last = None
    for attempt in range(tries):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0 (aeterna-illustrations-fetch)"})
            with urllib.request.urlopen(req, timeout=60) as r:
                return r.read()
        except Exception as e:  # noqa: BLE001
            last = e
            time.sleep(2 ** attempt)
    raise RuntimeError(f"échec téléchargement : {last}")


def main() -> int:
    data = json.loads(MANIFEST.read_text(encoding="utf-8"))
    WEB_DIR.mkdir(parents=True, exist_ok=True)
    HD_DIR.mkdir(parents=True, exist_ok=True)
    report = {"ok": [], "failed": []}
    for item in data["items"]:
        slug = item["slug"]
        try:
            raw = download(item["source_url"])
            im = Image.open(io.BytesIO(raw)).convert("RGB")
            im.save(HD_DIR / f"{slug}.webp", "WEBP", quality=90, method=6)
            h = round(im.height * WEB_WIDTH / im.width)
            im.resize((WEB_WIDTH, h), Image.LANCZOS).save(WEB_DIR / f"{slug}.webp", "WEBP", quality=82, method=6)
            report["ok"].append({"slug": slug, "source_px": [im.width, im.height]})
            print(f"OK   {slug}  {im.width}x{im.height}")
        except Exception as e:  # noqa: BLE001
            report["failed"].append({"slug": slug, "error": str(e)})
            print(f"FAIL {slug}: {e}", file=sys.stderr)
    REPORT.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"\n{len(report['ok'])} OK / {len(report['failed'])} échec(s)")
    return 0


if __name__ == "__main__":
    sys.exit(main())

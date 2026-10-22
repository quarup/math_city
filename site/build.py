"""Assemble the public website into _site/ (run from the repo root).

    pip install markdown
    python3 site/build.py

Copies the static pages, pulls the images from docs/readme/ (so the PNGs are
not duplicated in git) and renders PRIVACY.md into privacy/index.html, so the
web page can never drift from the policy in the repo. Used by
.github/workflows/pages.yml; also handy for a local preview:
`python3 -m http.server -d _site`.
"""

import shutil
from pathlib import Path

import markdown

REPO = Path(__file__).resolve().parent.parent
SITE = REPO / "site"
OUT = REPO / "_site"

STATIC = ["index.html", "style.css", "favicon-32.png", "apple-touch-icon.png"]
IMAGES = [
    "lockup.png",
    "city_day.png",
    "city_night.png",
    "q_protractor.png",
    "q_fraction.png",
    "q_scratchpad.png",
    "city_play.jpg",
]


def main() -> None:
    if OUT.exists():
        shutil.rmtree(OUT)
    (OUT / "img").mkdir(parents=True)
    (OUT / "privacy").mkdir()

    for name in STATIC:
        shutil.copy2(SITE / name, OUT / name)
    for name in IMAGES:
        shutil.copy2(REPO / "docs" / "readme" / name, OUT / "img" / name)

    body = markdown.markdown((REPO / "PRIVACY.md").read_text(encoding="utf-8"))
    template = (SITE / "privacy.html").read_text(encoding="utf-8")
    assert "{{CONTENT}}" in template
    (OUT / "privacy" / "index.html").write_text(
        template.replace("{{CONTENT}}", body), encoding="utf-8"
    )
    (OUT / ".nojekyll").write_text("")
    print(f"built {sum(1 for p in OUT.rglob('*') if p.is_file())} files into {OUT.name}/")


if __name__ == "__main__":
    main()

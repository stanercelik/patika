#!/usr/bin/env python3
"""Patika path paywall'larını 28 günlük paywall'dan eşitler.

Tasarımın kaynağı RevenueCat panelindeki **28 günlük** paywall'ın yayındaki hâlidir
(ürün sahibi orada düzenliyor). Bu betik onu okur, yalnız paket kimliğini değiştirip
7/14/21 günlük paywall'lara yazar ve yayınlar.

Uzunluğa göre değişen tek parça ilerleme izidir (`Progress trail`): patikanın gün
sayısı kadar parça, ilki dolu (tamamlanan 1. adım). RevenueCat'te parça sayısı değişkene
bağlanamadığı için her paywall'da gün sayısına göre yeniden kurulur.

Tek düzeltme: kapatma ikonu bir butona sarılı değilse sarılır. İşlevsiz bir ✕
kullanıcıyı paywall'a kilitler (onboarding'in sonunda uygulamanın tamamı).

    python3 scripts/revenuecat/sync_paywalls.py            # taslaklara yazar
    python3 scripts/revenuecat/sync_paywalls.py --publish  # yazar ve yayınlar

Gerekenler: `rc` CLI (brew install revenuecat) ve `rc auth login`.
"""
import copy, json, subprocess, sys, tempfile

PROJECT = "proj898e5829"
SOURCE = ("pwef6ffd359de943b7", "path_unlock_28d")
TARGETS = [
    ("pw90b35a2daa0f4be2", "path_unlock_7d"),
    ("pwc3b073075134453b", "path_unlock_14d"),
    ("pwa49e7bb0740e4852", "path_unlock_21d"),
]


def rc(*args, body=None):
    cmd = ["rc", *args]
    if body is not None:
        with tempfile.NamedTemporaryFile("w", suffix=".json", delete=False) as f:
            json.dump(body, f)
        cmd += ["--body", "@" + f.name]
    out = subprocess.run(cmd, capture_output=True, text=True)
    if out.returncode != 0:
        sys.exit(f"{' '.join(args[:3])} failed: {out.stderr.strip() or out.stdout.strip()}")
    return json.loads(out.stdout) if out.stdout.strip().startswith("{") else out.stdout


def paywall(pw_id):
    return rc("api", "GET", f"/projects/{PROJECT}/paywalls/{pw_id}?expand=components")


def walk(node, fn):
    if isinstance(node, dict):
        fn(node)
        for value in node.values():
            walk(value, fn)
    elif isinstance(node, list):
        for value in node:
            walk(value, fn)


def ensure_close_button(config):
    """`Top row` içindeki çıplak ✕ ikonunu `navigate_back` butonuna sarar."""
    fixed = []

    def fix(node):
        # Zaten sarılmış ikonun kabı yeniden gezilir; ikinci kez sarılmaz.
        if node.get("type") != "stack" or node.get("name") == "Close hit area":
            return
        children = node.get("components") or []
        for i, child in enumerate(children):
            if child.get("type") == "icon" and child.get("icon_name") == "x":
                children[i] = {
                    "type": "button",
                    "id": child["id"] + "b",
                    "name": "Close",
                    "action": {"type": "navigate_back"},
                    "stack": {
                        "type": "stack", "id": child["id"] + "s", "name": "Close hit area",
                        "components": [child],
                        "dimension": {"type": "vertical", "alignment": "center", "distribution": "center"},
                        "size": {"width": {"type": "fixed", "value": 44}, "height": {"type": "fixed", "value": 44}},
                        "spacing": 0, "background": None, "background_color": None, "badge": None,
                        "border": None, "shadow": None, "shape": None,
                        "margin": {"top": 0, "leading": 0, "bottom": 0, "trailing": 0},
                        "padding": {"top": 0, "leading": 0, "bottom": 0, "trailing": 0},
                    },
                }
                fixed.append(child["id"])

    walk(config, fix)
    return fixed


def set_package(config, package_id):
    def fix(node):
        if node.get("type") == "package":
            node["package_id"] = package_id
    walk(config, fix)


TRAIL_DONE = "#E9BA8FFF"     # apricot: tamamlanan 1. adım
TRAIL_AHEAD = "#60716BFF"    # plateBorder: kalan adımlar


def trail_segment(index, done):
    return {
        "type": "stack", "id": f"trailseg{index:02d}", "name": f"Trail step {index + 1}",
        "components": [],
        "dimension": {"type": "vertical", "alignment": "center", "distribution": "start"},
        "size": {"width": {"type": "fill", "value": None}, "height": {"type": "fixed", "value": 4}},
        "spacing": 0,
        "background": {"type": "color", "value": {"light": {"type": "hex",
                                                            "value": TRAIL_DONE if done else TRAIL_AHEAD}}},
        "background_color": None, "badge": None, "border": None, "shadow": None,
        "shape": {"type": "pill", "corners": None},
        "margin": {"top": 0, "leading": 0, "bottom": 0, "trailing": 0},
        "padding": {"top": 0, "leading": 0, "bottom": 0, "trailing": 0},
    }


def set_trail(config, days):
    """`Progress trail` yığınını `days` parçayla yeniden kurar; ilki dolu."""
    def fix(node):
        if node.get("type") == "stack" and node.get("name") == "Progress trail":
            node["components"] = [trail_segment(i, i == 0) for i in range(days)]
    walk(config, fix)


def days_of(package_id):
    return int(package_id.rsplit("_", 1)[1].rstrip("d"))


def push(pw_id, package_id, source, publish):
    current = paywall(pw_id)
    config = copy.deepcopy(source["components_config"])
    set_package(config, package_id)
    set_trail(config, days_of(package_id))
    body = {
        "revision": current["revision"],
        "components_config": config,
        "components_localizations": source["components_localizations"],
        "default_locale": source["default_locale"],
        "automatically_scale_font_size": source["automatically_scale_font_size"],
    }
    rc("api", "PATCH", f"/projects/{PROJECT}/paywalls/{pw_id}", body=body)
    print(f"draft updated: {current['name']} ({package_id})")
    if publish:
        rc("paywalls", "publish", pw_id, "--project-id", PROJECT, "--yes", "--no-input")
        print(f"published:     {current['name']}")


def main():
    publish = "--publish" in sys.argv
    data = paywall(SOURCE[0])
    components = data["components"]
    source = components.get("draft") or components.get("published")
    if source is None:
        sys.exit("28-day paywall has no components")
    source = copy.deepcopy(source)
    fixed = ensure_close_button(source["components_config"])
    if fixed:
        print(f"close icon wrapped in a button: {fixed}")
        push(SOURCE[0], SOURCE[1], source, publish)
    for pw_id, package_id in TARGETS:
        push(pw_id, package_id, source, publish)


if __name__ == "__main__":
    main()

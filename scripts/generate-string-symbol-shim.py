#!/usr/bin/env python3
"""Localizable.xcstrings'ten test sembol örtüsü üretir.

Xcode, katalogdaki her anahtar için `LocalizedStringResource.<anahtarCamelCase>`
sembolü üretir. Elle `swiftc` ile derlenen test betikleri (Tests/*) Xcode dışında
çalıştığı için o sembolleri görmez; bu betik aynı imzaları düz Swift olarak yazar.

    python3 scripts/generate-string-symbol-shim.py            # yazar
    python3 scripts/generate-string-symbol-shim.py --check    # güncel mi? (CI için)

Katalog değişince yeniden çalıştırılır. Örtü yalnızca testlerde derlenir, uygulamaya girmez.
"""
import json, pathlib, re, sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
CATALOG = ROOT / "MyApp/Content/Localizable.xcstrings"
OUT = ROOT / "Tests/Support/StringSymbolsShim.swift"


def symbol(key: str) -> str:
    parts = key.split(".")
    return parts[0] + "".join(p[:1].upper() + p[1:] for p in parts[1:])


def first_value(entry: dict) -> str:
    en = entry["localizations"]["en"]
    if "stringUnit" in en:
        return en["stringUnit"]["value"]
    return en["variations"]["plural"]["other"]["stringUnit"]["value"]


def render() -> str:
    strings = json.loads(CATALOG.read_text())["strings"]
    lines = [
        "// Bu dosya üretilir: python3 scripts/generate-string-symbol-shim.py",
        "// Xcode'un `LocalizedStringResource` sembollerinin elle derlenen test betikleri için karşılığı.",
        "import Foundation",
        "",
        "extension LocalizedStringResource {",
    ]
    for key in sorted(strings):
        value = first_value(strings[key])
        args = re.findall(r"%(?:\d+\$)?(lld|@)", value)
        name = symbol(key)
        if not args:
            lines.append(f'    static var {name}: LocalizedStringResource {{ LocalizedStringResource("{key}") }}')
        else:
            params = ", ".join(f"_ arg{i + 1}: {'Int' if a == 'lld' else 'String'}" for i, a in enumerate(args))
            lines.append(
                f'    static func {name}({params}) -> LocalizedStringResource {{ LocalizedStringResource("{key}") }}'
            )
    lines.append("}")
    return "\n".join(lines) + "\n"


if __name__ == "__main__":
    content = render()
    if "--check" in sys.argv:
        if not OUT.exists() or OUT.read_text() != content:
            print("Tests/Support/StringSymbolsShim.swift eski: python3 scripts/generate-string-symbol-shim.py", file=sys.stderr)
            sys.exit(1)
        print("shim güncel")
    else:
        OUT.parent.mkdir(parents=True, exist_ok=True)
        OUT.write_text(content)
        print(f"{OUT.relative_to(ROOT)}: {content.count('static ')} sembol")

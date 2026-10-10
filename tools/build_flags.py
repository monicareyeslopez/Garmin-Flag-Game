"""Download flag images and generate the Connect IQ resources that depend on them.

Writes:
  resources/drawables/flags/<code>.png   one per country, fitted to BOX
  resources/drawables/flags.xml          bitmap resource entries
  resources/drawables/launcher_icon.png  app icon
  source/Countries.mc                    names, flag IDs and region ranges

Run from anywhere:  python tools/build_flags.py
Requires Pillow. Flag images come from flagcdn.com (public domain).
"""

import io
import sys
import urllib.request
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
FLAG_DIR = ROOT / "resources" / "drawables" / "flags"
FLAGS_XML = ROOT / "resources" / "drawables" / "flags.xml"
ICON_PNG = ROOT / "resources" / "drawables" / "launcher_icon.png"
COUNTRIES_MC = ROOT / "source" / "Countries.mc"

SOURCE_URL = "https://flagcdn.com/w320/{code}.png"
BOX = (260, 174)  # largest flag size that leaves room for text on a 390px round screen
ICON_SIZE = 56

# Region order here is the order of the region menu on the watch.
REGIONS = [
    ("Africa", [
        ("dz", "Algeria"), ("ao", "Angola"), ("bj", "Benin"), ("bw", "Botswana"),
        ("bf", "Burkina Faso"), ("bi", "Burundi"), ("cv", "Cabo Verde"), ("cm", "Cameroon"),
        ("cf", "Central African Republic"), ("td", "Chad"), ("km", "Comoros"), ("cg", "Congo"),
        ("cd", "DR Congo"), ("ci", "Côte d'Ivoire"), ("dj", "Djibouti"), ("eg", "Egypt"),
        ("gq", "Equatorial Guinea"), ("er", "Eritrea"), ("sz", "Eswatini"), ("et", "Ethiopia"),
        ("ga", "Gabon"), ("gm", "Gambia"), ("gh", "Ghana"), ("gn", "Guinea"),
        ("gw", "Guinea-Bissau"), ("ke", "Kenya"), ("ls", "Lesotho"), ("lr", "Liberia"),
        ("ly", "Libya"), ("mg", "Madagascar"), ("mw", "Malawi"), ("ml", "Mali"),
        ("mr", "Mauritania"), ("mu", "Mauritius"), ("ma", "Morocco"), ("mz", "Mozambique"),
        ("na", "Namibia"), ("ne", "Niger"), ("ng", "Nigeria"), ("rw", "Rwanda"),
        ("st", "Sao Tome and Principe"), ("sn", "Senegal"), ("sc", "Seychelles"),
        ("sl", "Sierra Leone"), ("so", "Somalia"), ("za", "South Africa"), ("ss", "South Sudan"),
        ("sd", "Sudan"), ("tz", "Tanzania"), ("tg", "Togo"), ("tn", "Tunisia"), ("ug", "Uganda"),
        ("zm", "Zambia"), ("zw", "Zimbabwe"),
    ]),
    ("Americas", [
        ("ag", "Antigua and Barbuda"), ("ar", "Argentina"), ("bs", "Bahamas"), ("bb", "Barbados"),
        ("bz", "Belize"), ("bo", "Bolivia"), ("br", "Brazil"), ("ca", "Canada"), ("cl", "Chile"),
        ("co", "Colombia"), ("cr", "Costa Rica"), ("cu", "Cuba"), ("dm", "Dominica"),
        ("do", "Dominican Republic"), ("ec", "Ecuador"), ("sv", "El Salvador"), ("gd", "Grenada"),
        ("gt", "Guatemala"), ("gy", "Guyana"), ("ht", "Haiti"), ("hn", "Honduras"),
        ("jm", "Jamaica"), ("mx", "Mexico"), ("ni", "Nicaragua"), ("pa", "Panama"),
        ("py", "Paraguay"), ("pe", "Peru"), ("kn", "Saint Kitts and Nevis"), ("lc", "Saint Lucia"),
        ("vc", "Saint Vincent and the Grenadines"), ("sr", "Suriname"),
        ("tt", "Trinidad and Tobago"), ("us", "United States"), ("uy", "Uruguay"),
        ("ve", "Venezuela"),
    ]),
    ("Asia", [
        ("af", "Afghanistan"), ("am", "Armenia"), ("az", "Azerbaijan"), ("bh", "Bahrain"),
        ("bd", "Bangladesh"), ("bt", "Bhutan"), ("bn", "Brunei"), ("kh", "Cambodia"),
        ("cn", "China"), ("cy", "Cyprus"), ("ge", "Georgia"), ("in", "India"), ("id", "Indonesia"),
        ("ir", "Iran"), ("iq", "Iraq"), ("il", "Israel"), ("jp", "Japan"), ("jo", "Jordan"),
        ("kz", "Kazakhstan"), ("kw", "Kuwait"), ("kg", "Kyrgyzstan"), ("la", "Laos"),
        ("lb", "Lebanon"), ("my", "Malaysia"), ("mv", "Maldives"), ("mn", "Mongolia"),
        ("mm", "Myanmar"), ("np", "Nepal"), ("kp", "North Korea"), ("om", "Oman"),
        ("pk", "Pakistan"), ("ps", "Palestine"), ("ph", "Philippines"), ("qa", "Qatar"),
        ("sa", "Saudi Arabia"), ("sg", "Singapore"), ("kr", "South Korea"), ("lk", "Sri Lanka"),
        ("sy", "Syria"), ("tj", "Tajikistan"), ("th", "Thailand"), ("tl", "Timor-Leste"),
        ("tr", "Turkey"), ("tm", "Turkmenistan"), ("ae", "United Arab Emirates"),
        ("uz", "Uzbekistan"), ("vn", "Vietnam"), ("ye", "Yemen"),
    ]),
    ("Europe", [
        ("al", "Albania"), ("ad", "Andorra"), ("at", "Austria"), ("by", "Belarus"),
        ("be", "Belgium"), ("ba", "Bosnia and Herzegovina"), ("bg", "Bulgaria"), ("hr", "Croatia"),
        ("cz", "Czechia"), ("dk", "Denmark"), ("ee", "Estonia"), ("fi", "Finland"),
        ("fr", "France"), ("de", "Germany"), ("gr", "Greece"), ("hu", "Hungary"),
        ("is", "Iceland"), ("ie", "Ireland"), ("it", "Italy"), ("lv", "Latvia"),
        ("li", "Liechtenstein"), ("lt", "Lithuania"), ("lu", "Luxembourg"), ("mt", "Malta"),
        ("md", "Moldova"), ("mc", "Monaco"), ("me", "Montenegro"), ("nl", "Netherlands"),
        ("mk", "North Macedonia"), ("no", "Norway"), ("pl", "Poland"), ("pt", "Portugal"),
        ("ro", "Romania"), ("ru", "Russia"), ("sm", "San Marino"), ("rs", "Serbia"),
        ("sk", "Slovakia"), ("si", "Slovenia"), ("es", "Spain"), ("se", "Sweden"),
        ("ch", "Switzerland"), ("ua", "Ukraine"), ("gb", "United Kingdom"), ("va", "Vatican City"),
    ]),
    ("Oceania", [
        ("au", "Australia"), ("fj", "Fiji"), ("ki", "Kiribati"), ("mh", "Marshall Islands"),
        ("fm", "Micronesia"), ("nr", "Nauru"), ("nz", "New Zealand"), ("pw", "Palau"),
        ("pg", "Papua New Guinea"), ("ws", "Samoa"), ("sb", "Solomon Islands"), ("to", "Tonga"),
        ("tv", "Tuvalu"), ("vu", "Vanuatu"),
    ]),
]

# Flags that can't be told apart at watch size: either answer counts.
LOOKALIKES = {
    "td": "Chad or Romania",
    "ro": "Romania or Chad",
    "id": "Indonesia or Monaco",
    "mc": "Monaco or Indonesia",
}


def fetch_flag(code: str) -> None:
    out = FLAG_DIR / f"{code}.png"
    if out.exists():
        return
    req = urllib.request.Request(SOURCE_URL.format(code=code), headers={"User-Agent": "flag-quiz-build"})
    with urllib.request.urlopen(req, timeout=30) as resp:
        img = Image.open(io.BytesIO(resp.read())).convert("RGBA")
    scale = min(BOX[0] / img.width, BOX[1] / img.height)
    size = (round(img.width * scale), round(img.height * scale))
    img.resize(size, Image.LANCZOS).save(out, optimize=True)


def write_flags_xml(codes: list[str]) -> None:
    lines = ["<!-- Generated by tools/build_flags.py. Do not edit. -->", "<drawables>"]
    for code in codes:
        lines.append(f'    <bitmap id="flag_{code}" filename="flags/{code}.png" packingFormat="png" />')
    lines.append("</drawables>")
    FLAGS_XML.write_text("\n".join(lines) + "\n", encoding="utf-8")


def mc_string(s: str) -> str:
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


def wrap_items(items: list[str], indent: str = "        ", width: int = 100) -> str:
    lines, line = [], indent
    for item in items:
        piece = item + ", "
        if len(line) + len(piece) > width and line.strip():
            lines.append(line.rstrip())
            line = indent
        line += piece
    lines.append(line.rstrip().rstrip(","))
    return "\n".join(lines)


def write_countries_mc() -> None:
    names, flags, starts = [], [], [0]
    for _, countries in REGIONS:
        for code, name in countries:
            names.append(mc_string(LOOKALIKES.get(code, name)))
            flags.append(f"Rez.Drawables.flag_{code}")
        starts.append(len(names))
    region_names = [mc_string("World")] + [mc_string(r) for r, _ in REGIONS]

    src = f"""// Generated by tools/build_flags.py. Do not edit.
import Toybox.Lang;

module Countries {{

    // Index 0 is every country; 1..n are the regions below.
    const REGION_NAMES = [
{wrap_items(region_names)}
    ] as Array<String>;

    // Countries are grouped by region: region r (1-based) spans
    // REGION_START[r - 1] up to, but not including, REGION_START[r].
    const REGION_START = [
{wrap_items([str(s) for s in starts])}
    ] as Array<Number>;

    const NAMES = [
{wrap_items(names)}
    ] as Array<String>;

    const FLAGS = [
{wrap_items(flags)}
    ] as Array<ResourceId>;
}}
"""
    COUNTRIES_MC.write_text(src, encoding="utf-8")


def write_icon() -> None:
    s = 4  # supersample for smooth edges
    n = ICON_SIZE * s
    img = Image.new("RGBA", (n, n), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.ellipse((0, 0, n - 1, n - 1), fill=(20, 60, 110, 255))
    pole_x, top, bottom = 17 * s, 12 * s, 45 * s
    d.rounded_rectangle((pole_x - s, top, pole_x + s, bottom), radius=s, fill=(235, 235, 235, 255))
    left, right, h = pole_x + s, 42 * s, 6 * s
    for i, colour in enumerate([(220, 50, 50), (245, 245, 245), (50, 160, 80)]):
        y = 14 * s + i * h
        d.rectangle((left, y, right, y + h), fill=colour + (255,))
    img.resize((ICON_SIZE, ICON_SIZE), Image.LANCZOS).save(ICON_PNG, optimize=True)


def main() -> int:
    codes = [code for _, countries in REGIONS for code, _ in countries]
    assert len(codes) == len(set(codes)) == 195, f"expected 195 unique codes, got {len(codes)}"

    FLAG_DIR.mkdir(parents=True, exist_ok=True)
    COUNTRIES_MC.parent.mkdir(parents=True, exist_ok=True)

    failed = []
    for i, code in enumerate(codes, 1):
        try:
            fetch_flag(code)
        except Exception as exc:  # keep going so one bad download doesn't hide the rest
            failed.append((code, exc))
        print(f"\r{i}/{len(codes)} flags", end="", flush=True)
    print()
    if failed:
        for code, exc in failed:
            print(f"  failed: {code}: {exc}", file=sys.stderr)
        return 1

    write_flags_xml(codes)
    write_countries_mc()
    write_icon()
    print(f"Wrote {len(codes)} flags, {FLAGS_XML.name}, {COUNTRIES_MC.name}, {ICON_PNG.name}")
    return 0


if __name__ == "__main__":
    sys.exit(main())

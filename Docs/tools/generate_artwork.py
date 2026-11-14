#!/usr/bin/env python3
"""Generate Sorta's original, self-contained SVG documentation artwork."""

from html import escape
from pathlib import Path


ASSETS = Path(__file__).resolve().parents[1] / "assets"
FONT = "Arial, Helvetica, sans-serif"
COPY = {
    "en": {
        "tagline": "Your photos. Carefully organized.",
        "eyebrow": "LOCAL PHOTO TOOLS",
        "date": "BY DATE",
        "photos": "photos",
        "illustration": "CONCEPT ILLUSTRATION",
        "banner_desc": "Original vector illustration of photo cards becoming folders by date beside the Sorta name. Not an app screenshot.",
        "workflow_title": "Start small. Check carefully.",
        "workflow_desc": "Concept illustration: try a small set of photo copies with original deletion off, check the results, then process the full archive with a separate backup. The backup is prepared by the user, not automatically by Sorta.",
        "steps": [
            ("A small set of copies", ["Try a few photos first."], ["Keep original deletion off."]),
            ("Check the result", ["Compare photos,", "dates and quality."], ["Continue only when", "you are satisfied."]),
            ("Your archive + a backup", ["Keep a separate", "backup of your archive."], ["Then process all photos."]),
        ],
        "footer": "Keep the originals until you have checked the result.",
    },
    "ru": {
        "tagline": "Порядок в фотографиях. Бережно.",
        "eyebrow": "ИНСТРУМЕНТЫ ДЛЯ ФОТО",
        "date": "ПО ДАТЕ",
        "photos": "фотографии",
        "illustration": "КОНЦЕПТУАЛЬНАЯ ИЛЛЮСТРАЦИЯ",
        "banner_desc": "Оригинальная векторная иллюстрация: фотокарточки становятся папками по датам рядом с названием Sorta. Это не скриншот приложения.",
        "workflow_title": "Начните с малого. Проверьте результат.",
        "workflow_desc": "Иллюстрация: попробуйте небольшой набор копий фотографий с выключенным удалением оригиналов, проверьте результат и только затем обработайте архив с отдельной резервной копией. Копию готовит пользователь, а не Sorta автоматически.",
        "steps": [
            ("Небольшой набор копий", ["Начните с нескольких", "фотографий."], ["Без удаления оригиналов."]),
            ("Проверка результата", ["Сравните фото,", "даты и качество."], ["Продолжайте только", "после проверки."]),
            ("Архив + резервная копия", ["Сохраните отдельную", "копию всего архива."], ["Затем обработайте все фото."]),
        ],
        "footer": "Сохраняйте оригиналы, пока не убедитесь в результате.",
    },
}


def label(x, y, value, size=22, color="#F5F6FA", weight=400, extra=""):
    return (f'<text x="{x}" y="{y}" font-size="{size}" fill="{color}" '
            f'font-weight="{weight}" {extra}>{escape(value)}</text>')


def photo(name, x, y, width=180, angle=0, warm=False):
    """An invented landscape, drawn directly as vector geometry; no source photo."""
    sky = "#D9C9F3" if warm else "#C3D4FF"
    ridge = "#8479AE" if warm else "#809ADB"
    front = "#565B8B" if warm else "#536EB6"
    sun = "#F8DBAF" if warm else "#FFF2C9"
    scale = width / 180
    return f'''<g transform="translate({x} {y}) rotate({angle} {width / 2} {width * 0.61})">
<g transform="scale({scale})">
  <rect x="5" y="10" width="180" height="222" rx="16" fill="#090B1C" opacity=".16"/>
  <rect width="180" height="222" rx="16" fill="#EEF0FC" stroke="#CAD3F2" stroke-width="2"/>
  <defs><clipPath id="{name}"><rect x="13" y="13" width="154" height="145" rx="9"/></clipPath></defs>
  <g clip-path="url(#{name})">
    <rect x="13" y="13" width="154" height="145" fill="{sky}"/>
    <circle cx="132" cy="46" r="17" fill="{sun}"/>
    <path d="M-5 134L54 61L94 108L126 80L188 149V175H-5Z" fill="{ridge}"/>
    <path d="M-8 147Q30 105 67 132T181 114V174H-8Z" fill="{front}"/>
    <path d="M-8 154Q51 135 89 149T188 139" fill="none" stroke="#C1CEF4" stroke-opacity=".38" stroke-width="3"/>
  </g>
  <path d="M17 181H117" stroke="#929EC5" stroke-width="5" stroke-linecap="round"/>
  <path d="M17 197H75" stroke="#BEC7E0" stroke-width="4" stroke-linecap="round"/>
  <circle cx="153" cy="191" r="7" fill="#BDC9EF"/>
</g></g>'''


def folder(x, y, date, subtitle, violet=False):
    accent = "#AA96F5" if violet else "#8AA1FF"
    fill = "#2E2949" if violet else "#252D4C"
    return f'''<g transform="translate({x} {y})">
  <path d="M0 24V12Q0 0 12 0H79Q87 0 94 8L105 20H278Q294 20 294 36V115Q294 131 278 131H16Q0 131 0 115Z" fill="{fill}" stroke="{accent}" stroke-opacity=".6" stroke-width="2"/>
  <rect x="1" y="35" width="292" height="95" rx="15" fill="{fill}"/>
  <path d="M2 39H292" stroke="{accent}" stroke-opacity=".32"/>
  <rect x="23" y="58" width="49" height="49" rx="10" fill="{accent}" fill-opacity=".13"/>
  <g stroke="{accent}" stroke-width="2" fill="none" stroke-linecap="round" stroke-linejoin="round">
    <rect x="33" y="69" width="29" height="26" rx="4"/>
    <path d="M34 89L42 81L48 87L54 79L61 88"/>
    <circle cx="42" cy="76" r="2" fill="{accent}" stroke="none"/>
  </g>
  {label(91, 81, date, 27, '#E5E9FC', 700)}
  {label(92, 107, subtitle, 17, '#A9ADBE')}
</g>'''


def arrow(x, y, color="#8AA1FF", length=63):
    return (f'<path d="M{x} {y}h{length}m-10-10 10 10-10 10" fill="none" '
            f'stroke="{color}" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>')


def svg(width, height, title, description, content):
    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}" role="img" aria-labelledby="title desc">
<!-- SPDX-License-Identifier: CC0-1.0 -->
<title id="title">{escape(title)}</title>
<desc id="desc">{escape(description)}</desc>
{content}
</svg>
'''


def banner(language):
    copy = COPY[language]
    content = f'''<defs>
  <linearGradient id="background" x1="0" y1="0" x2="1" y2="1"><stop stop-color="#0D0D14"/><stop offset="1" stop-color="#202039"/></linearGradient>
  <radialGradient id="glow"><stop stop-color="#6E8BFF" stop-opacity=".24"/><stop offset="1" stop-color="#6E8BFF" stop-opacity="0"/></radialGradient>
</defs>
<rect x="1" y="1" width="1918" height="478" rx="28" fill="url(#background)" stroke="#35364D" stroke-width="2"/>
<path d="M1080 24V456M1260 24V456M1440 24V456M1620 24V456M1800 24V456M1000 96H1870M1000 192H1870M1000 288H1870M1000 384H1870" stroke="#A8B8FF" opacity=".055" fill="none"/>
<ellipse cx="1460" cy="245" rx="464" ry="234" fill="url(#glow)"/>
<g font-family="{FONT}">
  <rect x="96" y="61" width="68" height="68" rx="21" fill="#20263E" stroke="#4C598B" stroke-width="2"/>
  <rect x="112" y="78" width="30" height="31" rx="5" transform="rotate(-12 127 94)" fill="#5366AE"/>
  <rect x="120" y="84" width="30" height="31" rx="5" fill="#A4B5FF"/>
  <path d="M123 107L131 96L136 102L142 95L148 108" fill="#4C5B99"/>
  <circle cx="140" cy="91" r="3" fill="#F3E8C9"/>
  {label(191, 104, copy['eyebrow'], 21, '#A9ADBE', 700, 'letter-spacing="3"')}
  {label(89, 265, 'Sorta', 132, '#F5F6FA', 700, 'letter-spacing="-6"')}
  <path d="M100 297H175" stroke="#6E8BFF" stroke-width="4" stroke-linecap="round"/>
  <path d="M191 297H216" stroke="#8A78BD" stroke-width="4" stroke-linecap="round"/>
  {label(96, 359, copy['tagline'], 39, '#D5DAED')}
  {label(98, 424, 'macOS  /  Apple Silicon', 22, '#A2A9C5', 700, 'letter-spacing="2"')}
  <path d="M965 58V422" stroke="#61688C" stroke-opacity=".35"/>
  {photo('photo-back', 1046, 106, 192, -10, True)}
  {photo('photo-front', 1164, 163, 190, 9)}
  {arrow(1397, 242)}
  {label(1429, 285, copy['date'], 16, '#A6AED0', 700, 'text-anchor="middle" letter-spacing="2"')}
  {folder(1531, 104, '2024 / 07', copy['photos'])}
  {folder(1531, 270, '2025 / 02', copy['photos'], True)}
  {label(1825, 441, copy['illustration'], 13, '#979FBE', 400, 'text-anchor="end" letter-spacing="1.5"')}
</g>'''
    return svg(1920, 480, f"Sorta — {copy['tagline']}", copy["banner_desc"], content)


def sample_icon():
    return photo("sample-back", 28, 104, 96, -10, True) + photo("sample-front", 72, 119, 93, 9)


def check_icon():
    return f'''{photo('compare-photo', 37, 106, 109)}
<circle cx="143" cy="213" r="28" fill="#E4E9FB" stroke="#6E8BFF" stroke-width="3"/>
<path d="M163 233L180 250" stroke="#657CBE" stroke-width="7" stroke-linecap="round"/>
<path d="M130 213L139 222L155 203" fill="none" stroke="#526CAB" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/>'''


def archive_icon():
    return '''<g stroke-linejoin="round">
<rect x="70" y="108" width="94" height="118" rx="15" fill="#E4E3F5" stroke="#9684C1" stroke-width="2"/>
<path d="M91 128H143M91 140H133" stroke="#B2A4D4" stroke-width="3" stroke-linecap="round"/>
<path d="M33 153V142Q33 132 43 132H72L85 145H140Q152 145 152 157V222Q152 234 140 234H45Q33 234 33 222Z" fill="#DDE5FF" stroke="#7188CE" stroke-width="2"/>
<path d="M34 165H151" stroke="#9DACE0" stroke-width="2"/>
<rect x="48" y="181" width="30" height="32" rx="5" fill="#F5F7FF" stroke="#A5B4E0"/>
<rect x="87" y="181" width="47" height="5" rx="2" fill="#8398D0"/>
<rect x="87" y="194" width="35" height="5" rx="2" fill="#A8B7DE"/>
<circle cx="149" cy="234" r="22" fill="#F1EDF9" stroke="#9684C1" stroke-width="2"/>
<path d="M140 234L147 241L159 227" fill="none" stroke="#7E6AA8" stroke-width="3" stroke-linecap="round"/>
</g>'''


def workflow(language):
    copy = COPY[language]
    parts = [f'''<rect x="1" y="1" width="1598" height="418" rx="28" fill="#EEF0F6" stroke="#D6DBEA" stroke-width="2"/>
<g font-family="{FONT}">
{label(38, 50, copy['workflow_title'], 30, '#282D46', 700)}
{label(1560, 48, copy['illustration'], 13, '#68718E', 400, 'text-anchor="end" letter-spacing="1.2"')}''']
    for index, (title, body, footnote) in enumerate(copy["steps"]):
        x = 35 + index * 527
        icon = [sample_icon, check_icon, archive_icon][index]()
        parts.append(f'''<g transform="translate({x} 84)">
<rect width="476" height="284" rx="25" fill="#F8F9FD" stroke="#CDD4E8"/>
<circle cx="38" cy="41" r="16" fill="#E3E8F9"/>
{label(38, 46, f'0{index + 1}', 14, '#657AB7', 700, 'text-anchor="middle"')}
{label(68, 49, title, 25, '#303953', 700)}
{icon}''')
        for line, value in enumerate(body):
            parts.append(label(199, 139 + line * 29, value, 21, "#4B5674"))
        for line, value in enumerate(footnote):
            parts.append(label(199, 214 + line * 25, value, 18, "#687493"))
        parts.append("</g>")
    parts += [arrow(522, 226, "#8292BE", 26), arrow(1049, 226, "#8292BE", 26),
              label(38, 400, copy["footer"], 18, "#68718E"), "</g>"]
    return svg(1600, 420, copy["workflow_title"], copy["workflow_desc"], "\n".join(parts))


def main():
    ASSETS.mkdir(parents=True, exist_ok=True)
    for language in COPY:
        for name, render in [("banner", banner), ("workflow", workflow)]:
            path = ASSETS / f"{name}-{language}.svg"
            path.write_text(render(language), encoding="utf-8")
            print(path.name)


if __name__ == "__main__":
    main()

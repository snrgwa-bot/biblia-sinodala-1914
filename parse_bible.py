#!/usr/bin/env python3
"""
Parse the 1914 Romanian Orthodox Bible (Public Domain) from plain text into structured JSON.
Source: https://archive.org/details/biblia-1914-v123
"""
import re
import json
import os

INPUT_FILE = '/Users/dumitrubumbu/Desktop/BIBLIA/Biblia-1914.txt'
OUTPUT_FILE = '/Users/dumitrubumbu/Desktop/BIBLIA/BibliaRomana/BibliaRomana/Resources/biblia_1914.json'

# Short display names for the books
SHORT_NAMES = {
    "FACEREA": "Facerea",
    "EȘIREA": "Eșirea",
    "LEVITICUL": "Leviticul",
    "NUMERII": "Numerii",
    "A DOUA LEGE": "A Doua Lege",
    "CARTEA LUI ISUS NAVÌ": "Isus Navi",
    "JUDECĂTORII": "Judecătorii",
    "CARTEA RUT": "Rut",
    "CARTEA ÎNTÂIA A ÎMPĂRAȚILOR": "1 Împărați",
    "CARTEA A DOUA A ÎMPĂRAȚILOR": "2 Împărați",
    "CARTEA A TREIA A ÎMPĂRAȚILOR": "3 Împărați",
    "CARTEA A PATRA A ÎMPĂRAȚILOR": "4 Împărați",
    "CARTEA ÎNTÂI PARALIPOMENE": "1 Paralipomene",
    "CARTEA A DOUA PARALIPOMENE": "2 Paralipomene",
    "CARTEA LUI ESDRA": "Esdra",
    "CARTEA LUI NEEMIA": "Neemia",
    "CARTEA ESTIREI": "Estera",
    "CARTEA LUI IOV": "Iov",
    "PSALTIREA PROROCULUI ȘI ÎMPĂRATULUI DAVID": "Psalmii",
    "PILDELE LUI SOLOMON": "Pildele",
    "ECLISIASTUL": "Eclisiastul",
    "CÂNTAREA CÂNTĂRILOR LUI SOLOMON": "Cântarea Cântărilor",
    "ISAIA": "Isaia",
    "IEREMIA": "Ieremia",
    "PLÂNGERILE PROROCULUI IEREMIA": "Plângerile",
    "IEZECHIIL": "Iezechiil",
    "PROROCIA LUI DANIIL": "Daniil",
    "PROROCIA LUI OSIE": "Osie",
    "PROROCIA LUI IOIL": "Ioil",
    "PROROCIA LUI AMOS": "Amos",
    "PROROCIA LUI AVDIE": "Avdie",
    "PROROCIA LUI IONÀ": "Iona",
    "PROROCIA LUI MIHEEA": "Miheea",
    "PROROCIA LUI NAUM": "Naum",
    "PROROCIA LUI AVACUM": "Avacum",
    "PROROCIA LUI SOFONIE": "Sofonie",
    "PROROCIA LUI AGHEU": "Agheu",
    "PROROCIA LUI ZAHARIA": "Zaharia",
    "PROROCIA LUI MALAHIA": "Malahia",
    # Deuterocanonical
    "CARTEA LUI TOVIT": "Tovit",
    "CARTEA IUDITEI": "Iudita",
    "PROROCIA LUI VARUH": "Varuh",
    "CARTEA A TREIA A LUI ESDRA": "3 Esdra",
    "CARTEA ÎNȚELEPCIUNEI LUI SOLOMON": "Înțelepciunea lui Solomon",
    "CARTEA ÎNȚELEPCIUNEI LUI ISUS FIUL LUI SIRAH": "Isus Sirah",
    "ISTORIA SUSANEI": "Susana",
    "CARTEA ÎNTÂI A MACAVEILOR": "1 Macavei",
    "CARTEA A DOUA A MACAVEILOR": "2 Macavei",
    "CARTEA A TREIA A MACAVEILOR": "3 Macavei",
    # New Testament
    "SFÂNTA EVANGHELIE DE LA MATEI": "Matei",
    "SFÂNTA EVANGHELIE DE LA MARCU": "Marcu",
    "SFÂNTA EVANGHELIE DE LA LUCA": "Luca",
    "SFÂNTA EVANGHELIE DE LA IOAN": "Ioan",
    "FAPTELE SFINȚILOR APOSTOLI": "Faptele Apostolilor",
    "EPISTOLIA SFÂNTULUI APOSTOL PAVEL CEA CĂTRE ROMANI": "Romani",
    "EPISTOLIA SFÂNTULUI APOSTOL PAVEL ÎNTÂIA CĂTRE CORINTENI": "1 Corinteni",
    "EPISTOLIA SFÂNTULUI APOSTOL PAVEL A DOUA CĂTRE CORINTENI": "2 Corinteni",
    "EPISTOLIA SFÂNTULUI APOSTOL PAVEL CĂTRE GALATENI": "Galateni",
    "EPISTOLIA SFÂNTULUI APOSTOL PAVEL CĂTRE EFESENI": "Efeseni",
    "EPISTOLIA SFÂNTULUI APOSTOL PAVEL CĂTRE FILIPPISENI": "Filipeni",
    "EPISTOLIA SFÂNTULUI APOSTOL PAVEL CĂTRE COLASENI": "Coloseni",
    "EPISTOLIA SFÂNTULUI APOSTOL PAVEL ÎNTÂIA CĂTRE TESALONICHENI": "1 Tesaloniceni",
    "EPISTOLIA SFÂNTULUI APOSTOL PAVEL A DOUA CĂTRE TESALONICHENI": "2 Tesaloniceni",
    "EPISTOLIA SFÂNTULUI APOSTOL PAVEL ÎNTÂIA CĂTRE TIMOTEI": "1 Timotei",
    "EPISTOLIA SFÂNTULUI APOSTOL PAVEL A DOUA CĂTRE TIMOTEI": "2 Timotei",
    "EPISTOLIA SFÂNTULUI APOSTOL PAVEL CĂTRE TIT": "Tit",
    "EPISTOLIA SFÂNTULUI APOSTOL PAVEL CĂTRE FILIMON": "Filimon",
    "EPISTOLIA SFÂNTULUI APOSTOL PAVEL CĂTRE EVREI": "Evrei",
    "EPISTOLIA SOBORNICEASCĂ A SFÂNTULUI APOSTOL IACOV": "Iacov",
    "EPISTOLIA SOBORNICEASCĂ ÎNTÂIA A SFÂNTULUI APOSTOL PETRU": "1 Petru",
    "EPISTOLIA SOBORNICEASCĂ A DOUA A SFÂNTULUI APOSTOL PETRU": "2 Petru",
    "EPISTOLIA SOBORNICEASCĂ ÎNTÂIA A SFÂNTULUI APOSTOL IOAN": "1 Ioan",
    "EPISTOLIA SOBORNICEASCĂ A DOUA A SFÂNTULUI APOSTOL IOAN": "2 Ioan",
    "EPISTOLIA SOBORNICEASCĂ A TREIA A SFÂNTULUI APOSTOL IOAN": "3 Ioan",
    "EPISTOLIA SOBORNICEASCĂ A SFÂNTULUI APOSTOL IUDA": "Iuda",
    "APOCALIPSIS A SFÂNTULUI IOAN TEOLOGUL": "Apocalipsa",
}

NEW_TESTAMENT_STARTS = "SFÂNTA EVANGHELIE DE LA MATEI"
DEUTEROCANONICAL_BOOKS = {
    "CARTEA LUI TOVIT", "CARTEA IUDITEI", "PROROCIA LUI VARUH",
    "CARTEA A TREIA A LUI ESDRA", "CARTEA ÎNȚELEPCIUNEI LUI SOLOMON",
    "CARTEA ÎNȚELEPCIUNEI LUI ISUS FIUL LUI SIRAH", "ISTORIA SUSANEI",
    "CARTEA ÎNTÂI A MACAVEILOR", "CARTEA A DOUA A MACAVEILOR",
    "CARTEA A TREIA A MACAVEILOR",
}

def is_cross_reference(line):
    """Check if a line is a cross-reference (e.g. 'Ioan 1, 1, 2; Evr. 1, 10')"""
    s = line.strip()
    if not s or len(s) > 150:
        return False
    # Not a verse start
    if re.match(r'^\d+\.\s', s):
        return False
    # Must contain a chapter,verse reference pattern: digit(s), digit(s)
    if not re.search(r'\d+,\s*\d+', s):
        return False
    # Short line with chapter,verse pattern is almost certainly a cross-reference
    if len(s) < 80:
        return True
    # For longer lines, check ratio of reference-like characters
    stripped = re.sub(r'[\d,;\.\-\s\(\)]', '', s)
    if len(stripped) < len(s) * 0.4:
        return True
    return False

def find_book_name(lines, cap_line_idx, known_titles):
    """Look backwards from a CAP. 1 line to find the book name."""
    for j in range(cap_line_idx - 1, max(cap_line_idx - 20, 0), -1):
        prev = lines[j].strip()
        if prev in known_titles:
            return prev
        # Check partial matches for multi-line titles
        for title in known_titles:
            if prev and len(prev) > 4 and (prev == title or prev in title):
                return title
    return None

def parse_bible(text):
    lines = text.split('\n')
    books = []
    current_book = None
    current_book_full = None
    current_chapter = None
    current_verse_num = 0
    current_verse_text = ""
    chapters = {}
    in_new_testament = False
    in_psalms = False
    known_titles = set(SHORT_NAMES.keys())

    def save_verse():
        nonlocal current_verse_text, current_verse_num
        if current_verse_text and current_chapter is not None and current_verse_num > 0:
            if current_chapter not in chapters:
                chapters[current_chapter] = []
            chapters[current_chapter].append({
                "verse": current_verse_num,
                "text": current_verse_text.strip()
            })
        current_verse_text = ""

    def save_book():
        nonlocal chapters
        if chapters and current_book:
            books.append({
                "name": current_book,
                "fullName": current_book_full,
                "testament": "new" if in_new_testament else (
                    "deuterocanonical" if current_book_full in DEUTEROCANONICAL_BOOKS else "old"),
                "chapters": chapters
            })
        chapters = {}

    i = 0
    while i < len(lines):
        line = lines[i].strip()

        # ---- PSALMS: special handling (PSALMUL N instead of CAP. N) ----
        psalm_match = re.match(r'^PSALMUL\s+(\d+)\.$', line) or re.match(r'^PSALMUL\s+(\d+)$', line)

        # Check for PSALTIREA header (Psalms book start)
        if "PSALTIREA PROROCULUI" in line:
            save_verse()
            save_book()
            current_book_full = "PSALTIREA PROROCULUI ȘI ÎMPĂRATULUI DAVID"
            current_book = "Psalmii"
            in_psalms = True
            current_chapter = None
            current_verse_num = 0
            current_verse_text = ""
            i += 1
            continue

        # Also match PSALMUL NECANONIC 151 (non-canonical)
        psalm_nc_match = re.match(r'^PSALMUL\s+NECANONIC\s+(\d+)', line)

        if (psalm_match or psalm_nc_match) and in_psalms:
            save_verse()
            m = psalm_match or psalm_nc_match
            current_chapter = int(m.group(1))
            current_verse_num = 0
            current_verse_text = ""
            # After PSALMUL N, collect verse 1 (same logic as CAP.)
            i += 1
            subtitle_skipped = False
            verse1_parts = []
            while i < len(lines):
                nxt = lines[i].strip()
                if not nxt:
                    i += 1
                    continue
                if re.match(r'^2\.\s', nxt) or re.match(r'^PSALMUL\s+\d+', nxt) or re.match(r'^CAP\.', nxt):
                    break
                # Also stop at book titles
                if nxt in known_titles:
                    break
                if is_cross_reference(nxt):
                    i += 1
                    continue
                if not subtitle_skipped and len(nxt) < 60:
                    subtitle_skipped = True
                    i += 1
                    continue
                verse1_parts.append(nxt)
                i += 1
            if verse1_parts:
                current_verse_num = 1
                current_verse_text = " ".join(verse1_parts)
            continue

        # Check if we're leaving Psalms (next book starts)
        if in_psalms and line in known_titles:
            in_psalms = False

        # ---- CHAPTER MARKER: CAP. N. ----
        cap_match = re.match(r'^CAP\.\s+(\d+)\.$', line)
        if cap_match:
            chapter_num = int(cap_match.group(1))

            save_verse()

            if chapter_num == 1:
                save_book()
                # Find book name
                found = find_book_name(lines, i, known_titles)
                if found:
                    current_book_full = found
                    current_book = SHORT_NAMES.get(found, found)
                    if found == NEW_TESTAMENT_STARTS:
                        in_new_testament = True
                elif current_book is None:
                    current_book_full = "FACEREA"
                    current_book = "Facerea"

            current_chapter = chapter_num
            current_verse_num = 0
            current_verse_text = ""

            # After CAP. N., collect lines until we find "2. " (verse 2).
            # The subtitle is the first short line. Everything else before "2."
            # (excluding cross-references) is verse 1.
            i += 1
            subtitle_skipped = False
            verse1_parts = []
            while i < len(lines):
                nxt = lines[i].strip()
                if not nxt:
                    i += 1
                    continue
                # Stop at verse 2, next chapter, psalm, or book title
                if re.match(r'^2\.\s', nxt) or re.match(r'^CAP\.', nxt) or re.match(r'^PSALMUL\s', nxt):
                    break
                if nxt in known_titles:
                    break
                if is_cross_reference(nxt):
                    i += 1
                    continue
                # First non-empty, non-ref line is the subtitle (if short and title-like)
                if not subtitle_skipped and len(nxt) < 80 and not re.search(r'[,;].*[,;]', nxt):
                    subtitle_skipped = True
                    i += 1
                    continue
                # Everything else is verse 1 text
                verse1_parts.append(nxt)
                i += 1

            if verse1_parts:
                current_verse_num = 1
                current_verse_text = " ".join(verse1_parts)
            continue

        # ---- VERSE START: N. text ----
        verse_match = re.match(r'^(\d+)\.\s+(.+)', line)
        if verse_match and current_chapter is not None:
            save_verse()
            current_verse_num = int(verse_match.group(1))
            current_verse_text = verse_match.group(2)
            i += 1
            continue

        # ---- CONTINUATION or CROSS-REFERENCE ----
        if line and current_verse_num > 0:
            if is_cross_reference(line):
                i += 1
                continue
            elif current_verse_text:
                current_verse_text += " " + line

        i += 1

    # Save final state
    save_verse()
    save_book()

    return books

# ---- MAIN ----
with open(INPUT_FILE, 'r', encoding='utf-8') as f:
    text = f.read()

books = parse_bible(text)

# Convert chapter keys to strings
for book in books:
    book["chapters"] = {str(k): v for k, v in book["chapters"].items()}
    book["chapterCount"] = len(book["chapters"])

# Build output
bible = {
    "name": "Biblia Ortodox\u0103 Sinodal\u0103",
    "edition": "Edi\u021bia Sf\u00e2ntului Sinod",
    "year": 1914,
    "language": "ro",
    "source": "https://archive.org/details/biblia-1914-v123",
    "license": "Public Domain",
    "books": books
}

total_verses = sum(len(v) for book in books for v in book["chapters"].values())
total_chapters = sum(book["chapterCount"] for book in books)

print(f"Books: {len(books)}")
print(f"Chapters: {total_chapters}")
print(f"Verses: {total_verses}")
print(f"\nBook list:")
for idx, book in enumerate(books):
    print(f"  {idx+1}. {book['name']} ({book['testament']}) - {book['chapterCount']} ch, {sum(len(v) for v in book['chapters'].values())} vs")

os.makedirs(os.path.dirname(OUTPUT_FILE), exist_ok=True)
with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
    json.dump(bible, f, ensure_ascii=False, indent=None, separators=(',', ':'))

fsize = os.path.getsize(OUTPUT_FILE)
print(f"\nJSON: {OUTPUT_FILE} ({fsize / 1024 / 1024:.1f} MB)")

# Tests
gen = books[0]
print(f"\n--- {gen['name']} 1:1 ---")
print(gen['chapters']['1'][0]['text'][:200])

# Find Psalms
for b in books:
    if b['name'] == 'Psalmii':
        print(f"\n--- Psalmii chapters: {b['chapterCount']} ---")
        print(f"--- Psalmii 1:1 ---")
        print(b['chapters']['1'][0]['text'][:200])
        print(f"--- Psalmii 23:1 ---")
        if '23' in b['chapters']:
            print(b['chapters']['23'][0]['text'][:200])
        print(f"--- Psalmii 150:1 ---")
        if '150' in b['chapters']:
            print(b['chapters']['150'][0]['text'][:200])
        else:
            print("MISSING!")
        break

# Find Estera
for b in books:
    if b['name'] == 'Estera':
        print(f"\n--- Estera 1:1 ---")
        print(b['chapters']['1'][0]['text'][:200])
        break

# Find Matthew
for b in books:
    if b['name'] == 'Matei':
        print(f"\n--- Matei 1:1 ---")
        print(b['chapters']['1'][0]['text'][:200])
        break

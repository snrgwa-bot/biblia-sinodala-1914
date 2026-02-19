# Biblia Sinodală 1914 — App Store Connect Submission Guide

> All fields filled and ready to copy-paste into App Store Connect.
> Bundle ID: `com.nexubible.BibliaRomana` | Version: 2.1 (Build 1)

---

## 1. APP INFORMATION (General Tab)

### Localizable Information

| Field | Value |
|-------|-------|
| **Name** | `Biblia Sinodală 1914` |
| **Subtitle** | `Biblia Ortodoxă cu AI și hartă` |

### General Information

| Field | Value |
|-------|-------|
| **Bundle ID** | `com.nexubible.BibliaRomana` |
| **SKU** | `BibliaRomana2024` |
| **Primary Language** | Romanian (ro) |
| **Primary Category** | Reference |
| **Secondary Category** | Books |
| **Content Rights** | Yes — contains third-party content (Bible text: Biblia Sinodală 1914, Public Domain via archive.org) — we have the rights to use it (public domain, no copyright restrictions) |
| **License Agreement** | Apple's Standard License Agreement |

### Age Ratings

| Question | Answer |
|----------|--------|
| Cartoon or Fantasy Violence | None |
| Realistic Violence | None |
| Sexual Content or Nudity | None |
| Profanity or Crude Humor | None |
| Alcohol, Tobacco, or Drug Use | None |
| Simulated Gambling | None |
| Horror/Fear Themes | None |
| Mature/Suggestive Themes | None |
| Unrestricted Web Access | No |
| Gambling and Contests | No |
| **Expected Rating** | **4+** |

### App Encryption

| Field | Value |
|-------|-------|
| **ITSAppUsesNonExemptEncryption** | `NO` — App only uses standard HTTPS (TLS) for Gemini API calls, which is exempt. Add this key to Info.plist before submission. |

---

## 2. iOS APP VERSION

### Previews and Screenshots

| Device | Required | Notes |
|--------|----------|-------|
| **iPhone 6.5"** | YES | 1284×2778px or 1242×2688px — need at least 3, ideally 6-10 |
| **iPad 12.9"** | YES (app supports iPad) | 2048×2732px |

**Recommended screenshots to capture (in order):**
1. Biblioteca — showing the list of all Bible books
2. Citire — a chapter open with highlighted verses and notes
3. Enciclopedie — encyclopedia list with category pills
4. Enciclopedie Detail — an entry with map and AI deep-dive
5. Vizualizare — progress/heatmap/timeline view
6. Asistent AI — dictionary or perspectives feature
7. Harta Biblică — map with pins
8. Setări — showing theme/font options

### Promotional Text (170 chars)

```
Biblia Ortodoxă Sinodală 1914 completă, cu asistent AI, enciclopedie biblică, hartă interactivă și cronologie. Începe cu 3 zile gratuit!
```
(139 characters)

### Description (4,000 chars)

```
Biblia Sinodală 1914 — cea mai completă aplicație pentru studiul Bibliei Ortodoxe Române, cu funcții inteligente și conținut bogat.

CITIRE COMPLETĂ
• Toate cele 76 de cărți ale Bibliei Ortodoxe Sinodală, ediția 1914
• Navigare rapidă pe cărți, capitole și versete
• Evidențieri color cu mai multe culori la alegere
• Note personale scrise de mână pe fiecare verset
• Partajare versete ca imagini frumoase

ENCICLOPEDIE BIBLICĂ
• Peste 100 de articole despre persoane, locuri, evenimente și concepte biblice
• Categorii: persoane, locuri, evenimente, concepte, obiecte
• Versete de referință cu navigare directă la textul biblic
• Legături între articole înrudite
• Aprofundare AI pentru detalii suplimentare

HARTĂ BIBLICĂ INTERACTIVĂ
• Localizare pe hartă a locurilor biblice importante
• Navigare de la hartă direct la versete relevante
• Vizualizare pe hartă statică ilustrată sau Apple Maps

VIZUALIZARE AVANSATĂ
• Progres de citire — vezi cât ai citit din fiecare carte
• Harta de căldură — descoperă zonele cele mai studiate
• Cronologie biblică — evenimente în ordine cronologică cu referințe navigabile
• Vizualizare adnotări — toate evidențierile și notele într-un singur loc

ASISTENT AI BIBLIC
• Dicționar biblic — definiții detaliate ale cuvintelor biblice
• Rezumate capitole — obține rezumatul rapid al oricărui capitol
• Perspective personaje — vezi evenimentele prin ochii personajelor biblice
• Explicații versete — înțelege sensul profund al fiecărui verset
• Căutare cuvinte în întreaga Biblie

PERSONALIZARE
• Trei teme: luminos, întunecat, sistem
• Dimensiuni de font ajustabile
• Fonturi: Serif, Sans-serif, Monospaced
• Interfață complet în limba română

SURSA TEXTULUI
Biblia Ortodoxă Sinodală, Ediția Sfântului Sinod, 1914 — text din domeniul public, preluat de pe archive.org.

ABONAMENT PREMIUM
Funcțiile AI și Vizualizarea avansată necesită un abonament opțional:
• Lunar: $4.99/lună
• Anual: $29.99/an (economisești 50%)
• 3 zile de încercare gratuită
Abonamentul se reînnoiește automat. Poți anula oricând din Setări > Apple ID > Abonamente.

Descarcă acum și descoperă Biblia într-un mod complet nou!
```
(1,807 characters)

### Keywords (100 chars)

```
biblia,ortodoxă,sinodală,1914,biblie,română,verset,enciclopedie,hartă,cronologie,dicționar,AI
```
(94 characters)

### URLs

| Field | Value |
|-------|-------|
| **Support URL** | `https://nexubible.com/support` *(create this page before submission)* |
| **Marketing URL** | `https://nexubible.com` *(optional, create if desired)* |

### Version Information

| Field | Value |
|-------|-------|
| **Version** | `2.1` |
| **Copyright** | `2026 Dumitru Bumbu` |

---

## 3. APP REVIEW INFORMATION

| Field | Value |
|-------|-------|
| **Sign-in Required** | No |
| **First Name** | `Dumitru` |
| **Last Name** | `Bumbu` |
| **Phone Number** | *(your phone number with country code)* |
| **Email** | *(your email address)* |

### Notes for App Review (copy-paste)

```
Biblia Sinodală 1914 is a Romanian Orthodox Bible study app. No login is required.

TESTING THE APP:
1. The app opens to the Library tab showing all 76 Bible books
2. Tap any book, then a chapter number to read Bible text
3. Long-press any verse to highlight it or add a note
4. The Encyclopedia tab shows biblical persons, places, and events
5. The Visualization tab shows reading progress and timeline

AI FEATURES (require subscription):
The AI features use the Google Gemini API. To test AI features:
- Go to Settings > enter a Gemini API key (get one free at ai.google.dev)
- Go to Settings > Developer section > enable "Premium activat (DEV)" toggle
- Now AI features are accessible: Dictionary, Summaries, Perspectives

SUBSCRIPTION:
The app offers optional auto-renewable subscriptions for AI and Visualization features:
- Monthly: $4.99/month with 3-day free trial
- Yearly: $29.99/year with 3-day free trial

BIBLE TEXT SOURCE:
The Bible text is from "Biblia Ortodoxă Sinodală, Ediția Sfântului Sinod, 1914" — a public domain text available at archive.org.
```

---

## 4. APP STORE VERSION RELEASE

| Field | Recommended |
|-------|-------------|
| **Release Option** | Manually release this version |

---

## 5. PRICING AND AVAILABILITY

| Field | Value |
|-------|-------|
| **App Price** | Free (with in-app subscriptions) |
| **Availability** | All countries/regions |
| **Tax Category** | App Store Software (default) |
| **Apple Silicon Mac** | Yes (enable) |
| **Apple Vision Pro** | No |
| **Distribution Method** | Public |

---

## 6. APP PRIVACY

### Privacy Policy URL

| Field | Value |
|-------|-------|
| **Privacy Policy URL** | `https://nexubible.com/privacy` *(create this page before submission — see template below)* |

### Data Collection Practices (Privacy Nutrition Label)

**Data the app collects:**

| Data Type | Collected? | Linked to User? | Used for Tracking? | Purpose |
|-----------|-----------|-----------------|-------------------|---------|
| Purchases (Purchase History) | YES | YES | NO | App Functionality (subscription status) |
| Usage Data (Product Interaction) | NO | — | — | — |
| Diagnostics | NO | — | — | — |
| Location | NO | — | — | — |
| Contact Info | NO | — | — | — |
| Identifiers | NO | — | — | — |
| Search History | NO | — | — | — |
| User Content (notes, highlights) | YES | NO | NO | App Functionality (stored locally on device only) |

**Summary:** The app collects minimal data. Notes and highlights are stored locally on the device. Purchase history is collected by Apple for subscription management. The Gemini API receives the text the user searches for (word definitions, summaries) but this is not linked to the user's identity.

**For the questionnaire, answer:**
- "Do you or your third-party partners collect data from this app?" → **Yes**
- Purchase History → Collected, Linked to User, App Functionality
- User Content → Collected, Not Linked to User, App Functionality
- All other categories → Not Collected

---

## 7. SUBSCRIPTIONS (Monetization)

### Subscription Group

| Field | Value |
|-------|-------|
| **Group Reference Name** | `AI Assistant` |
| **Localized Group Name** | `Asistent AI Biblic` |

### Subscription 1: Monthly

| Field | Value |
|-------|-------|
| **Reference Name** | `AI Monthly` |
| **Product ID** | `com.nexubible.BibliaRomana.ai.monthly` |
| **Duration** | 1 Month |
| **Price** | $4.99 (Tier 5) |
| **Display Name** | `AI Lunar` |
| **Description** | `Acces lunar la funcțiile AI și vizualizare` |
| **Introductory Offer** | Free Trial — 3 Days |
| **Screenshot** | Screenshot showing AI Assistant or Paywall |

### Subscription 2: Yearly

| Field | Value |
|-------|-------|
| **Reference Name** | `AI Yearly` |
| **Product ID** | `com.nexubible.BibliaRomana.ai.yearly` |
| **Duration** | 1 Year |
| **Price** | $29.99 (closest tier) |
| **Display Name** | `AI Anual` |
| **Description** | `Acces anual la funcțiile AI și vizualizare` |
| **Introductory Offer** | Free Trial — 3 Days |
| **Screenshot** | Screenshot showing AI Assistant or Paywall |

### Billing Grace Period

| Field | Value |
|-------|-------|
| **Grace Period** | 16 days (recommended) |

---

## 8. ACCESSIBILITY

| Feature | Supported? |
|---------|-----------|
| VoiceOver | Yes |
| Voice Control | Yes |
| Larger Text | Yes (app has font size settings) |
| Dark Interface | Yes (app has dark theme) |
| Differentiate Without Color | Partial (highlights use colors but also show color names) |
| Sufficient Contrast | Yes |
| Reduced Motion | Yes (SwiftUI default behavior) |
| Captions | N/A (no video/audio) |
| Audio Descriptions | N/A |

---

## 9. BEFORE SUBMISSION CHECKLIST

### Code Changes Needed

- [ ] Add to Info.plist: `ITSAppUsesNonExemptEncryption` = `NO`
- [ ] Remove `#if DEBUG` dev toggle before Release build (it's already conditional, will auto-remove)
- [ ] Set app icon: 1024×1024px PNG, no transparency
- [ ] Upload build via Xcode: Product > Archive > Distribute App > App Store Connect

### Pages to Create

- [ ] **Privacy Policy page** at `https://nexubible.com/privacy`
- [ ] **Support page** at `https://nexubible.com/support`

### App Store Connect Steps (in order)

1. [ ] Log in to [App Store Connect](https://appstoreconnect.apple.com)
2. [ ] Create new app: My Apps > "+" > New App
3. [ ] Fill in App Information (Section 1 above)
4. [ ] Complete Age Rating questionnaire
5. [ ] Set up Pricing (Free) and Availability
6. [ ] Create Subscription Group and both subscriptions (Section 7)
7. [ ] Complete Privacy questionnaire (Section 6)
8. [ ] Archive and upload build from Xcode
9. [ ] Fill in iOS Version page (description, keywords, screenshots)
10. [ ] Fill in App Review information (Section 3)
11. [ ] Add screenshots for subscriptions
12. [ ] Submit for Review

### Screenshots Needed

| Device | Count | Size |
|--------|-------|------|
| iPhone 6.5" | 6-10 | 1284×2778px |
| iPad 12.9" | 6-10 | 2048×2732px |

**Tip:** Run app on iPhone 15 Pro Max simulator and iPad Pro 12.9" simulator, then take screenshots with Cmd+S in Simulator.

---

## 10. PRIVACY POLICY TEMPLATE

Create a page at `https://nexubible.com/privacy` with this content:

```
Politica de Confidențialitate — Biblia Sinodală 1914

Ultima actualizare: Februarie 2026

Aplicația Biblia Sinodală 1914 ("Aplicația") este dezvoltată de Dumitru Bumbu ("noi").

DATE COLECTATE
• Notele și evidențierile dumneavoastră sunt stocate local pe dispozitiv și nu sunt transmise nicăieri.
• Funcțiile AI trimit textul căutat (cuvinte, versete) către Google Gemini API pentru procesare. Aceste date nu sunt stocate permanent de noi.
• Informațiile despre abonament sunt gestionate de Apple prin App Store și nu sunt accesibile nouă.

DATE PE CARE NU LE COLECTĂM
• Nu colectăm date de localizare
• Nu colectăm date de contact
• Nu colectăm identificatori personali
• Nu folosim cookie-uri sau instrumente de analiză
• Nu partajăm date cu terți în scopuri publicitare

SERVICII TERȚE
• Google Gemini API — pentru funcțiile de inteligență artificială. Consultați politica Google: https://policies.google.com/privacy
• Apple StoreKit — pentru gestionarea abonamentelor

SECURITATE
Toate comunicațiile cu serverele externe sunt criptate prin HTTPS/TLS.

COPII
Aplicația nu colectează intenționat date de la copii sub 13 ani.

MODIFICĂRI
Putem actualiza această politică periodic. Verificați această pagină pentru cea mai recentă versiune.

CONTACT
Pentru întrebări: [adresa ta de email]
```

---

## 11. SUPPORT PAGE TEMPLATE

Create a page at `https://nexubible.com/support` with:

```
Suport — Biblia Sinodală 1914

Aveți întrebări sau probleme? Contactați-ne:
Email: [adresa ta de email]

ÎNTREBĂRI FRECVENTE

Î: Cum activez funcțiile AI?
R: Mergeți la Setări > introduceți cheia API Gemini (obțineți una gratuită de pe ai.google.dev), apoi abonați-vă la planul Premium.

Î: Cum anulez abonamentul?
R: Mergeți la Setări iPhone > Apple ID > Abonamente > Biblia Sinodală > Anulează.

Î: Datele mele sunt stocate în cloud?
R: Nu. Notele și evidențierile sunt stocate doar pe dispozitivul dumneavoastră.

Î: Pot folosi aplicația offline?
R: Da. Textul Bibliei și enciclopedia funcționează offline. Doar funcțiile AI necesită conexiune la internet.

Î: Ce ediție a Bibliei este folosită?
R: Biblia Ortodoxă Sinodală, Ediția Sfântului Sinod, 1914 — text din domeniul public.
```

---

*Document generat pentru Biblia Sinodală 1914 v2.1 — Februarie 2026*

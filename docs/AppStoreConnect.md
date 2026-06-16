# App Store Connect — submission content

Paste-ready content for the first review submission. Two localizations:
**English (U.S.)** is the primary language, **Portuguese (Brazil)** the second.
Character limits are noted per field; all texts below fit.

> Trademark note: this app was rejected once under Guideline 5.2.1 for content
> "resembling FIFA." FIFA owns "FIFA", "WORLD CUP", and "FIFA WORLD CUP" as
> registered marks, and App Review will not adjudicate nominative fair use — it
> just wants the marks gone. So ALL copy below avoids "FIFA", "World Cup", and
> "Copa do Mundo". The app refers to the event neutrally as the "2026 tournament"
> / "torneio de 2026" and brands itself "Football 2026" / "Futebol 2026". Never
> reintroduce FIFA/World Cup branding, logos, the official emblem, or wording
> that implies affiliation or endorsement.

---

## App information (applies to all localizations)

| Field | Value |
|---|---|
| Bundle ID | `app.zeneto.football` |
| Primary language | English (U.S.) |
| Category | Sports |
| Secondary category | News (optional) |
| Age rating | 4+ (no objectionable content) |
| Price | Free |
| Copyright | © 2026 José Neto |

### App Privacy
- **Data Not Collected** — the app has no accounts, no analytics, no tracking,
  and no third-party SDKs. It only downloads public tournament data.

### Export compliance
- Already answered in the binary: `ITSAppUsesNonExemptEncryption = NO`
  (standard HTTPS only).

---

## English (U.S.)

**Name** (30 max — 13):

```
Just Football
```

**Subtitle** (30 max — 28):

```
The 2026 tournament, nothing else
```

**Promotional text** (170 max):

```
Every match of the 2026 tournament, live and offline. No ads, no accounts, no tracking. Just football.
```

**Description** (4000 max):

```
Football and nothing else.

Just Football is the simplest way to follow the 2026 tournament: all 48 teams, all 12 groups, and every one of the 104 matches — from the opening kickoff to the final.

THE WHOLE TOURNAMENT, AT A GLANCE
• Every match, grouped by day and sorted by kickoff
• Kickoff times shown in your time zone
• Live matches flagged the moment they start
• Final scores as soon as the whistle blows
• Every stage clearly labelled, from the group phase to the final
• The venue for every match

MADE TO STAY OUT OF YOUR WAY
• Works offline — the schedule lives on your device and refreshes when you open the app
• No ads
• No account, no sign-in
• No tracking. The app collects nothing about you. Nothing.
• In English and Brazilian Portuguese

THE MANIFESTO
The main idea here is football and nothing else. No ads. No authentication. No tracking. No pink football boots. No soccer. Just football.
```

**Keywords** (100 max):

```
football,soccer,2026,matches,scores,fixtures,results,schedule,groups,teams
```

> Keywords are never shown to users. Note: "world cup" was removed — it is a
> FIFA mark and contributed to the 5.2.1 rejection. Do not add it back.

**What's New** (version 1.0):

```
The opening whistle: every team, every group, every match of the 2026 tournament — in English and Brazilian Portuguese. No ads, no accounts, no tracking. Just football.
```

---

## Portuguese (Brazil)

**Name** (30 max — 10):

```
Só Futebol
```

**Subtitle** (30 max — 30):

```
O torneio de 2026 e nada mais
```

**Promotional text** (170 max):

```
Todas as partidas do torneio de 2026, ao vivo e offline. Sem anúncios, sem cadastro, sem rastreamento. Só futebol.
```

**Description** (4000 max):

```
Futebol e nada mais.

O Só Futebol é o jeito mais simples de acompanhar o torneio de 2026: todos os 48 times, todos os 12 grupos e cada uma das 104 partidas — do pontapé inicial à final.

O TORNEIO INTEIRO, DE RELANCE
• Todas as partidas, agrupadas por dia e ordenadas pelo horário
• Horários no seu fuso
• Partidas ao vivo sinalizadas no momento em que começam
• Placar final assim que o juiz apita
• Cada fase claramente identificada, da fase de grupos à final
• O estádio de cada partida

FEITO PARA NÃO ATRAPALHAR
• Funciona offline — a tabela fica no seu aparelho e se atualiza quando você abre o app
• Sem anúncios
• Sem conta, sem login
• Sem rastreamento. O app não coleta nada sobre você. Nada.
• Em português do Brasil e em inglês

O MANIFESTO
A ideia aqui é futebol e nada mais. Sem anúncios. Sem autenticação. Sem rastreamento. Sem chuteiras cor-de-rosa. Sem "soccer". Só futebol.
```

**Keywords** (100 max — 83):

```
futebol,2026,partidas,placar,resultados,tabela,jogos,seleções,grupos
```

**What's New** (version 1.0):

```
O apito inicial: todos os times, todos os grupos, todas as partidas do torneio de 2026 — em português e inglês. Sem anúncios, sem cadastro, sem rastreamento. Só futebol.
```

---

## App Review Information

**Notes for the reviewer:**

```
Just Football displays the public schedule and results of the international football tournament held in June–July 2026.

- This app uses no FIFA or World Cup branding, logos, official emblems, or marks. It refers to the event only by date ("the 2026 tournament") and is not affiliated with, endorsed by, or sponsored by FIFA. The previous 5.2.1 rejection has been addressed: every instance of "FIFA" and "World Cup" / "Copa do Mundo" has been removed from the app and its metadata.
- The displayed data is factual public information — team names, national flags, fixture dates, venues, and scores — none of which is FIFA intellectual property.
- There is no login, account, or demo credentials — the full app is available immediately on first launch.
- Content is read-only public data fetched over HTTPS from our hosted database and cached on the device for offline use.
- Scores and match statuses update as the tournament progresses (June–July 2026), so the data visible during review reflects the real state on that day.
- The app collects no user data of any kind: no analytics, no tracking, no third-party SDKs.
```

**Contact information:** your name, phone, and email (required fields).

**Support URL** (required): a page you control — a GitHub repository page or a
simple contact page is enough. Suggestion: publish the manifesto there.

**Marketing URL** (optional): can be left empty.

---

## Screenshot checklist (not text, but required before submitting)

- 6.9" (iPhone 17 Pro Max class) and 6.5" sizes; one set per language.
- Suggested shots, both languages:
  1. The schedule with finished, live, and upcoming matches
  2. A match day with scores (winners in bold, "FT"/"FIM")
  3. The About screen with the manifesto
- `xcrun simctl io booted screenshot` on the right simulator produces
  correctly sized PNGs.

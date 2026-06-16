# Just Football ⚽

**The 2026 tournament, nothing else.**

The simplest way to follow the 2026 international football tournament on iOS: all 48 teams, all 12 groups, and every one of the 104 matches — from the opening kickoff to the final.

No ads. No accounts. No tracking. Just football.

| Schedule | About | Dark mode |
|---|---|---|
| ![Schedule](docs/screenshots/en/iphone/01-schedule.png) | ![About](docs/screenshots/en/iphone/02-about.png) | ![Dark mode](docs/screenshots/en/iphone/03-schedule-dark.png) |

## Features

- Every match, grouped by day and sorted by kickoff
- Kickoff times shown in your time zone
- Live matches flagged the moment they start, with the running match clock, and final scores as soon as the whistle blows
- Live scores and goals refresh on their own while a match is in play — no need to pull
- Tap any match for its goal-by-goal timeline: scorer, minute, and penalty/own-goal markers
- Every stage clearly labelled, from the group phase to the final, with venues
- Works offline — the schedule lives on your device and refreshes when you open the app
- Localized in English and Brazilian Portuguese

## The manifesto

The main idea here is football and nothing else. No ads. No authentication. No tracking. No pink football boots. No soccer. Just football.

## Architecture

A SwiftUI + MVVM app, with all logic split into four local Swift packages under `Packages/`. The app target holds only views, view models, and glue.

```
football/            App target — Views, ViewModels, Support
Packages/
├── FootballCore     Domain models (Team, Match, Goal, Stage, ContentLocale)
├── FootballAPI      Airtable REST client
├── FootballStorage  SwiftData local cache (FootballStore model actor)
└── FootballManager  Sync & service layer tying API and storage together
```

Data flows one way: `FootballAPI` fetches public tournament data over HTTPS, `FootballManager` syncs it into `FootballStorage`, and the UI reads from the local store — which is why the app works offline.

UI strings are localized with String Catalogs (en, pt-BR); match and team names come localized from the data source, falling back to English.

## Building

Requires Xcode with the iOS 26 SDK.

1. Clone the repo and open `football.xcodeproj`.
2. The app reads its data from an Airtable base with three tables, `Teams`, `Matches`, and `Goals`. Credentials are kept out of git:

   ```sh
   cp football/Support/Secrets.swift.sample football/Support/Secrets.swift
   ```

   Then fill in your Airtable base ID and a personal access token with the read-only `data.records:read` scope.
3. Build and run. Without credentials the project still compiles, and SwiftUI previews work against bundled sample data (`PreviewFootballService`).

## Tests

The packages carry their own test suites:

```sh
swift test --package-path Packages/FootballAPI
swift test --package-path Packages/FootballStorage
```

## Privacy

The app collects nothing. No analytics, no tracking, no third-party SDKs — it only downloads public tournament data and caches it on the device.

## Support

Questions or problems? See the [support page](https://joselinoneto.github.io/football/) or open an issue.

---

*"Just Football" is an independent app. It tracks the public schedule and results of the 2026 international football tournament and is not affiliated with, endorsed by, or sponsored by FIFA. It uses no FIFA or World Cup branding, logos, or marks.*

© 2026 José Neto

# Changelog

All notable user-facing changes to **Just Football**. Newest first.

---

## 1.4

The tournament reaches its finish — a champion to crown, and every team's road to it.

### ✨ What's new

- **Champions.** Once the final is played, a new golden **Champions** screen crowns
  the winner — with the final result and the goals that decided it. Tap the champion
  to jump straight to their squad.
  - A **Champions** banner appears at the top of the **Final** round in the Matches
    tab, so the winner is one tap away. Nothing shows until the trophy is lifted.
- **Every team's results.** Each team page now lists all of its matches, from the
  group stage through the knockouts, with a **Win / Draw / Loss** marker and the
  score (shootout results included). Tap any game to open its full detail.

### 🧪 What to test (beta)

- With the final decided, open **Matches → Final** and confirm the **Champions**
  banner appears; tap it and check the trophy screen shows the final result, the
  goal highlights, and that tapping the champion opens their squad.
- Open a few team pages (e.g. from a match's team name) and confirm the **Matches**
  list shows every game, correct W/D/L badges, and that each row opens the match.
- Verify everything in both English and Brazilian Portuguese, light and dark.

### 🔧 Under the hood

- The Champions screen and each team's results read the same live-updating data as
  the schedule, so scores stay current while the screen is open.

---

## 1.3

The knockout stage, a team you call your own, and a roomier layout.

### ✨ What's new

- **Knockout bracket.** The new **Matches** tab lays out every knockout round, from
  the round of 32 through to the final, and fills in as teams advance.
  - Ties settled in extra time or on penalties are marked as such — **"After extra
    time" / "After penalties"** — with the shootout score shown alongside the result.
- **Pick a favorite team.** In **Settings**, choose a team and the app takes on its
  flag's color as the accent — across the app, the Home Screen widget, and the Live
  Activity. Change it any time, or go back to the default pitch green.
- **A tab for everything.** The app is now organized into four tabs:
  - **Home** — the day-by-day schedule.
  - **Matches** — the knockout bracket.
  - **Group Stage** — the group tables.
  - **Settings** — your favorite team and the About page.
- **Roomier schedule.** The Home schedule was rebuilt as a cleaner, Home-style
  list that's easier to scan.

### 🧪 What to test (beta)

- Open the **Matches** tab and scroll the knockout rounds; confirm decided ties show
  "After extra time"/"After penalties" and the shootout score.
- In **Settings → Favorite team**, pick a team and confirm the accent color changes
  everywhere — app, widget, and any Live Activity — and that clearing it returns to
  green.
- Switch between all four tabs and confirm each loads its content.
- Verify everything in both English and Brazilian Portuguese, light and dark.

### 🔧 Under the hood

- The group standings load once instead of on every refresh.
- The Watch app and widget now show the same penalty/extra-time result notes as the
  phone.

---

## 1.2 (build 3)

Home Screen widgets, Live Activities, and a refreshed schedule.

### ✨ What's new

- **Home Screen widgets** in three sizes.
  - **Small** — follows the one match that matters right now: the live game, or
    the next one up, rolling forward on its own instead of getting stuck on the
    day's first fixture. The header switches from "Today" to the match's weekday
    as it moves ahead.
  - **Medium & large** — today's fixtures at a glance. Pick a team to follow and
    they switch to that team's story: its last 3 results followed by its upcoming
    games.
  - Group-stage matches now show the group letter (e.g. "Group A").
- **Live Activities** on the Lock Screen and in the Dynamic Island for a match in
  play, with the live score and match clock.
  - The compact Dynamic Island now shows both teams — flag and score on each side.
  - Only ever one activity per match: updates land in place instead of stacking
    new cards on the Lock Screen over time.
- **Tap to open** — tapping a widget or a Live Activity jumps straight to that
  match's detail in the app.
- **Background refresh** — widgets and Live Activities keep their scores current
  even while the app is closed.
- **Refreshed schedule**
  - Live matches float to the top so what's on now is the first thing you see.
  - Completed days are ordered latest-first; today stays pinned to the top, with
    upcoming days after.
  - New **Liquid Glass** section switcher (Matches / Standings) and filter chips.

### 🧪 What to test (beta)

- Add each widget size (small, medium, large) to the Home Screen and confirm
  today's matches render with flags, codes, and scores.
- Leave the small widget over a day with several games and confirm it advances to
  the live/next match rather than staying on the first kickoff.
- Long-press a widget → **Edit Widget** → pick a team, and confirm the medium and
  large widgets show that team's recent results then upcoming fixtures.
- During a live match, confirm the Lock Screen / Dynamic Island Live Activity
  updates the score and clock — and that it does **not** spawn duplicate cards
  after locking/unlocking or over a long session.
- Check the Dynamic Island compact view shows both flags with their scores.
- Tap a widget and a Live Activity and confirm each opens the right match detail.
- In the schedule, confirm live games sit at the top and completed days read
  latest-first.
- Verify everything in both English and Brazilian Portuguese, light and dark.

### 🔧 Under the hood

- The widget reads the app's data through a shared App Group and does its own
  lightweight Teams/Matches refresh on its timeline.
- Brand colors (pitch green, live red) are shared across the app, Watch app,
  widget, and Live Activity so the look is identical everywhere.

---

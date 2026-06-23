# Changelog

All notable user-facing changes to **Just Football**. Newest first.

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

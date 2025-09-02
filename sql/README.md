# SQL index

Each file is either a **single self-contained query** or a **small set of related queries**.  
Scope: NCAA D-I men (2014–2017), regular season only; no neutrals; team-season ≥ 8H & ≥ 8A.

## File descriptions (brief)
- `00_setup.sql` – schema/dictionary checks + filtered games view (no tournaments/neutral).
- `10_season.sql` – season pace and σ (spread) of final margins.
- `20_team.sql` – team HRE & shooting lifts (detail → summary).
- `30_channels.sql` – fouls, free-throw rate, turnovers, rebounds, shooting.
- `40_pace.sql` – home–road tempo edge.
- `42_conference_only.sql` – within-conference sensitivity.
- `44_pairs.sql` – paired home/away swaps.
- `46_rules_bundle.sql` – scoring/pace around the rule reset.
- `47_close_games.sql` – close-game shares (≤5, ≤10, ≤20).
- `48_calibration.sql` – points → win-probability rough factors.
- `49_conference_rollup.sql` – conference/tier rollups.
- `50_channels_rollup.sql` – channel rollups (wide/long).
- `52_tiers_power6.sql` – tier + Power Six splits.

**Notes:** `pp` = percentage points; “venue effect” ≈ HRE ÷ 2.

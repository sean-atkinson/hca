# Observational Notes (summary)

**Scope & data**
- NCAA D-I men, 2014–2017 regular season. No tournaments or neutral sites.
- Canonical view: `09_games_core_filtered_view.sql` (season label mapping, filters).

**Key decisions**
- Treat pre-2016 `neutral_site` NULLs as non-neutral (sensitivity in 29a/29b: ~0.4–0.5 pts shift).
- Team-season normalization (≥8 home & ≥8 road).  
- Report **HRE** (home margin − road margin); venue effect ≈ HRE ÷ 2.
- Language: “coincides with,” not causal.

**Sanity checks**
- Tournament flags stable (~430/season): `03_tournament_games_counts.sql`.
- Box score audit (points vs components): `35_boxscore_points_sanity.sql` (tiny diffs only).
- Pace calc uses NCAA 0.475×FTA: `41_pace_team_lift_summary.sql`.

**What moved**
- Pace ↑ in 2015–16 and again 2016–17: `46_rule_bundle_scoring_pace_check.sql`.
- σ of final margins ↓ (fewer blowouts): `11_stddev_final_margin.sql`.
- HRE fell ~3–4 pts by 2016–17: `20d_team_lift_summary.sql`, `45_paired_swaps_summary.sql`.

**What didn’t**
- Fouls & FT rate: stable lifts (`31_`, `32_`).
- Shooting lifts: ~+3–4pp on 2P, ~+1pp on 3P, steady (`33_`).
- TO & REB gaps: steady (`36–40_`).

**Tier split (Power Six vs others)**
- Power Six ticked up slightly; decline driven by Mid-Majors & Other D-I: `52_*`, `49_*`.

**Interpretation (nowcast)**
- Faster, tighter environment; away scoring closed the gap. Classic “home” levers stayed flat.
- We treat this as **operational signal**, not proof of causation.

**Next checks (if extending)**
- Validate: possession-weighted HRE, month splits, venue size/attendance, travel/altitude.
- Hunt drivers: shot profile (early-clock 3s, rim vs mid), possession starts (live/dead), stoppage time.
- Ground truth: small film sample across tiers.

**Version notes**
- Slides: `/presentation/case_study_v7.pdf`
- SQL index: see `/sql/README.md` (or top-level README query map).

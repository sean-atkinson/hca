-- 30_boxcore_core_filtered_view.sql
-- Purpose:
--   Box-score layer for channel analysis (FG/2P/3P/FT, fouls),
--   with normalized percentage fields to handle 0–1 vs 0–100 scale differences.
-- Source:
--   bigquery-public-data.ncaa_basketball.mbb_games_sr
-- Filters:
--   Seasons 2014–2016, exclude tournaments & neutrals (NULL neutrals treated as non-neutral).

CREATE OR REPLACE VIEW `hca-2016-analysis.hca2016.v_games_core_box` AS
SELECT
  season,
  CASE
    WHEN season = 2014 THEN '2014–15'
    WHEN season = 2015 THEN '2015–16'
    WHEN season = 2016 THEN '2016–17'
    ELSE CAST(season AS STRING)
  END AS season_label,

  -- Team identifiers / labels
  CAST(h_id AS STRING) AS h_team_id,
  CAST(a_id AS STRING) AS a_team_id,
  h_name               AS h_team_name,
  a_name               AS a_team_name,

  -- Conference names
  h_conf_name,
  a_conf_name,

  -- Points
  h_points             AS h_pts,
  a_points             AS a_pts,

  -- Field goals (raw + %)
  h_field_goals_made   AS h_fgm,
  h_field_goals_att    AS h_fga,
  h_field_goals_pct    AS h_fg_pct,
  a_field_goals_made   AS a_fgm,
  a_field_goals_att    AS a_fga,
  a_field_goals_pct    AS a_fg_pct,

  -- 2-point field goals (raw + %)
  h_two_points_made    AS h_2pm,
  h_two_points_att     AS h_2pa,
  h_two_points_pct     AS h_2p_pct,
  a_two_points_made    AS a_2pm,
  a_two_points_att     AS a_2pa,
  a_two_points_pct     AS a_2p_pct,

  -- 3-point field goals (raw + %)
  h_three_points_made  AS h_3pm,
  h_three_points_att   AS h_3pa,
  h_three_points_pct   AS h_3p_pct,
  a_three_points_made  AS a_3pm,
  a_three_points_att   AS a_3pa,
  a_three_points_pct   AS a_3p_pct,

  -- Free throws (raw + %)
  h_free_throws_made   AS h_ftm,
  h_free_throws_att    AS h_fta,
  h_free_throws_pct    AS h_ft_pct,
  a_free_throws_made   AS a_ftm,
  a_free_throws_att    AS a_fta,
  a_free_throws_pct    AS a_ft_pct,

  -- Fouls
  h_personal_fouls     AS h_pf,
  a_personal_fouls     AS a_pf,

  -- Turnovers
  h_turnovers,
  a_turnovers,

  -- Team rebounds
  h_team_rebounds,
  a_team_rebounds,
  h_offensive_rebounds,
  a_offensive_rebounds, 

  -- ---------- Normalized percentage fields (0–1 scale) ----------
  -- FG%
  CASE WHEN h_field_goals_pct    > 1 THEN h_field_goals_pct    / 100 ELSE h_field_goals_pct    END AS h_fg_pct_norm,
  CASE WHEN a_field_goals_pct    > 1 THEN a_field_goals_pct    / 100 ELSE a_field_goals_pct    END AS a_fg_pct_norm,
  -- 2P%
  CASE WHEN h_two_points_pct     > 1 THEN h_two_points_pct     / 100 ELSE h_two_points_pct     END AS h_2p_pct_norm,
  CASE WHEN a_two_points_pct     > 1 THEN a_two_points_pct     / 100 ELSE a_two_points_pct     END AS a_2p_pct_norm,
  -- 3P%
  CASE WHEN h_three_points_pct   > 1 THEN h_three_points_pct   / 100 ELSE h_three_points_pct   END AS h_3p_pct_norm,
  CASE WHEN a_three_points_pct   > 1 THEN a_three_points_pct   / 100 ELSE a_three_points_pct   END AS a_3p_pct_norm,
  -- FT%
  CASE WHEN h_free_throws_pct    > 1 THEN h_free_throws_pct    / 100 ELSE h_free_throws_pct    END AS h_ft_pct_norm,
  CASE WHEN a_free_throws_pct    > 1 THEN a_free_throws_pct    / 100 ELSE a_free_throws_pct    END AS a_ft_pct_norm

FROM
  `bigquery-public-data.ncaa_basketball.mbb_games_sr`
WHERE
  season IN (2014, 2015, 2016)
  AND IFNULL(neutral_site, FALSE) = FALSE
  AND NOT (
    tournament IS NOT NULL OR tournament_type IS NOT NULL
    OR tournament_round IS NOT NULL OR tournament_game_no IS NOT NULL
  );


-- 31_ft_rate_team_lift.sql
-- Purpose:
--   Team-season normalized FREE-THROW access & accuracy gaps (home − road), by season.
--   • FT RATE lift (correct):   SUM(FTA) / SUM(FGA)  → access to the line
--   • FT% lift (correct):       SUM(FTM) / SUM(FTA)  → shooting accuracy
--   • FT% lift (naïve):         AVG(per-game FT%)    → shown only to illustrate bias
--   Guard: keep team-seasons with ≥8 home AND ≥8 road games.

CREATE OR REPLACE TABLE `hca-2016-analysis.hca2016.ft_rate_team_lift_summary` AS
WITH home_team AS (
  SELECT
    season_label,
    h_team_id AS team_id,
    COUNT(*) AS n_home,
    SAFE_DIVIDE(SUM(h_fta), NULLIF(SUM(h_fga), 0)) AS ft_rate_home,   -- FTA/FGA
    SAFE_DIVIDE(SUM(h_ftm), NULLIF(SUM(h_fta), 0)) AS ft_pct_home,    -- FTM/FTA
    AVG(h_ft_pct) AS ft_pct_home_naive
  FROM
    `hca-2016-analysis.hca2016.v_games_core_box`
  GROUP BY
    season_label,
    team_id
),
away_team AS (
  SELECT
    season_label,
    a_team_id AS team_id,
    COUNT(*) AS n_away,
    SAFE_DIVIDE(SUM(a_fta), NULLIF(SUM(a_fga), 0)) AS ft_rate_away,
    SAFE_DIVIDE(SUM(a_ftm), NULLIF(SUM(a_fta), 0)) AS ft_pct_away,
    AVG(a_ft_pct) AS ft_pct_away_naive
  FROM
    `hca-2016-analysis.hca2016.v_games_core_box`
  GROUP BY
    season_label,
    team_id
),
team_lift AS (
  SELECT
    h.season_label,
    h.team_id,
    h.n_home,
    a.n_away,
    (h.ft_rate_home - a.ft_rate_away) AS ft_rate_lift,
    (h.ft_pct_home - a.ft_pct_away) AS ft_pct_lift_totals,
    (h.ft_pct_home_naive - a.ft_pct_away_naive) AS ft_pct_lift_naive
  FROM
    home_team AS h
    JOIN away_team AS a USING (season_label, team_id)
  WHERE
    h.n_home >= 8
    AND a.n_away >= 8
)
SELECT
  season_label,
  ROUND(AVG(ft_rate_lift), 4) AS mean_ft_rate_lift,
  ROUND(AVG(ft_pct_lift_totals), 4) AS mean_ft_pct_lift_totals,
  ROUND(AVG(ft_pct_lift_naive), 4) AS mean_ft_pct_lift_naive,
  COUNT(*) AS team_seasons_kept,
  ROUND(AVG(n_home), 1) AS avg_home_games_kept,
  ROUND(AVG(n_away), 1) AS avg_away_games_kept
FROM
  team_lift
GROUP BY
  season_label
ORDER BY
  season_label;


-- 32_fouls_team_lift.sql
-- Purpose:
--   Team-season normalized FOULS gap (home − road), by season.
--   Negative values mean teams commit fewer fouls at home (classic home edge).
--   Guard: ≥8 home AND ≥8 road games.

CREATE OR REPLACE TABLE `hca-2016-analysis.hca2016.fouls_team_lift_summary` AS
WITH home_team AS (
  SELECT
    season_label,
    h_team_id AS team_id,
    COUNT(*) AS n_home,
    AVG(h_pf) AS fouls_per_game_home
  FROM
    `hca-2016-analysis.hca2016.v_games_core_box`
  GROUP BY
    season_label,
    team_id
),
away_team AS (
  SELECT
    season_label,
    a_team_id AS team_id,
    COUNT(*) AS n_away,
    AVG(a_pf) AS fouls_per_game_away
  FROM
    `hca-2016-analysis.hca2016.v_games_core_box`
  GROUP BY
    season_label,
    team_id
),
team_lift AS (
  SELECT
    h.season_label,
    h.team_id,
    h.n_home,
    a.n_away,
    (h.fouls_per_game_home - a.fouls_per_game_away) AS fouls_gap_home_minus_road
  FROM
    home_team AS h
    JOIN away_team AS a USING (season_label, team_id)
  WHERE
    h.n_home >= 8
    AND a.n_away >= 8
)
SELECT
  season_label,
  ROUND(AVG(fouls_gap_home_minus_road), 2) AS mean_fouls_gap,  -- < 0 → fewer fouls at home
  COUNT(*) AS team_seasons_kept,
  ROUND(AVG(n_home), 1) AS avg_home_games_kept,
  ROUND(AVG(n_away), 1) AS avg_away_games_kept
FROM
  team_lift
GROUP BY
  season_label
ORDER BY
  season_label;


-- 33_shooting_team_lift.sql
-- -- Purpose:
--   Team-season shooting lifts (home − away) for FG%, 2P%, 3P%.
--   Uses normalized % fields (0–1) in v_games_core_box to avoid scale issues.

CREATE OR REPLACE TABLE `hca-2016-analysis.hca2016.shooting_team_lift` AS
WITH home AS (
  SELECT
    season_label,
    CAST(h_team_id AS STRING) AS team_id,
    h_team_name               AS team_name,
    AVG(h_fg_pct_norm)        AS avg_home_fg_pct,
    AVG(h_2p_pct_norm)        AS avg_home_2p_pct,
    AVG(h_3p_pct_norm)        AS avg_home_3p_pct,
    COUNT(*)                  AS n_home_games
  FROM
    `hca-2016-analysis.hca2016.v_games_core_box`
  GROUP BY
    season_label, team_id, team_name
),
away AS (
  SELECT
    season_label,
    CAST(a_team_id AS STRING) AS team_id,
    a_team_name               AS team_name,
    AVG(a_fg_pct_norm)        AS avg_away_fg_pct,
    AVG(a_2p_pct_norm)        AS avg_away_2p_pct,
    AVG(a_3p_pct_norm)        AS avg_away_3p_pct,
    COUNT(*)                  AS n_away_games
  FROM
    `hca-2016-analysis.hca2016.v_games_core_box`
  GROUP BY
    season_label, team_id, team_name
),
home_and_away AS (
  SELECT
    h.season_label,
    h.team_id,
    h.team_name,
    h.n_home_games,
    a.n_away_games,
    -- lifts in percentage points (on 0–1 scale; multiply by 100 in a viz if desired)
    h.avg_home_fg_pct - a.avg_away_fg_pct AS fg_pct_lift,
    h.avg_home_2p_pct - a.avg_away_2p_pct AS p2_pct_lift,
    h.avg_home_3p_pct - a.avg_away_3p_pct AS p3_pct_lift
  FROM home h
  JOIN away a
    ON h.season_label  = a.season_label
   AND h.team_id = a.team_id
  WHERE
    h.n_home_games >= 8
    AND a.n_away_games >= 8
)
SELECT
  season_label,
  COUNT(*)                          AS team_seasons_kept,
  ROUND(AVG(fg_pct_lift), 4)        AS mean_fg_pct_lift,  -- e.g., 0.0123 = +1.23 pp
  ROUND(AVG(p2_pct_lift), 4)        AS mean_2p_pct_lift,
  ROUND(AVG(p3_pct_lift), 4)        AS mean_3p_pct_lift,
  ROUND(AVG(n_home_games), 1)       AS avg_home_games_kept,
  ROUND(AVG(n_away_games), 1)       AS avg_away_games_kept
FROM
  home_and_away
GROUP BY
  season_label
ORDER BY
  season_label;


-- 34_shooting_scale_check.sql
-- Purpose: show storage scale for 2P%/3P% across seasons (are they 0–1 or 0–100?)

SELECT
  season_label,
  ROUND(AVG(h_2p_pct), 3)  AS avg_raw_h_2p,
  ROUND(AVG(a_2p_pct), 3)  AS avg_raw_a_2p,
  ROUND(AVG(h_3p_pct), 3)  AS avg_raw_h_3p,
  ROUND(AVG(a_3p_pct), 3)  AS avg_raw_a_3p,
  -- normalized to 0–1 scale on the fly
  ROUND(AVG(CASE WHEN h_2p_pct > 1 THEN h_2p_pct/100 ELSE h_2p_pct END), 3) AS avg_norm_h_2p,
  ROUND(AVG(CASE WHEN a_2p_pct > 1 THEN a_2p_pct/100 ELSE a_2p_pct END), 3) AS avg_norm_a_2p
FROM
  `hca-2016-analysis.hca2016.v_games_core_box`
GROUP BY
  season_label
ORDER BY
  season_label;


-- 35_boxscore_points_sanity.sql
-- -- Quick points sanity check (reconstruct vs recorded)
-- Uses v_games_core_box (has *_made fields)

WITH recon AS (
  SELECT
    season_label,
    -- reconstruct points from makes
    (COALESCE(h_2pm, 0) * 2 + COALESCE(h_3pm, 0) * 3 + COALESCE(h_ftm, 0)) AS h_pts_recon,
    (COALESCE(a_2pm, 0) * 2 + COALESCE(a_3pm, 0) * 3 + COALESCE(a_ftm, 0)) AS a_pts_recon,
    h_pts,
    a_pts
  FROM
    `hca-2016-analysis.hca2016.v_games_core_box`
)
SELECT
  season_label,
  COUNT(*) AS n_games,
  SUM(CASE WHEN h_pts_recon != h_pts THEN 1 ELSE 0 END) AS h_mismatches,
  SUM(CASE WHEN a_pts_recon != a_pts THEN 1 ELSE 0 END) AS a_mismatches,
  MAX(ABS(h_pts_recon - h_pts)) AS max_abs_diff_home,
  MAX(ABS(a_pts_recon - a_pts)) AS max_abs_diff_away
FROM
  recon
GROUP BY
  season_label
ORDER BY
  season_label;


-- 36_turnovers_team_lift_detail.sql
-- -- Purpose:
--   Add turnover stats into the team-season lift framework.
--   Measures home–road difference in average turnovers (negative = home turns it over less).

CREATE OR REPLACE TABLE `hca-2016-analysis.hca2016.turnovers_team_lift` AS
WITH home AS (
  SELECT
    season_label,
    h_team_id AS team_id,
    h_team_name AS team_name,
    COUNT(*) AS n_home_games,
    AVG(h_turnovers) AS avg_home_to
  FROM
    `hca-2016-analysis.hca2016.v_games_core_box`
  GROUP BY
    season_label,
    team_id,
    team_name
),
away AS (
  SELECT
    season_label,
    a_team_id AS team_id,
    a_team_name AS team_name,
    COUNT(*) AS n_away_games,
    AVG(a_turnovers) AS avg_away_to
  FROM
    `hca-2016-analysis.hca2016.v_games_core_box`
  GROUP BY
    season_label,
    team_id,
    team_name
),
joined AS (
  SELECT
    COALESCE(h.season_label, a.season_label) AS season_label,
    COALESCE(h.team_id, a.team_id) AS team_id,
    COALESCE(h.team_name, a.team_name) AS team_name,
    IFNULL(h.n_home_games, 0) AS n_home_games,
    IFNULL(a.n_away_games, 0) AS n_away_games,
    IFNULL(h.avg_home_to, 0) AS avg_home_to,
    IFNULL(a.avg_away_to, 0) AS avg_away_to
  FROM
    home AS h
    FULL OUTER JOIN away AS a
      ON h.team_id = a.team_id
     AND h.season_label = a.season_label
)
SELECT
  season_label,
  team_id,
  team_name,
  n_home_games,
  n_away_games,
  ROUND(avg_home_to, 2) AS avg_home_to,
  ROUND(avg_away_to, 2) AS avg_away_to,
  ROUND(avg_away_to - avg_home_to, 2) AS to_gap,  -- positive = more TOs away
  (n_home_games + n_away_games) AS n_games_used
FROM
  joined
WHERE
  n_home_games >= 8
  AND n_away_games >= 8
ORDER BY
  season_label,
  team_id;


-- 37_turnovers_sanity_check.sql
-- Purpose:
--   Quick season-level check of raw average turnovers at home vs away.
--   Confirms the aggregate direction of turnover advantage.

CREATE OR REPLACE TABLE `hca-2016-analysis.hca2016.turnovers_sanity_check` AS
SELECT
  season_label,
  ROUND(AVG(h_turnovers), 2) AS avg_home_turnovers,
  ROUND(AVG(a_turnovers), 2) AS avg_away_turnovers,
  COUNT(*)                   AS n_games
FROM
  `hca-2016-analysis.hca2016.v_games_core_box`
GROUP BY season_label
ORDER BY season_label;


-- 38_turnovers_team_lift_summary.sql
-- Purpose:
--   Collapse team-season turnover gaps to one row per season.
--   Provides season-level average of home–road turnover difference.

CREATE OR REPLACE TABLE `hca-2016-analysis.hca2016.turnovers_team_lift_summary` AS
SELECT
  season_label,
  COUNT(*)                    AS team_seasons_kept,
  ROUND(AVG(to_gap), 3)       AS mean_to_gap,          -- + = more TOs away (home edge)
  ROUND(AVG(n_home_games), 1) AS avg_home_games_kept,
  ROUND(AVG(n_away_games), 1) AS avg_away_games_kept
FROM
  `hca-2016-analysis.hca2016.turnovers_team_lift`
GROUP BY
  season_label
ORDER BY
  season_label;


-- 39_rebounds_team_lift_detail.sql
-- Purpose:
--   Team-season home–road rebound gap (positive = more rebounds at home)

CREATE OR REPLACE TABLE `hca-2016-analysis.hca2016.rebounds_team_lift_detail` AS
WITH home AS (
  SELECT
    season_label,
    h_team_id AS team_id,
    h_team_name AS team_name,
    COUNT(*) AS n_home_games,
    AVG(h_team_rebounds) AS avg_home_reb
  FROM
    `hca-2016-analysis.hca2016.v_games_core_box`
  GROUP BY
    season_label,
    team_id,
    team_name
),
away AS (
  SELECT
    season_label,
    a_team_id AS team_id,
    a_team_name AS team_name,
    COUNT(*) AS n_away_games,
    AVG(a_team_rebounds) AS avg_away_reb
  FROM
    `hca-2016-analysis.hca2016.v_games_core_box`
  GROUP BY
    season_label,
    team_id,
    team_name
),
rebounds_team_season AS (
  SELECT
    COALESCE(h.season_label, a.season_label) AS season,
    COALESCE(h.team_id, a.team_id) AS team_id,
    COALESCE(h.team_name, a.team_name) AS team_name,
    IFNULL(h.n_home_games, 0) AS n_home_games,
    IFNULL(a.n_away_games, 0) AS n_away_games,
    IFNULL(h.avg_home_reb, 0) AS avg_home_reb,
    IFNULL(a.avg_away_reb, 0) AS avg_away_reb
  FROM
    home AS h
    FULL OUTER JOIN away AS a
      ON h.team_id = a.team_id
     AND h.season_label = a.season_label
)
SELECT
  season,
  team_id,
  team_name,
  n_home_games,
  n_away_games,
  ROUND(avg_home_reb, 2) AS avg_home_reb,
  ROUND(avg_away_reb, 2) AS avg_away_reb,
  ROUND(avg_home_reb - avg_away_reb, 2) AS reb_gap,  -- + = home edge
  (n_home_games + n_away_games) AS n_games_used
FROM
  rebounds_team_season
WHERE
  n_home_games >= 8
  AND n_away_games >= 8
ORDER BY
  season,
  team_id;


-- 39b_rebounds_team_lift_summary.sql
-- Purpose: season-level average of home–road rebound gap.

CREATE OR REPLACE TABLE `hca-2016-analysis.hca2016.rebounds_team_lift_summary` AS
SELECT
  season,
  COUNT(*)                    AS team_seasons_kept,
  ROUND(AVG(reb_gap), 3)      AS mean_reb_gap,
  ROUND(AVG(n_home_games), 1) AS avg_home_games_kept,
  ROUND(AVG(n_away_games), 1) AS avg_away_games_kept
FROM
  `hca-2016-analysis.hca2016.rebounds_team_lift_detail`
GROUP BY
  season
ORDER BY
  season;

-- 20_team_lift.sql
-- Purpose:
--   Compute TEAM-SEASON home-court "points lift": points_lift = (avg home margin) - (avg away margin).
--   Controls for team strength/exposure by comparing each team’s home vs away performance.
--   Includes team conference for grouping.
--
-- Input:
--   hca2016.games_core_filtered  (2014 pre, 2015 rule, 2016 post; no tournaments; no neutrals)
--
-- Output:
--   hca2016.team_lift_detail   = points lift for each team-season (with conference)
--   hca2016.team_lift_summary  = mean lift per season + sample sizes
--
-- Business rules:
--   • Keep team-seasons with at least 8 home and 8 away games.

CREATE OR REPLACE TABLE `hca-2016-analysis.hca2016.team_lift_detail` AS
WITH all_games AS (
  SELECT
    season,
    season_label,
    CAST(h_team_id AS STRING) AS h_team_id,
    CAST(a_team_id AS STRING) AS a_team_id,
    h_team_name,
    a_team_name,
    h_conf_name AS home_conf_name,
    a_conf_name AS away_conf_name,
    h_pts,
    a_pts
  FROM
    `hca-2016-analysis.hca2016.games_core_filtered`
),
home_team AS (
  SELECT
    season,
    season_label,
    h_team_id AS team_id,
    h_team_name AS team_name,
    home_conf_name AS conf_name,
    (h_pts - a_pts) AS margin_home
  FROM
    all_games
),
away_team AS (
  SELECT
    season,
    season_label,
    a_team_id AS team_id,
    a_team_name AS team_name,
    away_conf_name AS conf_name,
    (a_pts - h_pts) AS margin_away
  FROM
    all_games
),
home_agg AS (
  SELECT
    season,
    season_label,
    team_id,
    ANY_VALUE(team_name) AS team_name,
    ANY_VALUE(conf_name) AS conf_name,
    COUNT(*) AS n_home,
    AVG(margin_home) AS avg_home_margin
  FROM
    home_team
  GROUP BY
    season,
    season_label,
    team_id
),
away_agg AS (
  SELECT
    season,
    season_label,
    team_id,
    ANY_VALUE(team_name) AS team_name,
    ANY_VALUE(conf_name) AS conf_name,
    COUNT(*) AS n_away,
    AVG(margin_away) AS avg_away_margin
  FROM
    away_team
  GROUP BY
    season,
    season_label,
    team_id
),
joined AS (
  SELECT
    h.season,
    h.season_label,
    h.team_id,
    COALESCE(h.team_name, a.team_name) AS team_name,
    COALESCE(h.conf_name, a.conf_name) AS conf_name,
    h.n_home,
    a.n_away,
    h.avg_home_margin,
    a.avg_away_margin
  FROM
    home_agg AS h
    INNER JOIN away_agg AS a
      ON h.season = a.season
     AND h.season_label = a.season_label
     AND h.team_id = a.team_id
),
filtered AS (
  SELECT
    season,
    season_label,
    team_id,
    team_name,
    conf_name,
    n_home,
    n_away,
    ROUND(avg_home_margin, 2) AS avg_home_margin,
    ROUND(avg_away_margin, 2) AS avg_away_margin,
    ROUND(avg_home_margin - avg_away_margin, 2) AS points_lift,
    (n_home + n_away) AS n_games_used
  FROM
    joined
  WHERE
    n_home >= 8
    AND n_away >= 8
)
SELECT
  season,
  season_label,
  team_id,
  team_name,
  conf_name,
  n_home,
  n_away,
  avg_home_margin,
  avg_away_margin,
  points_lift,
  n_games_used
FROM
  filtered
ORDER BY
  season,
  team_id;

-- 20b_v_team_lift_summary_labeled.sql
-- Purpose:
--   Clarify season labeling by showing full span (e.g., 2014–15 instead of just 2014).
--   Provides presentation-ready season labels alongside numeric season codes.
--
-- Inputs:
--   hca2016.team_lift_summary
--
-- Outputs:
--   hca2016.v_team_lift_summary_labeled

CREATE OR REPLACE TABLE `hca-2016-analysis.hca2016.team_lift_summary` AS
SELECT
  season,
  season_label,
  ROUND(AVG(points_lift), 2) AS mean_points_lift,
  COUNT(*) AS team_seasons_kept,
  SUM(n_games_used) AS total_games_used,
  ROUND(AVG(n_home), 1) AS avg_home_games_kept,
  ROUND(AVG(n_away), 1) AS avg_away_games_kept
FROM
  `hca-2016-analysis.hca2016.team_lift_detail`
GROUP BY
  season,
  season_label
ORDER BY
  season;

-- 20c_team_lift_detail.sql
-- Purpose:
--   Compute TEAM-SEASON home-court "points lift": points_lift = (avg home margin) - (avg away margin).
--   Controls for team strength/exposure by comparing each team’s home vs away performance.
--   Includes team conference for grouping.
--
-- Input:
--   hca2016.games_core_filtered  (2014 pre, 2015 rule, 2016 post; no tournaments; no neutrals)
--
-- Output:
--   hca2016.team_lift_detail   = points lift for each team-season (with conference)
--   hca2016.team_lift_summary  = mean lift per season + sample sizes + HCA (= HRE/2)
--
-- Business rules:
--   • Keep team-seasons with at least 8 home and 8 away games.

CREATE OR REPLACE TABLE `hca-2016-analysis.hca2016.team_lift_detail` AS
WITH all_games AS (
  SELECT
    season,
    season_label,
    CAST(h_team_id AS STRING) AS h_team_id,
    CAST(a_team_id AS STRING) AS a_team_id,
    h_team_name,
    a_team_name,
    h_conf_name AS home_conf_name,
    a_conf_name AS away_conf_name,
    h_pts,
    a_pts
  FROM
    `hca-2016-analysis.hca2016.games_core_filtered`
),
home_team AS (
  SELECT
    season,
    season_label,
    h_team_id AS team_id,
    h_team_name AS team_name,
    home_conf_name AS conf_name,
    (h_pts - a_pts) AS margin_home
  FROM
    all_games
),
away_team AS (
  SELECT
    season,
    season_label,
    a_team_id AS team_id,
    a_team_name AS team_name,
    away_conf_name AS conf_name,
    (a_pts - h_pts) AS margin_away
  FROM
    all_games
),
home_agg AS (
  SELECT
    season,
    season_label,
    team_id,
    ANY_VALUE(team_name) AS team_name,
    ANY_VALUE(conf_name) AS conf_name,
    COUNT(*) AS n_home,
    AVG(margin_home) AS avg_home_margin
  FROM
    home_team
  GROUP BY
    season,
    season_label,
    team_id
),
away_agg AS (
  SELECT
    season,
    season_label,
    team_id,
    ANY_VALUE(team_name) AS team_name,
    ANY_VALUE(conf_name) AS conf_name,
    COUNT(*) AS n_away,
    AVG(margin_away) AS avg_away_margin
  FROM
    away_team
  GROUP BY
    season,
    season_label,
    team_id
),
joined AS (
  SELECT
    h.season,
    h.season_label,
    h.team_id,
    COALESCE(h.team_name, a.team_name) AS team_name,
    COALESCE(h.conf_name, a.conf_name) AS conf_name,
    h.n_home,
    a.n_away,
    h.avg_home_margin,
    a.avg_away_margin
  FROM
    home_agg AS h
    INNER JOIN away_agg AS a
      ON h.season = a.season
     AND h.season_label = a.season_label
     AND h.team_id = a.team_id
),
filtered AS (
  SELECT
    season,
    season_label,
    team_id,
    team_name,
    conf_name,
    n_home,
    n_away,
    ROUND(avg_home_margin, 2) AS avg_home_margin,
    ROUND(avg_away_margin, 2) AS avg_away_margin,
    ROUND(avg_home_margin - avg_away_margin, 2) AS points_lift,
    (n_home + n_away) AS n_games_used
  FROM
    joined
  WHERE
    n_home >= 8
    AND n_away >= 8
)
SELECT
  season,
  season_label,
  team_id,
  team_name,
  conf_name,
  n_home,
  n_away,
  avg_home_margin,
  avg_away_margin,
  points_lift,
  n_games_used
FROM
  filtered
ORDER BY
  season,
  team_id;

-- 20d_team_lift_summary.sql
-- -- Purpose:
--   Summarize by season and include HCA (= HRE/2) for Looker.
--
-- Input:
--   hca2016.team_lift_detail
--
-- Output:
--   hca2016.team_lift_summary

CREATE OR REPLACE TABLE `hca-2016-analysis.hca2016.team_lift_summary` AS
SELECT
  season,
  season_label,
  ROUND(AVG(points_lift), 2) AS mean_points_lift,      -- HRE (pts)
  ROUND(AVG(points_lift) / 2, 2) AS hca_points,        -- HCA (pts) = HRE/2
  COUNT(*) AS team_seasons_kept,
  SUM(n_games_used) AS total_games_used,
  ROUND(AVG(n_home), 1) AS avg_home_games_kept,
  ROUND(AVG(n_away), 1) AS avg_away_games_kept
FROM
  `hca-2016-analysis.hca2016.team_lift_detail`
GROUP BY
  season,
  season_label
ORDER BY
  season;


-- 21_conference_lift.sql
-- Purpose:
--   Mean team-season points lift by conference group for 2014–2016.
--   Pivot mean points lift by conference across 2014–2016 seasons for easier side-by-side comparison.
--
-- Conference grouping:
--   • Power 6: ACC, Big Ten, Big 12, SEC, Pac-12, Big East
--   • Mid-majors: AAC, MWC, WCC, A-10
--   • Other D-I: all remaining conferences 

CREATE OR REPLACE TABLE `hca-2016-analysis.hca2016.conference_lift_pivot` AS
WITH conf_summary AS (
  SELECT
      season,
      CASE
          WHEN conf_name = 'Atlantic Coast'    THEN 'ACC'
          WHEN conf_name = 'Big Ten'           THEN 'Big Ten'
          WHEN conf_name = 'Big 12'            THEN 'Big 12'
          WHEN conf_name = 'Southeastern'      THEN 'SEC'
          WHEN conf_name = 'Pacific 12'        THEN 'Pac-12'
          WHEN conf_name = 'Big East'          THEN 'Big East'
          WHEN conf_name = 'American Athletic' THEN 'AAC'
          WHEN conf_name = 'Mountain West'     THEN 'MWC'
          WHEN conf_name = 'West Coast'        THEN 'WCC'
          WHEN conf_name = 'Atlantic 10'       THEN 'A-10'
          WHEN conf_name = 'Missouri Valley'   THEN 'MVC'
          ELSE 'Other D-I'
      END AS conference_group,
      ROUND(AVG(points_lift), 2) AS mean_points_lift,
      SUM(n_games_used)          AS total_games_used
  FROM
      `hca-2016-analysis.hca2016.team_lift_detail`
  GROUP BY
      season, conference_group
)

SELECT
    conference_group,
    MAX(CASE WHEN season = 2014 THEN mean_points_lift END) AS lift_2014,
    MAX(CASE WHEN season = 2015 THEN mean_points_lift END) AS lift_2015,
    MAX(CASE WHEN season = 2016 THEN mean_points_lift END) AS lift_2016,
    MAX(CASE WHEN season = 2014 THEN total_games_used END) AS games_2014,
    MAX(CASE WHEN season = 2015 THEN total_games_used END) AS games_2015,
    MAX(CASE WHEN season = 2016 THEN total_games_used END) AS games_2016
FROM
    conf_summary
GROUP BY
    conference_group
ORDER BY
    conference_group;

-- 21b_v_conference_lift_pivot_labeled.sql
-- Purpose:
--   Clarify season labeling in the pivot by renaming year-coded columns
--   to full spans (e.g., 2014–15 instead of just 2014).
-- Inputs:
--   hca2016.conference_lift_pivot   -- (your current pivot table shown above)
-- Outputs:
--   hca2016.v_conference_lift_pivot_labeled

CREATE OR REPLACE VIEW `hca-2016-analysis.hca2016.v_conference_lift_pivot_labeled` AS
SELECT
  conference_group,
  -- Rename lift columns to two-year season labels
  lift_2014 AS lift_2014_15,
  lift_2015 AS lift_2015_16,
  lift_2016 AS lift_2016_17,
  -- Rename games columns likewise
  games_2014 AS games_2014_15,
  games_2015 AS games_2015_16,
  games_2016 AS games_2016_17
FROM
  `hca-2016-analysis.hca2016.conference_lift_pivot`
ORDER BY
  conference_group;


-- 29a_neutral_pulse_check.sql
-- Purpose:
--   Sanity check on our neutral-site handling.
--   In 2014–15 and 2015–16, neutral_site is NULL for all rows (treated as non-neutral).
--   Here, we test 2016–17 both with and without neutral games.
--   If including neutrals changes results materially, our pre-2016 assumption could bias outcomes.
--   If the difference is small, it validates our conservative treatment of NULLs.

-- Exclude neutrals (canonical)
SELECT
  'Exclude neutrals' AS policy,
  COUNT(*) AS n_games,
  ROUND(AVG(CASE WHEN h_points > a_points THEN 1 ELSE 0 END), 3) AS home_win_pct,
  ROUND(AVG(h_points - a_points), 2) AS avg_home_margin_pts
FROM
  `bigquery-public-data.ncaa_basketball.mbb_games_sr`
WHERE
  season = 2016
  AND IFNULL(neutral_site, FALSE) = FALSE
  AND NOT (
    tournament IS NOT NULL
    OR tournament_type IS NOT NULL
    OR tournament_round IS NOT NULL
    OR tournament_game_no IS NOT NULL
  )

UNION ALL

-- Include neutrals (sensitivity)
SELECT
  'Include neutrals' AS policy,
  COUNT(*) AS n_games,
  ROUND(AVG(CASE WHEN h_points > a_points THEN 1 ELSE 0 END), 3) AS home_win_pct,
  ROUND(AVG(h_points - a_points), 2) AS avg_home_margin_pts
FROM
  `bigquery-public-data.ncaa_basketball.mbb_games_sr`
WHERE
  season = 2016
  AND NOT (
    tournament IS NOT NULL
    OR tournament_type IS NOT NULL
    OR tournament_round IS NOT NULL
    OR tournament_game_no IS NOT NULL
  );


-- 29b_neutral_lift_check.sql
-- Purpose:
--   Same neutral-site sanity check, but at the normalized team-season level.
--   We recompute Home–Road Edge (points lift) for 2016–17 with and without neutral-site games.
--   Goal: confirm whether treating NULLs as non-neutral in earlier years meaningfully skews team-level results.

WITH excl_home AS (
  SELECT
    h_id AS team_id,
    COUNT(*) AS n_home,
    AVG(h_points - a_points) AS avg_home_margin
  FROM
    `bigquery-public-data.ncaa_basketball.mbb_games_sr`
  WHERE
    season = 2016
    AND IFNULL(neutral_site, FALSE) = FALSE
    AND NOT (
      tournament IS NOT NULL
      OR tournament_type IS NOT NULL
      OR tournament_round IS NOT NULL
      OR tournament_game_no IS NOT NULL
    )
  GROUP BY
    h_id
),
excl_away AS (
  SELECT
    a_id AS team_id,
    COUNT(*) AS n_away,
    AVG(a_points - h_points) AS avg_away_margin
  FROM
    `bigquery-public-data.ncaa_basketball.mbb_games_sr`
  WHERE
    season = 2016
    AND IFNULL(neutral_site, FALSE) = FALSE
    AND NOT (
      tournament IS NOT NULL
      OR tournament_type IS NOT NULL
      OR tournament_round IS NOT NULL
      OR tournament_game_no IS NOT NULL
    )
  GROUP BY
    a_id
),
excl_lift AS (
  SELECT
    'Exclude neutrals' AS policy,
    ROUND(AVG(eh.avg_home_margin - ea.avg_away_margin), 2) AS mean_points_lift,
    COUNT(*) AS team_seasons_kept
  FROM
    excl_home AS eh
    JOIN excl_away AS ea USING (team_id)
  WHERE
    eh.n_home >= 8
    AND ea.n_away >= 8
),
incl_home AS (
  SELECT
    h_id AS team_id,
    COUNT(*) AS n_home,
    AVG(h_points - a_points) AS avg_home_margin
  FROM
    `bigquery-public-data.ncaa_basketball.mbb_games_sr`
  WHERE
    season = 2016
    AND NOT (
      tournament IS NOT NULL
      OR tournament_type IS NOT NULL
      OR tournament_round IS NOT NULL
      OR tournament_game_no IS NOT NULL
    )
  GROUP BY
    h_id
),
incl_away AS (
  SELECT
    a_id AS team_id,
    COUNT(*) AS n_away,
    AVG(a_points - h_points) AS avg_away_margin
  FROM
    `bigquery-public-data.ncaa_basketball.mbb_games_sr`
  WHERE
    season = 2016
    AND NOT (
      tournament IS NOT NULL
      OR tournament_type IS NOT NULL
      OR tournament_round IS NOT NULL
      OR tournament_game_no IS NOT NULL
    )
  GROUP BY
    a_id
),
incl_lift AS (
  SELECT
    'Include neutrals' AS policy,
    ROUND(AVG(ih.avg_home_margin - ia.avg_away_margin), 2) AS mean_points_lift,
    COUNT(*) AS team_seasons_kept
  FROM
    incl_home AS ih
    JOIN incl_away AS ia USING (team_id)
  WHERE
    ih.n_home >= 8
    AND ia.n_away >= 8
)
SELECT
  *
FROM
  excl_lift
UNION ALL
SELECT
  *
FROM
  incl_lift;

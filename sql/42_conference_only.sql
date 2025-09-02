-- 42_conference_only_sensitivity.sql
-- Purpose:
--   Restrict analysis to conference-only games to check whether the observed
--   decline in Home–Road Edge (HRE) holds when non-conference scheduling quirks
--   (buy games, mismatched road trips, etc.) are removed.
-- Notes:
--   • Uses v_games_core_box (2014–2016, no tournaments, no neutrals).
--   • Conference-only flag = TRUE when both teams’ conf_name are equal.

CREATE OR REPLACE TABLE `hca-2016-analysis.hca2016.conference_only_team_lift_summary` AS
WITH base AS (
  SELECT
    season_label,
    h_team_id,
    h_team_name,
    a_team_id,
    a_team_name,
    h_pts,
    a_pts,
    h_conf_name,
    a_conf_name
  FROM
    `hca-2016-analysis.hca2016.v_games_core_box`
  WHERE
    h_conf_name = a_conf_name  -- restrict to conference-only games
),
home AS (
  SELECT
    season_label,
    h_team_id AS team_id,
    h_team_name AS team_name,
    COUNT(*) AS n_home_games,
    AVG(h_pts - a_pts) AS avg_home_margin
  FROM
    base
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
    AVG(a_pts - h_pts) AS avg_away_margin
  FROM
    base
  GROUP BY
    season_label,
    team_id,
    team_name
),
joined AS (
  SELECT
    COALESCE(h.season_label, a.season_label) AS season,
    COALESCE(h.team_id, a.team_id) AS team_id,
    COALESCE(h.team_name, a.team_name) AS team_name,
    IFNULL(h.n_home_games, 0) AS n_home_games,
    IFNULL(a.n_away_games, 0) AS n_away_games,
    IFNULL(h.avg_home_margin, 0) AS avg_home_margin,
    IFNULL(a.avg_away_margin, 0) AS avg_away_margin
  FROM
    home AS h
    FULL OUTER JOIN away AS a
      ON h.team_id = a.team_id
     AND h.season_label = a.season_label
)
SELECT
  season,
  COUNT(*) AS team_seasons_kept,
  ROUND(AVG(avg_home_margin - avg_away_margin), 2) AS mean_points_lift,
  ROUND(AVG(n_home_games), 1) AS avg_home_games_kept,
  ROUND(AVG(n_away_games), 1) AS avg_away_games_kept
FROM
  joined
WHERE
  n_home_games >= 8
  AND n_away_games >= 8
GROUP BY
  season
ORDER BY
  season;

-- 43_conference_only_per_league_pivot.sql
-- Purpose:
--   Intra-conference only HRE: build team-season lifts using games where both teams are in the same conference,
--   then summarize by league and pivot seasons for side-by-side comparison.
-- Notes:
--   • Reads from v_games_core_box (which must include h_conf_name / a_conf_name).
--   • Uses ≥8/≥8 games per team-season sample guard.
--   • Conference mapping matches your earlier conference_lift_pivot table.

CREATE OR REPLACE TABLE `hca-2016-analysis.hca2016.conference_only_lift_pivot` AS
WITH base AS (
  SELECT
    season,
    h_team_id,
    h_team_name,
    h_conf_name,
    a_team_id,
    a_team_name,
    a_conf_name,
    h_pts,
    a_pts
  FROM
    `hca-2016-analysis.hca2016.v_games_core_box`
  WHERE
    -- intra-conference only
    h_conf_name = a_conf_name
),
home AS (
  SELECT
    season,
    CAST(h_team_id AS STRING) AS team_id,
    ANY_VALUE(h_team_name) AS team_name,
    ANY_VALUE(h_conf_name) AS conf_name,
    COUNT(*) AS n_home_games,
    AVG(h_pts - a_pts) AS avg_home_margin
  FROM
    base
  GROUP BY
    season,
    team_id
),
away AS (
  SELECT
    season,
    CAST(a_team_id AS STRING) AS team_id,
    ANY_VALUE(a_team_name) AS team_name,
    ANY_VALUE(a_conf_name) AS conf_name,
    COUNT(*) AS n_away_games,
    AVG(a_pts - h_pts) AS avg_away_margin
  FROM
    base
  GROUP BY
    season,
    team_id
),
team_lift AS (
  SELECT
    COALESCE(h.season, a.season) AS season,
    COALESCE(h.team_id, a.team_id) AS team_id,
    COALESCE(h.team_name, a.team_name) AS team_name,
    COALESCE(h.conf_name, a.conf_name) AS conf_name,
    IFNULL(h.n_home_games, 0) AS n_home_games,
    IFNULL(a.n_away_games, 0) AS n_away_games,
    IFNULL(h.avg_home_margin, 0) AS avg_home_margin,
    IFNULL(a.avg_away_margin, 0) AS avg_away_margin,
    -- Home–Road Edge (HRE) within conference
    (IFNULL(h.avg_home_margin, 0) - IFNULL(a.avg_away_margin, 0)) AS points_lift,
    (IFNULL(h.n_home_games, 0) + IFNULL(a.n_away_games, 0)) AS n_games_used
  FROM
    home AS h
    FULL OUTER JOIN away AS a
      ON h.team_id = a.team_id
     AND h.season = a.season
  WHERE
    IFNULL(h.n_home_games, 0) >= 8
    AND IFNULL(a.n_away_games, 0) >= 8
),
conf_summary AS (
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
    SUM(n_games_used) AS total_games_used,
    COUNT(*) AS team_seasons_kept
  FROM
    team_lift
  GROUP BY
    season,
    conference_group
)
SELECT
  conference_group,
  MAX(CASE WHEN season = 2014 THEN mean_points_lift END) AS lift_2014,
  MAX(CASE WHEN season = 2015 THEN mean_points_lift END) AS lift_2015,
  MAX(CASE WHEN season = 2016 THEN mean_points_lift END) AS lift_2016,
  MAX(CASE WHEN season = 2014 THEN total_games_used END) AS games_2014,
  MAX(CASE WHEN season = 2015 THEN total_games_used END) AS games_2015,
  MAX(CASE WHEN season = 2016 THEN total_games_used END) AS games_2016,
  MAX(CASE WHEN season = 2014 THEN team_seasons_kept END) AS teams_2014,
  MAX(CASE WHEN season = 2015 THEN team_seasons_kept END) AS teams_2015,
  MAX(CASE WHEN season = 2016 THEN team_seasons_kept END) AS teams_2016
FROM
  conf_summary
GROUP BY
  conference_group
ORDER BY
  conference_group;

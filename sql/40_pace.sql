-- 40_pace_team_lift_summary.sql
-- Purpose:
--   Season-level pace gap using possessions ≈ FGA + 0.475 * FTA - OREB + TO
-- Source:
--   hca-2016-analysis.hca2016.v_games_core_box

CREATE OR REPLACE TABLE `hca-2016-analysis.hca2016.pace_team_lift_summary` AS
WITH home AS (
  SELECT
    season_label,
    h_team_id AS team_id,
    h_team_name AS team_name,
    COUNT(*) AS n_home_games,
    AVG(h_fga + 0.475 * h_fta - h_offensive_rebounds + h_turnovers) AS avg_home_possessions
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
    AVG(a_fga + 0.475 * a_fta - a_offensive_rebounds + a_turnovers) AS avg_away_possessions
  FROM
    `hca-2016-analysis.hca2016.v_games_core_box`
  GROUP BY
    season_label,
    team_id,
    team_name
),
team_pace AS (
  SELECT
    COALESCE(h.season_label, a.season_label) AS season_label,
    COALESCE(h.team_id, a.team_id) AS team_id,
    COALESCE(h.team_name, a.team_name) AS team_name,
    IFNULL(h.n_home_games, 0) AS n_home_games,
    IFNULL(a.n_away_games, 0) AS n_away_games,
    IFNULL(h.avg_home_possessions, 0) AS avg_home_possessions,
    IFNULL(a.avg_away_possessions, 0) AS avg_away_possessions
  FROM
    home AS h
    FULL OUTER JOIN away AS a
      ON h.team_id = a.team_id
     AND h.season_label = a.season_label
)
SELECT
  season_label,
  COUNTIF(n_home_games >= 8 AND n_away_games >= 8) AS team_seasons_kept,
  ROUND(
    AVG(
      CASE
        WHEN n_home_games >= 8 AND n_away_games >= 8
        THEN avg_home_possessions - avg_away_possessions
      END
    ),
    3
  ) AS mean_pace_gap,
  ROUND(
    AVG(
      CASE
        WHEN n_home_games >= 8 AND n_away_games >= 8 THEN n_home_games
      END
    ),
    1
  ) AS avg_home_games_kept,
  ROUND(
    AVG(
      CASE
        WHEN n_home_games >= 8 AND n_away_games >= 8 THEN n_away_games
      END
    ),
    1
  ) AS avg_away_games_kept
FROM
  team_pace
GROUP BY
  season_label
ORDER BY
  season_label;


-- 40b_pace_season_summary_national.sql
-- -- Purpose:
--   Builds league-average pace per season AND joins the team-normalized pace gap.

CREATE OR REPLACE TABLE `hca-2016-analysis.hca2016.pace_season_summary` AS
WITH game_poss AS (
  SELECT
    season_label,
    -- Possessions per team in a game (college factor 0.475)
    (h_fga + 0.475 * h_fta - h_offensive_rebounds + h_turnovers) AS home_poss,
    (a_fga + 0.475 * a_fta - a_offensive_rebounds + a_turnovers) AS away_poss
  FROM
    `hca-2016-analysis.hca2016.v_games_core_box`
),
league_pace AS (
  SELECT
    season_label,
    ROUND(AVG(home_poss), 2) AS league_home_pace,
    ROUND(AVG(away_poss), 2) AS league_away_pace,
    ROUND(AVG((home_poss + away_poss) / 2), 2) AS league_avg_pace  -- use this for the left panel
  FROM
    game_poss
  GROUP BY
    season_label
),
gap AS (
  -- team-season–normalized gap you already computed
  SELECT
    season_label,
    team_seasons_kept,
    mean_pace_gap
  FROM
    `hca-2016-analysis.hca2016.pace_team_lift_summary`
)
SELECT
  lp.season_label,
  lp.league_home_pace,
  lp.league_away_pace,
  lp.league_avg_pace,
  g.team_seasons_kept,
  g.mean_pace_gap  -- use this for the right panel
FROM
  league_pace AS lp
  LEFT JOIN gap AS g USING (season_label)
ORDER BY
  season_label;


-- 46_rules_bundle_scoring_pace_check.sql
-- Purpose:
--   Sanity check whether the 2015–16 rule changes produced the expected uptick in scoring, 
--   possessions, and shooting percentages.

SELECT
  season_label AS season,
  COUNT(*) AS n_games,
  ROUND(AVG(h_pts + a_pts), 2) AS avg_total_points,
  ROUND(AVG(h_pts), 2) AS avg_home_points,
  ROUND(AVG(a_pts), 2) AS avg_away_points,
  ROUND(AVG(h_fga + a_fga), 2) AS avg_fga,
  ROUND(AVG(h_fgm + a_fgm) / AVG(h_fga + a_fga), 2) AS fg_pct_overall,
  -- Crude possessions estimate per team
  ROUND(
    AVG(
      (h_fga - h_offensive_rebounds + h_turnovers + 0.475 * h_fta)
      + (a_fga - a_offensive_rebounds + a_turnovers + 0.475 * a_fta)
    ) / 2,
    2
  ) AS est_possessions_per_team
FROM
  `hca-2016-analysis.hca2016.v_games_core_box`
GROUP BY
  season
ORDER BY
  season;

-- 46b_home_away_scoring_trends.sql
-- -- Purpose:
--   Season-level average points per game (Home vs Away)
-- Output:
--   One row per season, columns for home_ppg and away_ppg

CREATE OR REPLACE TABLE `hca-2016-analysis.hca2016.home_vs_away_points_wide` AS
SELECT
  season_label,
  ROUND(AVG(h_pts), 2) AS home_ppg,
  ROUND(AVG(a_pts), 2) AS away_ppg
FROM
  `hca-2016-analysis.hca2016.v_games_core_box`
GROUP BY
  season_label
ORDER BY
  season_label;

-- 47_close_game_share_by_season.sql 
-- Purpose:
--   Check whether share of close games (|margin| ≤ 5) changed post-2015–16.
--   Sanity check on σ drop: tighter games should mean more nail-biters.

CREATE OR REPLACE TABLE `hca-2016-analysis.hca2016.close_game_share` AS
SELECT
  season,
  season_label,
  COUNT(*) AS n_games,
  SUM(CASE WHEN ABS(h_pts - a_pts) <= 5 THEN 1 ELSE 0 END) AS n_close_games,
  ROUND(SUM(CASE WHEN ABS(h_pts - a_pts) <= 5 THEN 1 ELSE 0 END) / COUNT(*), 3) 
    AS close_game_share
FROM
  `hca-2016-analysis.hca2016.games_core_filtered`
GROUP BY
  season, season_label
ORDER BY
  season;


-- 47b_close_game_shares_extended.sql
-- Purpose:
--   Season-level share of games decided by ≤5, ≤10, and ≤20 points

CREATE OR REPLACE TABLE `hca-2016-analysis.hca2016.close_game_shares_extended` AS
SELECT
  season_label,
  COUNT(*) AS n_games,

  -- ≤5 pts
  SUM(CASE WHEN ABS(h_pts - a_pts) <= 5 THEN 1 ELSE 0 END) AS n_close_5,
  ROUND(
    100 * SUM(CASE WHEN ABS(h_pts - a_pts) <= 5 THEN 1 ELSE 0 END) / COUNT(*),
    1
  ) AS share_close_5_pct,

  -- ≤10 pts
  SUM(CASE WHEN ABS(h_pts - a_pts) <= 10 THEN 1 ELSE 0 END) AS n_close_10,
  ROUND(
    100 * SUM(CASE WHEN ABS(h_pts - a_pts) <= 10 THEN 1 ELSE 0 END) / COUNT(*),
    1
  ) AS share_close_10_pct,

  -- ≤20 pts
  SUM(CASE WHEN ABS(h_pts - a_pts) <= 20 THEN 1 ELSE 0 END) AS n_close_20,
  ROUND(
    100 * SUM(CASE WHEN ABS(h_pts - a_pts) <= 20 THEN 1 ELSE 0 END) / COUNT(*),
    1
  ) AS share_close_20_pct
FROM
  `hca-2016-analysis.hca2016.games_core_filtered`
GROUP BY
  season_label
ORDER BY
  season_label;

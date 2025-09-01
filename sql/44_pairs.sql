-- 44_paired_swaps_detail.sql
-- Purpose:
--   Estimate venue effect via home/away pairs within the same season.
--   For each X↔Y matchup (both venues), compute:
--     home_margin_when_X_home, home_margin_when_Y_home,
--     venue_effect_pair = (home_margin_Xhome + home_margin_Yhome) / 2
-- Inputs:
--   hca2016.v_games_core_box  (2014–2016; no tournaments; no neutrals)

CREATE OR REPLACE TABLE `hca-2016-analysis.hca2016.paired_swaps_detail` AS
WITH game_margins AS (
  SELECT
    season,
    h_team_id AS home_id,
    a_team_id AS away_id,
    (h_pts - a_pts) AS home_margin
  FROM
    `hca-2016-analysis.hca2016.v_games_core_box`
),
matchups AS (
  SELECT
    season,
    LEAST(home_id, away_id) AS team_lo,
    GREATEST(home_id, away_id) AS team_hi,
    home_id AS host_id,
    home_margin
  FROM
    game_margins
),
host_side AS (
  SELECT
    season,
    team_lo,
    team_hi,
    host_id,
    COUNT(*) AS n_host_games,
    AVG(home_margin) AS avg_host_home_margin
  FROM
    matchups
  GROUP BY
    season,
    team_lo,
    team_hi,
    host_id
),
paired AS (
  SELECT
    a.season,
    a.team_lo,
    a.team_hi,
    a.host_id AS lo_host_id,
    b.host_id AS hi_host_id,
    a.n_host_games AS n_lo_home,
    b.n_host_games AS n_hi_home,
    a.avg_host_home_margin AS lo_home_margin,
    b.avg_host_home_margin AS hi_home_margin,
    (a.avg_host_home_margin + b.avg_host_home_margin) / 2.0 AS venue_effect_pair
  FROM
    host_side a
    JOIN host_side b
      ON a.season = b.season
     AND a.team_lo = b.team_lo
     AND a.team_hi = b.team_hi
     AND a.host_id <> b.host_id
)
SELECT
  season,
  team_lo,
  team_hi,
  lo_host_id,
  hi_host_id,
  n_lo_home,
  n_hi_home,
  ROUND(lo_home_margin, 2) AS lo_home_margin,
  ROUND(hi_home_margin, 2) AS hi_home_margin,
  ROUND(venue_effect_pair, 2) AS venue_effect_pair,
  (n_lo_home + n_hi_home) AS n_games_used
FROM
  paired
QUALIFY
  ROW_NUMBER() OVER (
    PARTITION BY season, team_lo, team_hi
    ORDER BY lo_host_id, hi_host_id
  ) = 1
ORDER BY
  season,
  team_lo,
  team_hi;


-- 45_paired_swaps_summary.sql
-- Purpose:
--   Season-level summary of paired swaps.
--   Report mean venue effect (H) across pairs and the implied HRE (= 2H) for easy comparison.
-- Notes:
--   'pairs_kept' = number of X↔Y matchups with both venues played.

CREATE OR REPLACE TABLE `hca-2016-analysis.hca2016.paired_swaps_summary` AS
SELECT
  CASE season
    WHEN 2014 THEN '2014–15'
    WHEN 2015 THEN '2015–16'
    WHEN 2016 THEN '2016–17'
    ELSE CAST(season AS STRING)
  END AS season_label,
  season,
  COUNT(*) AS n_pairs_used,
  SUM(n_games_used) AS total_games_used,
  ROUND(AVG(venue_effect_pair), 2) AS mean_venue_effect_pts,
  ROUND(STDDEV_SAMP(venue_effect_pair), 2) AS sd_venue_effect_pts
FROM
  `hca-2016-analysis.hca2016.paired_swaps_detail`
GROUP BY
  season
ORDER BY
  season;

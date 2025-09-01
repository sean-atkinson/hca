-- 10_season_pulse.sql
-- Purpose:
--   Season-level home win% and average home margin (points),
--   using the canonical filtered view (no tournaments, no neutrals).

CREATE OR REPLACE TABLE `hca-2016-analysis.hca2016.season_pulse` AS
SELECT
  season,         -- keep numeric for joins/sorting
  season_label,   -- human-readable for charts/CSVs
  ROUND(
    SAFE_DIVIDE(
      SUM(CASE WHEN h_pts > a_pts THEN 1 ELSE 0 END),
      COUNT(*)
    ),
    3
  ) AS home_win_pct,
  ROUND(AVG(h_pts - a_pts), 2) AS avg_home_margin_pts,
  COUNT(*) AS n_games
FROM
  `hca-2016-analysis.hca2016.games_core_filtered`
GROUP BY
  season,
  season_label
ORDER BY
  season;


-- 11_stddev_final_margin.sql
-- Purpose:
--   Compute dataset-specific spread of final margins and an approximate
--   points-to-win-probability factor near pick'em.
-- Notes:
--   • margin = (h_pts - a_pts) from canonical filtered games.
--   • pp_per_point_approx uses normal PDF at 0: 1 / (σ * sqrt(2π)).
--     Use as an interpretability aid; not for betting.

CREATE OR REPLACE TABLE `hca-2016-analysis.hca2016.final_margin_sigma` AS
WITH margins AS (
  SELECT
    season,
    season_label,
    (h_pts - a_pts) AS margin
  FROM
    `hca-2016-analysis.hca2016.games_core_filtered`
),
by_season AS (
  SELECT
    season_label,
    COUNT(*) AS n_games,
    ROUND(AVG(margin), 2) AS mean_margin,
    ROUND(STDDEV_SAMP(margin), 2) AS sigma_margin,
    ROUND(
      1.0 / (STDDEV_SAMP(margin) * 2.50662827463),
      4
    ) AS pp_per_point_approx
  FROM
    margins
  GROUP BY
    season_label
),
overall AS (
  SELECT
    'All seasons' AS season_label,
    COUNT(*) AS n_games,
    ROUND(AVG(margin), 2) AS mean_margin,
    ROUND(STDDEV_SAMP(margin), 2) AS sigma_margin,
    ROUND(
      1.0 / (STDDEV_SAMP(margin) * 2.50662827463),
      4
    ) AS pp_per_point_approx
  FROM
    margins
)
SELECT
  *
FROM
  by_season
UNION ALL
SELECT
  *
FROM
  overall
ORDER BY
  season_label;

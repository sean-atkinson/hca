-- 48_pp_per_point_factors.sql
CREATE OR REPLACE TABLE `hca-2016-analysis.hca2016.pp_per_point_factors` AS
SELECT
  '2014–15' AS season_label,
  1.6 AS pp_per_point
UNION ALL
SELECT
  '2015–16' AS season_label,
  1.5 AS pp_per_point
UNION ALL
SELECT
  '2016–17' AS season_label,
  2.3 AS pp_per_point;

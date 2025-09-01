-- 49_conference_rollup.sql
-- Purpose:
--   Roll up team-level HRE (points_lift) into 3 buckets using FULL conf names,
--   with "Conference" removed for labeling.
-- Buckets:
--   Power Six: Atlantic Coast, Big Ten, Big 12, Pacific 12, Southeastern, Big East
--   Mid-Majors: American Athletic, Mountain West, West Coast, Atlantic 10
--   Other D-I: everything else

CREATE OR REPLACE TABLE `hca-2016-analysis.hca2016.conference_rollup_groups` AS
WITH base AS (
  SELECT
    season_label,
    TRIM(REGEXP_REPLACE(conf_name, r'\s*Conference$', '')) AS conf_full,
    points_lift
  FROM
    `hca-2016-analysis.hca2016.team_lift_detail`
),
bucketed AS (
  SELECT
    season_label,
    conf_full,
    CASE
      WHEN conf_full IN ('Atlantic Coast', 'Big Ten', 'Big 12', 'Pacific 12', 'Southeastern', 'Big East')
        THEN 'Power Six'
      WHEN conf_full IN ('American Athletic', 'Mountain West', 'West Coast', 'Atlantic 10', 'Missouri Valley')
        THEN 'Mid-Majors'
      ELSE 'Other D-I'
    END AS conf_group,
    points_lift
  FROM
    base
)
SELECT
  season_label,
  conf_group,
  ROUND(AVG(points_lift), 2) AS mean_points_lift,
  COUNT(*) AS team_seasons_kept
FROM
  bucketed
GROUP BY
  season_label,
  conf_group
ORDER BY
  conf_group,
  season_label;


-- 49b_conference_rollup_pivot.sql
-- -- Purpose:
--   Roll conferences into 3 buckets (Power Six / Mid-Majors / Other D-I),
--   then pivot season-level mean points lift into separate columns.
--   Chart-ready for grouped bar charts (one row per bucket).

CREATE OR REPLACE TABLE `hca-2016-analysis.hca2016.conference_rollup_pivot` AS
WITH grouped AS (
  SELECT
    season_label,
    CASE
      WHEN conf_name IN ('Atlantic Coast', 'Big Ten', 'Big 12', 'Southeastern', 'Pacific 12', 'Big East')
        THEN 'Power Six'
      WHEN conf_name IN ('American Athletic', 'Mountain West', 'West Coast', 'Missouri Valley', 'Atlantic 10')
        THEN 'Mid-Majors'
      ELSE 'Other D-I'
    END AS conf_group,
    ROUND(AVG(points_lift), 2) AS mean_points_lift
  FROM
    `hca-2016-analysis.hca2016.team_lift_detail`
  GROUP BY
    season_label,
    conf_group
)
SELECT
  conf_group,
  ROUND(MAX(CASE WHEN season_label = '2014–15' THEN mean_points_lift END), 2) AS lift_2014_15,
  ROUND(MAX(CASE WHEN season_label = '2015–16' THEN mean_points_lift END), 2) AS lift_2015_16,
  ROUND(MAX(CASE WHEN season_label = '2016–17' THEN mean_points_lift END), 2) AS lift_2016_17
FROM
  grouped
GROUP BY
  conf_group
ORDER BY
  conf_group;


-- 49c_conference_rollup_pivot.sql
-- Purpose:
--   Roll conferences into 3 buckets (Power Six / Mid-Majors / Other D-I),
--   then pivot season-level mean points lift into separate columns.
--   This makes it chart-ready for grouped bar charts (one row per bucket).

CREATE OR REPLACE TABLE `hca-2016-analysis.hca2016.conference_rollup_pivot` AS
WITH grouped AS (
  SELECT
    season_label,
    CASE
      WHEN conf_name IN ('Atlantic Coast', 'Big Ten', 'Big 12', 'Southeastern', 'Pacific 12', 'Big East')
        THEN 'Power Six'
      WHEN conf_name IN ('American Athletic', 'Mountain West', 'West Coast', 'Atlantic 10')
        THEN 'Mid-Majors'
      ELSE 'Other D-I'
    END AS conf_group,
    AVG(points_lift) AS mean_points_lift
  FROM
    `hca-2016-analysis.hca2016.team_lift_detail`
  GROUP BY
    season_label,
    conf_group
)
SELECT
  conf_group,
  MAX(CASE WHEN season_label = '2014–15' THEN mean_points_lift END) AS lift_2014_15,
  MAX(CASE WHEN season_label = '2015–16' THEN mean_points_lift END) AS lift_2015_16,
  MAX(CASE WHEN season_label = '2016–17' THEN mean_points_lift END) AS lift_2016_17
FROM
  grouped
GROUP BY
  conf_group
ORDER BY
  conf_group;

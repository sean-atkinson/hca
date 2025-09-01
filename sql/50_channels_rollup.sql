-- 50a_channels_rollup_wide.sql
-- Purpose:
--   One row per season_label with all channel means as columns.

CREATE OR REPLACE TABLE `hca-2016-analysis.hca2016.channels_rollup_wide` AS
WITH ft AS (
  SELECT
    season_label,
    AVG(mean_ft_rate_lift) AS ft_rate_lift,
    AVG(mean_ft_pct_lift_totals) AS ft_pct_lift
  FROM
    `hca-2016-analysis.hca2016.ft_rate_team_lift_summary`
  GROUP BY
    season_label
),
fouls AS (
  SELECT
    season_label,
    AVG(mean_fouls_gap) AS fouls_gap
  FROM
    `hca-2016-analysis.hca2016.fouls_team_lift_summary`
  GROUP BY
    season_label
),
shoot AS (
  SELECT
    season_label,
    AVG(mean_fg_pct_lift) AS fg_pct_lift,
    AVG(mean_2p_pct_lift) AS p2_pct_lift,
    AVG(mean_3p_pct_lift) AS p3_pct_lift
  FROM
    `hca-2016-analysis.hca2016.shooting_team_lift`
  GROUP BY
    season_label
),
tos AS (
  SELECT
    season_label,
    AVG(mean_to_gap) AS to_gap
  FROM
    `hca-2016-analysis.hca2016.turnovers_team_lift_summary`
  GROUP BY
    season_label
),
rebs AS (
  SELECT
    CAST(season AS STRING) AS season_label,
    AVG(mean_reb_gap) AS reb_gap
  FROM
    `hca-2016-analysis.hca2016.rebounds_team_lift_summary`
  GROUP BY
    season
),
pace AS (
  SELECT
    season_label,
    AVG(mean_pace_gap) AS pace_gap
  FROM
    `hca-2016-analysis.hca2016.pace_team_lift_summary`
  GROUP BY
    season_label
)
SELECT
  COALESCE(
    ft.season_label,
    fouls.season_label,
    shoot.season_label,
    tos.season_label,
    rebs.season_label,
    pace.season_label
  ) AS season_label,
  ft.ft_rate_lift,
  ft.ft_pct_lift,
  fouls.fouls_gap,
  tos.to_gap,
  rebs.reb_gap,
  shoot.fg_pct_lift,
  shoot.p2_pct_lift,
  shoot.p3_pct_lift,
  pace.pace_gap
FROM
  ft
  FULL OUTER JOIN fouls USING (season_label)
  FULL OUTER JOIN shoot USING (season_label)
  FULL OUTER JOIN tos USING (season_label)
  FULL OUTER JOIN rebs USING (season_label)
  FULL OUTER JOIN pace USING (season_label)
ORDER BY
  season_label;


-- 50b_channels_rollup_long.sql
-- Purpose:
--   Long format for grouped-bar visuals (Sheets/Canva/Tableau).

CREATE OR REPLACE TABLE `hca-2016-analysis.hca2016.channels_rollup_long` AS
WITH wide AS (
  SELECT
    *
  FROM
    `hca-2016-analysis.hca2016.channels_rollup_wide`
),
long AS (
  SELECT
    season_label,
    'FT rate lift' AS channel,
    ft_rate_lift AS value,
    'delta (FTA/FGA)' AS unit_hint,
    'FT rate lift' AS display_label
  FROM
    wide
  UNION ALL
  SELECT
    season_label,
    'FT% lift' AS channel,
    ft_pct_lift AS value,
    'delta (proportion)' AS unit_hint,
    'FT% lift' AS display_label
  FROM
    wide
  UNION ALL
  SELECT
    season_label,
    'Fouls gap' AS channel,
    fouls_gap AS value,
    'fouls per game' AS unit_hint,
    'Fouls gap' AS display_label
  FROM
    wide
  UNION ALL
  SELECT
    season_label,
    'Turnover gap' AS channel,
    to_gap AS value,
    'turnovers per game' AS unit_hint,
    'TO gap' AS display_label
  FROM
    wide
  UNION ALL
  SELECT
    season_label,
    'Rebound gap' AS channel,
    reb_gap AS value,
    'rebounds per game' AS unit_hint,
    'REB gap' AS display_label
  FROM
    wide
  UNION ALL
  SELECT
    season_label,
    'FG% lift' AS channel,
    fg_pct_lift AS value,
    'delta (proportion)' AS unit_hint,
    'FG% lift' AS display_label
  FROM
    wide
  UNION ALL
  SELECT
    season_label,
    '2P% lift' AS channel,
    p2_pct_lift AS value,
    'delta (proportion)' AS unit_hint,
    '2P% lift' AS display_label
  FROM
    wide
  UNION ALL
  SELECT
    season_label,
    '3P% lift' AS channel,
    p3_pct_lift AS value,
    'delta (proportion)' AS unit_hint,
    '3P% lift' AS display_label
  FROM
    wide
  UNION ALL
  SELECT
    season_label,
    'Pace gap' AS channel,
    pace_gap AS value,
    'possessions per game' AS unit_hint,
    'Pace gap' AS display_label
  FROM
    wide
)
SELECT
  season_label,
  channel,
  display_label,
  unit_hint,
  value,
  CASE
    WHEN channel IN ('FG% lift', '2P% lift', '3P% lift', 'FT% lift') THEN ROUND(value * 100, 2)  -- percentage points helper
    ELSE NULL
  END AS value_pp
FROM
  long
ORDER BY
  channel,
  season_label;


-- 51_conference_only_hre_long.sql
-- Purpose:
--   Conference-only HRE, long format for line charts

SELECT
  conference_group,
  CASE season_col
    WHEN 'lift_2014' THEN '2014-15'
    WHEN 'lift_2015' THEN '2015-16'
    WHEN 'lift_2016' THEN '2016-17'
  END AS season,
  lift AS hre_points
FROM
  `hca-2016-analysis.hca2016.conference_only_lift_pivot`
UNPIVOT (
  lift FOR season_col IN (lift_2014, lift_2015, lift_2016)
)
ORDER BY
  conference_group,
  season;

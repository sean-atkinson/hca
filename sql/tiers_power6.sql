-- 52a_channels_by_tier_seasons_wide.sql
-- Canonical rollup for 4 channels by conference tier, across 3 seasons.
-- Output: one row per (conf_group, channel) with 3 season columns.

CREATE OR REPLACE TABLE `hca-2016-analysis.hca2016.channels_by_tier_seasons_wide` AS
WITH
-- 1) Pull home/away game-level stats
home_games AS (
  SELECT
    season_label,
    CAST(h_team_id AS STRING) AS team_id,
    h_team_name AS team_name,
    TRIM(REGEXP_REPLACE(h_conf_name, r'\s*Conference$', '')) AS conf_full,
    h_pf AS fouls_home,
    h_fga AS fga_home,
    h_fta AS fta_home,
    h_offensive_rebounds AS orb_home,
    h_turnovers AS to_home
  FROM
    `hca-2016-analysis.hca2016.v_games_core_box`
),
away_games AS (
  SELECT
    season_label,
    CAST(a_team_id AS STRING) AS team_id,
    a_team_name AS team_name,
    TRIM(REGEXP_REPLACE(a_conf_name, r'\s*Conference$', '')) AS conf_full,
    a_pf AS fouls_away,
    a_fga AS fga_away,
    a_fta AS fta_away,
    a_offensive_rebounds AS orb_away,
    a_turnovers AS to_away
  FROM
    `hca-2016-analysis.hca2016.v_games_core_box`
),

-- 2) Aggregate to team-season (normalize by team)
home_agg AS (
  SELECT
    season_label,
    team_id,
    ANY_VALUE(team_name) AS team_name,
    ANY_VALUE(conf_full) AS conf_full,
    COUNT(*) AS n_home,
    AVG(fouls_home) AS fouls_per_game_home,
    SUM(fta_home) AS sum_fta_home,
    SUM(fga_home) AS sum_fga_home,
    AVG(orb_home) AS avg_orb_home,
    AVG(to_home) AS avg_to_home
  FROM
    home_games
  GROUP BY
    season_label,
    team_id
),
away_agg AS (
  SELECT
    season_label,
    team_id,
    ANY_VALUE(team_name) AS team_name,
    ANY_VALUE(conf_full) AS conf_full,
    COUNT(*) AS n_away,
    AVG(fouls_away) AS fouls_per_game_away,
    SUM(fta_away) AS sum_fta_away,
    SUM(fga_away) AS sum_fga_away,
    AVG(orb_away) AS avg_orb_away,
    AVG(to_away) AS avg_to_away
  FROM
    away_games
  GROUP BY
    season_label,
    team_id
),

-- 3) Join and compute team-season gaps
team_season_gaps AS (
  SELECT
    h.season_label,
    h.team_id,
    COALESCE(h.team_name, a.team_name) AS team_name,
    COALESCE(h.conf_full, a.conf_full) AS conf_full,
    h.n_home,
    a.n_away,

    -- Fouls gap: home − road (negative = fewer fouls at home)
    (h.fouls_per_game_home - a.fouls_per_game_away) AS fouls_gap,

    -- FT rate lift (pp): (FTA/FGA)_home − (FTA/FGA)_away
    SAFE_DIVIDE(h.sum_fta_home, NULLIF(h.sum_fga_home, 0))
      - SAFE_DIVIDE(a.sum_fta_away, NULLIF(a.sum_fga_away, 0)) AS ft_rate_lift,

    -- Turnover gap: road − home (positive = fewer TOs at home)
    (a.avg_to_away - h.avg_to_home) AS to_gap,

    -- Rebound gap: home − road
    (h.avg_orb_home - a.avg_orb_away) AS reb_gap
  FROM
    home_agg AS h
    JOIN away_agg AS a
      ON h.season_label = a.season_label
     AND h.team_id = a.team_id
  WHERE
    h.n_home >= 8
    AND a.n_away >= 8
),

-- 4) Bucket conferences into tiers
bucketed AS (
  SELECT
    season_label,
    CASE
      WHEN conf_full IN ('Atlantic Coast', 'Big Ten', 'Big 12', 'Pacific 12', 'Southeastern', 'Big East')
        THEN 'Power Six'
      WHEN conf_full IN ('American Athletic', 'Mountain West', 'West Coast', 'Atlantic 10', 'Missouri Valley')
        THEN 'Mid-Majors'
      ELSE 'Other D-I'
    END AS conf_group,
    fouls_gap,
    ft_rate_lift * 100.0 AS ft_rate_pp,  -- percentage points
    to_gap,
    reb_gap
  FROM
    team_season_gaps
),

-- 5) Collapse by tier × season
tier_season_means AS (
  SELECT
    conf_group,
    season_label,
    ROUND(AVG(fouls_gap), 3) AS fouls_gap,
    ROUND(AVG(ft_rate_pp), 2) AS ft_rate_pp,
    ROUND(AVG(to_gap), 3) AS to_gap,
    ROUND(AVG(reb_gap), 3) AS reb_gap
  FROM
    bucketed
  GROUP BY
    conf_group,
    season_label
)

-- 6) Pivot to wide
SELECT
  conf_group,
  'Fouls per game (home − road)' AS channel,
  MAX(CASE WHEN season_label = '2014–15' THEN fouls_gap END) AS season_2014_15,
  MAX(CASE WHEN season_label = '2015–16' THEN fouls_gap END) AS season_2015_16,
  MAX(CASE WHEN season_label = '2016–17' THEN fouls_gap END) AS season_2016_17
FROM
  tier_season_means
GROUP BY
  conf_group

UNION ALL
SELECT
  conf_group,
  'FT rate lift (pp)' AS channel,
  MAX(CASE WHEN season_label = '2014–15' THEN ft_rate_pp END),
  MAX(CASE WHEN season_label = '2015–16' THEN ft_rate_pp END),
  MAX(CASE WHEN season_label = '2016–17' THEN ft_rate_pp END)
FROM
  tier_season_means
GROUP BY
  conf_group

UNION ALL
SELECT
  conf_group,
  'Turnovers per game (road − home)' AS channel,
  MAX(CASE WHEN season_label = '2014–15' THEN to_gap END),
  MAX(CASE WHEN season_label = '2015–16' THEN to_gap END),
  MAX(CASE WHEN season_label = '2016–17' THEN to_gap END)
FROM
  tier_season_means
GROUP BY
  conf_group

UNION ALL
SELECT
  conf_group,
  'Rebounds per game (home − road)' AS channel,
  MAX(CASE WHEN season_label = '2014–15' THEN reb_gap END),
  MAX(CASE WHEN season_label = '2015–16' THEN reb_gap END),
  MAX(CASE WHEN season_label = '2016–17' THEN reb_gap END)
FROM
  tier_season_means
GROUP BY
  conf_group
ORDER BY
  CASE conf_group WHEN 'Power Six' THEN 1 WHEN 'Mid-Majors' THEN 2 ELSE 3 END,
  channel;


-- 52b_channels_by_tier_seasons_wide_v2.sql
-- -- Purpose:
--   Single wide table of tier-level channel metrics across seasons.
--   Adds SHOOTING lifts (FG%/2P%/3P% in percentage points) and PACE gap.
--   Output: one row per (conf_group, channel) with columns for 2014–15, 2015–16, 2016–17.

CREATE OR REPLACE TABLE `hca-2016-analysis.hca2016.channels_by_tier_seasons_wide_v2` AS
WITH
-- 1) Pull home/away game-level stats, incl. normalized shooting % and box stats for pace
home_games AS (
  SELECT
    season_label,
    CAST(h_team_id AS STRING) AS team_id,
    h_team_name AS team_name,
    TRIM(REGEXP_REPLACE(h_conf_name, r'\s*Conference$', '')) AS conf_full,
    h_pf AS fouls_home,
    h_fga AS fga_home,
    h_fta AS fta_home,
    h_offensive_rebounds AS orb_home,
    h_turnovers AS to_home,
    -- normalized shooting % (0–1)
    h_fg_pct_norm AS fg_home,
    h_2p_pct_norm AS p2_home,
    h_3p_pct_norm AS p3_home
  FROM
    `hca-2016-analysis.hca2016.v_games_core_box`
),
away_games AS (
  SELECT
    season_label,
    CAST(a_team_id AS STRING) AS team_id,
    a_team_name AS team_name,
    TRIM(REGEXP_REPLACE(a_conf_name, r'\s*Conference$', '')) AS conf_full,
    a_pf AS fouls_away,
    a_fga AS fga_away,
    a_fta AS fta_away,
    a_offensive_rebounds AS orb_away,
    a_turnovers AS to_away,
    -- normalized shooting % (0–1)
    a_fg_pct_norm AS fg_away,
    a_2p_pct_norm AS p2_away,
    a_3p_pct_norm AS p3_away
  FROM
    `hca-2016-analysis.hca2016.v_games_core_box`
),

-- 2) Aggregate to team-season (normalize by team)
home_agg AS (
  SELECT
    season_label,
    team_id,
    ANY_VALUE(team_name) AS team_name,
    ANY_VALUE(conf_full) AS conf_full,
    COUNT(*) AS n_home,
    AVG(fouls_home) AS fouls_per_game_home,
    SUM(fta_home) AS sum_fta_home,
    SUM(fga_home) AS sum_fga_home,
    AVG(orb_home) AS avg_orb_home,
    AVG(to_home) AS avg_to_home,
    -- shooting (0–1)
    AVG(fg_home) AS avg_fg_home,
    AVG(p2_home) AS avg_p2_home,
    AVG(p3_home) AS avg_p3_home,
    -- possessions (per game) using 0.475 for college
    AVG(fga_home + 0.475 * fta_home - orb_home + to_home) AS poss_home
  FROM
    home_games
  GROUP BY
    season_label,
    team_id
),
away_agg AS (
  SELECT
    season_label,
    team_id,
    ANY_VALUE(team_name) AS team_name,
    ANY_VALUE(conf_full) AS conf_full,
    COUNT(*) AS n_away,
    AVG(fouls_away) AS fouls_per_game_away,
    SUM(fta_away) AS sum_fta_away,
    SUM(fga_away) AS sum_fga_away,
    AVG(orb_away) AS avg_orb_away,
    AVG(to_away) AS avg_to_away,
    -- shooting (0–1)
    AVG(fg_away) AS avg_fg_away,
    AVG(p2_away) AS avg_p2_away,
    AVG(p3_away) AS avg_p3_away,
    -- possessions (per game)
    AVG(fga_away + 0.475 * fta_away - orb_away + to_away) AS poss_away
  FROM
    away_games
  GROUP BY
    season_label,
    team_id
),

-- 3) Join and compute team-season gaps
team_season_gaps AS (
  SELECT
    h.season_label,
    h.team_id,
    COALESCE(h.team_name, a.team_name) AS team_name,
    COALESCE(h.conf_full, a.conf_full) AS conf_full,
    h.n_home,
    a.n_away,

    -- Fouls gap: home − road (negative = fewer fouls at home)
    (h.fouls_per_game_home - a.fouls_per_game_away) AS fouls_gap,

    -- FT rate lift (pp): (FTA/FGA)_home − (FTA/FGA)_away  → convert to percentage points later
    SAFE_DIVIDE(h.sum_fta_home, NULLIF(h.sum_fga_home, 0))
      - SAFE_DIVIDE(a.sum_fta_away, NULLIF(a.sum_fga_away, 0)) AS ft_rate_lift_raw,

    -- Turnover gap: road − home (positive = fewer TOs at home)
    (a.avg_to_away - h.avg_to_home) AS to_gap,

    -- Rebound gap: home − road
    (h.avg_orb_home - a.avg_orb_away) AS reb_gap,

    -- Shooting lifts (0–1); convert to pp later
    (h.avg_fg_home - a.avg_fg_away) AS fg_lift_raw,
    (h.avg_p2_home - a.avg_p2_away) AS p2_lift_raw,
    (h.avg_p3_home - a.avg_p3_away) AS p3_lift_raw,

    -- Pace gap: home − road possessions per game
    (h.poss_home - a.poss_away) AS pace_gap
  FROM
    home_agg AS h
    JOIN away_agg AS a
      ON h.season_label = a.season_label
     AND h.team_id = a.team_id
  WHERE
    h.n_home >= 8
    AND a.n_away >= 8
),

-- 4) Bucket conferences into tiers (MVC included in Mid-Majors)
bucketed AS (
  SELECT
    season_label,
    CASE
      WHEN conf_full IN ('Atlantic Coast', 'Big Ten', 'Big 12', 'Pacific 12', 'Southeastern', 'Big East')
        THEN 'Power Six'
      WHEN conf_full IN ('American Athletic', 'Mountain West', 'West Coast', 'Atlantic 10', 'Missouri Valley')
        THEN 'Mid-Majors'
      ELSE 'Other D-I'
    END AS conf_group,
    fouls_gap,
    (ft_rate_lift_raw * 100.0) AS ft_rate_pp,   -- convert to percentage points
    to_gap,
    reb_gap,
    (fg_lift_raw * 100.0) AS fg_pp,             -- pp
    (p2_lift_raw * 100.0) AS p2_pp,             -- pp
    (p3_lift_raw * 100.0) AS p3_pp,             -- pp
    pace_gap
  FROM
    team_season_gaps
),

-- 5) Collapse by tier × season
tier_season_means AS (
  SELECT
    conf_group,
    season_label,
    ROUND(AVG(fouls_gap), 2) AS fouls_gap,
    ROUND(AVG(ft_rate_pp), 2) AS ft_rate_pp,
    ROUND(AVG(to_gap), 2) AS to_gap,
    ROUND(AVG(reb_gap), 2) AS reb_gap,
    ROUND(AVG(fg_pp), 2) AS fg_pct_lift_pp,
    ROUND(AVG(p2_pp), 2) AS p2_pct_lift_pp,
    ROUND(AVG(p3_pp), 2) AS p3_pct_lift_pp,
    ROUND(AVG(pace_gap), 2) AS pace_gap
  FROM
    bucketed
  GROUP BY
    conf_group,
    season_label
)

-- 6) Pivot to wide rows per channel
SELECT
  conf_group,
  'Fouls per game (home − road)' AS channel,
  MAX(CASE WHEN season_label = '2014–15' THEN fouls_gap END) AS season_2014_15,
  MAX(CASE WHEN season_label = '2015–16' THEN fouls_gap END) AS season_2015_16,
  MAX(CASE WHEN season_label = '2016–17' THEN fouls_gap END) AS season_2016_17
FROM
  tier_season_means
GROUP BY
  conf_group

UNION ALL
SELECT
  conf_group,
  'FT rate lift (pp)' AS channel,
  MAX(CASE WHEN season_label = '2014–15' THEN ft_rate_pp END),
  MAX(CASE WHEN season_label = '2015–16' THEN ft_rate_pp END),
  MAX(CASE WHEN season_label = '2016–17' THEN ft_rate_pp END)
FROM
  tier_season_means
GROUP BY
  conf_group

UNION ALL
SELECT
  conf_group,
  'Turnovers per game (road − home)' AS channel,
  MAX(CASE WHEN season_label = '2014–15' THEN to_gap END),
  MAX(CASE WHEN season_label = '2015–16' THEN to_gap END),
  MAX(CASE WHEN season_label = '2016–17' THEN to_gap END)
FROM
  tier_season_means
GROUP BY
  conf_group

UNION ALL
SELECT
  conf_group,
  'Rebounds per game (home − road)' AS channel,
  MAX(CASE WHEN season_label = '2014–15' THEN reb_gap END),
  MAX(CASE WHEN season_label = '2015–16' THEN reb_gap END),
  MAX(CASE WHEN season_label = '2016–17' THEN reb_gap END)
FROM
  tier_season_means
GROUP BY
  conf_group

UNION ALL
SELECT
  conf_group,
  'FG% lift (pp)' AS channel,
  MAX(CASE WHEN season_label = '2014–15' THEN fg_pct_lift_pp END),
  MAX(CASE WHEN season_label = '2015–16' THEN fg_pct_lift_pp END),
  MAX(CASE WHEN season_label = '2016–17' THEN fg_pct_lift_pp END)
FROM
  tier_season_means
GROUP BY
  conf_group

UNION ALL
SELECT
  conf_group,
  '2P% lift (pp)' AS channel,
  MAX(CASE WHEN season_label = '2014–15' THEN p2_pct_lift_pp END),
  MAX(CASE WHEN season_label = '2015–16' THEN p2_pct_lift_pp END),
  MAX(CASE WHEN season_label = '2016–17' THEN p2_pct_lift_pp END)
FROM
  tier_season_means
GROUP BY
  conf_group

UNION ALL
SELECT
  conf_group,
  '3P% lift (pp)' AS channel,
  MAX(CASE WHEN season_label = '2014–15' THEN p3_pct_lift_pp END),
  MAX(CASE WHEN season_label = '2015–16' THEN p3_pct_lift_pp END),
  MAX(CASE WHEN season_label = '2016–17' THEN p3_pct_lift_pp END)
FROM
  tier_season_means
GROUP BY
  conf_group

UNION ALL
SELECT
  conf_group,
  'Pace gap (poss/game, home − road)' AS channel,
  MAX(CASE WHEN season_label = '2014–15' THEN pace_gap END),
  MAX(CASE WHEN season_label = '2015–16' THEN pace_gap END),
  MAX(CASE WHEN season_label = '2016–17' THEN pace_gap END)
FROM
  tier_season_means
GROUP BY
  conf_group
ORDER BY
  CASE conf_group WHEN 'Power Six' THEN 1 WHEN 'Mid-Majors' THEN 2 ELSE 3 END,
  channel;


-- 52c_channels_power6_long.sql
-- Purpose:
--   Reshape wide → long for Power Six only
-- Output:
--   season_label, channel, value (ready for Canva)

CREATE OR REPLACE TABLE `hca-2016-analysis.hca2016.channels_power6_long` AS
WITH power6_wide AS (
  SELECT
    *
  FROM
    `hca-2016-analysis.hca2016.channels_by_tier_seasons_wide`
  WHERE
    conf_group = 'Power Six'
),
power6_long_unpivoted AS (
  SELECT
    conf_group,
    channel,
    '2014–15' AS season_label,
    season_2014_15 AS value
  FROM
    power6_wide
  UNION ALL
  SELECT
    conf_group,
    channel,
    '2015–16' AS season_label,
    season_2015_16 AS value
  FROM
    power6_wide
  UNION ALL
  SELECT
    conf_group,
    channel,
    '2016–17' AS season_label,
    season_2016_17 AS value
  FROM
    power6_wide
)
SELECT
  conf_group,
  channel,
  season_label,
  ROUND(value, 3) AS value
FROM
  power6_long_unpivoted
ORDER BY
  channel,
  season_label;


-- 52d_power6_shooting_pace_long_from_wide_v2.sql
CREATE OR REPLACE TABLE `hca-2016-analysis.hca2016.power6_shooting_pace_long_from_wide_v2` AS
WITH p6 AS (
  SELECT
    *
  FROM
    `hca-2016-analysis.hca2016.channels_by_tier_seasons_wide_v2`
  WHERE
    conf_group = 'Power Six'
    AND channel IN (
      'FG% lift (pp)',
      '2P% lift (pp)',
      '3P% lift (pp)',
      'Pace gap (poss/game, home − road)'
    )
)
SELECT
  conf_group,
  channel,
  '2014–15' AS season_label,
  season_2014_15 AS value
FROM
  p6
UNION ALL
SELECT
  conf_group,
  channel,
  '2015–16' AS season_label,
  season_2015_16 AS value
FROM
  p6
UNION ALL
SELECT
  conf_group,
  channel,
  '2016–17' AS season_label,
  season_2016_17 AS value
FROM
  p6
ORDER BY
  channel,
  season_label;

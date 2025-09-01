-- 00a_schema.sql
-- Purpose: list all columns, types, and nullability for mbb_games_sr

SELECT
  column_name,
  data_type,
  is_nullable
FROM
  `bigquery-public-data.ncaa_basketball.INFORMATION_SCHEMA.COLUMNS`
WHERE
  table_name = 'mbb_games_sr'
ORDER BY
  ordinal_position;

-- 00b_dictionary.sql
-- Purpose: pull table description and column descriptions if provided

SELECT
  t.table_name,
  t.option_value AS table_description,
  c.column_name,
  c.data_type,
  c.description AS column_description
FROM
  `bigquery-public-data.ncaa_basketball.INFORMATION_SCHEMA.TABLE_OPTIONS` AS t
JOIN
  `bigquery-public-data.ncaa_basketball.INFORMATION_SCHEMA.COLUMN_FIELD_PATHS` AS c
  ON t.table_name = c.table_name
WHERE
  t.table_name = 'mbb_games_sr'
  AND t.option_name = 'description'
ORDER BY
  c.column_name;

-- 01_season_dates.sql
-- Purpose: confirm how the `season` number maps to actual calendar dates
-- Best practice: clear SELECT list, explicit aliases, ordered output
SELECT
  season,
  MIN(scheduled_date) AS first_game_date,
  MAX(scheduled_date) AS last_game_date,
  COUNT(*)            AS n_games
FROM 
  `bigquery-public-data.ncaa_basketball.mbb_games_sr`
WHERE 
  season IN (2015, 2016, 2017)
GROUP BY 
  season
ORDER BY 
  season;


-- 02_neutral_site_counts.sql
-- Purpose: quantify neutral vs non-neutral coverage by season (2014–2017).
-- Notes:
--   • IFNULL(neutral_site, FALSE) ensures NULLs are treated as non-neutral.
--   • This helps us see if older seasons are missing neutral flags.

WITH neutral_site_data AS (
    SELECT
        season,
        neutral_site
    FROM
        `bigquery-public-data.ncaa_basketball.mbb_games_sr`
    WHERE
        season BETWEEN 2014 AND 2017
)
SELECT
    season,
    COUNT(*) AS total_games,
    SUM(CASE WHEN neutral_site = TRUE  THEN 1 ELSE 0 END)  AS neutral_games_true,
    SUM(CASE WHEN neutral_site = FALSE THEN 1 ELSE 0 END)  AS neutral_games_false,
    SUM(CASE WHEN neutral_site IS NULL THEN 1 ELSE 0 END)  AS neutral_games_null
FROM
    neutral_site_data
GROUP BY
    season
ORDER BY
    season;

-- 03_tournament_games_counts.sql
-- Purpose: quantify how often tournament fields are populated by season (2014–2017).
-- This tells us if we can reliably exclude tournament games using games-table flags.

WITH tournament_flags AS (
    SELECT
        season,
        -- Booleans for presence of any tournament-related value
        (tournament IS NOT NULL) AS has_tournament,
        (tournament_type IS NOT NULL) AS has_tournament_type,
        (tournament_round IS NOT NULL) AS has_tournament_round,
        (tournament_game_no IS NOT NULL) AS has_tournament_game_no
    FROM
        `bigquery-public-data.ncaa_basketball.mbb_games_sr`
    WHERE
        season BETWEEN 2014 AND 2017
)
SELECT
    season,
    COUNT(*) AS total_games,
    COUNTIF( has_tournament ) AS games_with_tournament,
    COUNTIF( has_tournament_type ) AS games_with_tournament_type,
    COUNTIF( has_tournament_round ) AS games_with_tournament_round,
    COUNTIF( has_tournament_game_no ) AS games_with_tournament_game_no
FROM
    tournament_flags
GROUP BY
    season
ORDER BY
    season;


-- 09_games_core_filtered_view.sql
-- Purpose:
--   Reusable filtered view for HCA analysis (2014 pre, 2015 rule, 2016 post).
--   Excludes tournaments and neutral sites. Carries team IDs, names, and conference names.
--   Adds season_label for reporting consistency (2014–15, 2015–16, 2016–17).

CREATE OR REPLACE VIEW `hca-2016-analysis.hca2016.games_core_filtered` AS
SELECT
    -- season identifiers
    season,
    CASE season
        WHEN 2014 THEN '2014–15'
        WHEN 2015 THEN '2015–16'
        WHEN 2016 THEN '2016–17'
        ELSE CAST(season AS STRING)
    END AS season_label,

    -- final scores
    h_points AS h_pts,
    a_points AS a_pts,

    -- team identifiers & labels
    CAST(h_id AS STRING) AS h_team_id,
    CAST(a_id AS STRING) AS a_team_id,
    h_name AS h_team_name,
    a_name AS a_team_name,

    -- conference labels (needed for conference grouping)
    h_conf_name,
    a_conf_name
FROM
    `bigquery-public-data.ncaa_basketball.mbb_games_sr`
WHERE
    season IN (2014, 2015, 2016)
    AND IFNULL(neutral_site, FALSE) = FALSE
    AND NOT (
        tournament IS NOT NULL
        OR tournament_type IS NOT NULL
        OR tournament_round IS NOT NULL
        OR tournament_game_no IS NOT NULL
    );

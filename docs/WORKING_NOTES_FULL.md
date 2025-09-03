# HCA Case Study — Working Notes: The Home Court Mystery

## Setup & Sanity Checks

### Foundation Work (Queries 00-09)

**Initial Data Exploration**: Started with comprehensive schema validation (00_schema.sql) to confirm all necessary fields were available in mbb_games_sr—field goals, three-pointers, free throws, turnovers, and fouls. Dictionary check (00_dictionary.sql) confirmed we had everything needed for a complete home court advantage investigation.

**Season Boundary Discovery** (01_season_dates.sql): Found that "season 2015" actually spans November 2015 through April 2016. Made the decision to relabel all seasons as 2014-15, 2015-16, and 2016-17 in outputs to avoid confusion during presentation.

**The Neutral Site Problem** (02_neutral_counts.sql): Hit our first analytical snag—2014 and 2015 seasons had completely NULL neutral_site fields. Had to make a judgment call: treat NULLs as non-neutral games. This creates a slightly conservative bias (inflates pre-period home advantage), but sensitivity testing later confirmed this assumption was safe.

**Tournament Noise** (03_tournament_counts.sql): Discovered approximately 430 games per season flagged with tournament metadata. Decision: exclude all tournament games to focus on regular season dynamics where teams actually play at their home venues.

**Canonical Filter Creation**: Drafted 09_games_core_filtered_view.sql as our gold standard—2014-16 seasons only, no tournaments, no neutrals. This became the backbone for all subsequent analysis.

**Robustness Validation**: Tested neutral-site sensitivity using 2016-17 data (which had proper neutral flags). Including neutrals reduced home margin by only 0.4 points and team lift by 0.5 points—differences too small to change conclusions. This validated our decision to treat pre-2016 NULLs as non-neutral.

---

## Phase 1: Core Analysis - The Discovery

### The Headline Numbers (Query 10_season_pulse.sql)

**Results That Made Us Look Twice**:
- **2014-15**: Win% 66.8%, margin +11.05 points (n=5,505 games)
- **2015-16**: Win% 67.3%, margin +11.14 points (n=5,516 games)  
- **2016-17**: Win% 66.9%, margin +7.75 points (n=5,186 games)

**The Hidden Story**: Win percentages stayed flat—around 67% across all three seasons. But average margin fell by 3.4 points in 2016-17. The headline win rate was masking a fundamental weakening of home court advantage.

**Basketball Takeaway**: Road teams learned to keep games closer. Coaches can't count on "crowd-fueled runs" to stretch margins like they could pre-2016.

### The Variance Revolution (Query 11_stddev_final_margin.sql)

**Standard Deviation Results**:
- **2014-15**: σ ≈ 25.3 points, 1 point ≈ 1.6pp win probability
- **2015-16**: σ ≈ 25.9 points, 1 point ≈ 1.5pp
- **2016-17**: σ ≈ 17.4 points, 1 point ≈ 2.3pp
- **Overall dataset**: σ ≈ 23.3 points, 1 point ≈ 1.7pp

**Plain English Translation**:
- **Mean margin** = average scoreboard edge for home teams (our primary metric)
- **σ (spread of margins)** = how much game results vary around that average—think "typical swing of results"
- **Points-to-Win Translation Factor** = how much a single point is worth in win probability near even games

**The Revelation**: The drop from σ = 25 to σ = 17 meant games became dramatically tighter with fewer blowouts. Because games tightened up in 2016-17, each point of home-court edge mattered more. The ~3.7-point decline in HRE corresponded to an 8-9 percentage-point drop in win chance (versus only 5-6pp in earlier years).

### Team-Level Normalization (Query 20_team_lift.sql)

**Home-Road Edge (HRE) Results**:
- **2014-15**: +15.93 points (351 team-seasons, ~10.6k games)
- **2015-16**: +16.12 points (351 team-seasons, ~10.6k games)
- **2016-17**: +12.38 points (351 team-seasons, ~9.9k games)

**Method Explained**: For each team-season, computed average home margin (home points - away points) and average away margin (away points - home points when playing away). HRE = home margin minus away margin. Dropped teams with fewer than 8 home or 8 away games to ensure statistical reliability.

**The Pattern Emerges**: No shift in 2015-16 (the rule implementation year), then a clear decline in 2016-17 (-3.7 points, roughly 23%). The ~6% reduction in total games cannot explain this drop.

**Critical Insight**: After 2015-16, home teams still won ~67% of games, but their HRE fell sharply. The impact was delayed—flat in the rule year, then dropping in 2016-17 as the new environment fully took hold.

**Basketball Takeaway**: The comfort of home (familiar rims, routines, crowd energy) still exists, but it delivers a smaller payoff. Execution and roster quality now travel better—"where you play" matters less than "how you play."

**Reporting Framework**: 
- **HRE** = difference in margins between home and road games (our working metric)
- **HCA** (venue effect) ≈ HRE ÷ 2 (classical interpretation)
- **Presentation language**: "The Home-Road Edge dropped ~3.7 points (≈1.9-point venue effect). That translates to ~4-5 percentage points less home win chance in close games."

### Conference Heterogeneity (Query 21_conference_lift_pivot.sql)

**Mixed Signals by League**: ACC and Big Ten showed increases, Pac-12, A-10, WCC, and Mountain West declined, SEC went up then down, "Other D-I" dropped sharply. The story was noisy and non-uniform, which motivated deeper channel analysis in Phase 2.

---

## Phase 2: Channel Investigation - Hunting for the Mechanism

### The Free Throw Investigation (Query 31_ft_rate_team_lift.sql)

**Hypothesis**: Maybe home teams lost their ability to get to the line or convert free throws.

**Results**:
- **FT Rate lift (FTA/FGA)**: ~+0.05 across all three seasons—completely stable
- **FT% lift (totals method)**: ~+1 percentage point higher at home, slightly declining but stable (0.97% → 0.91% → 0.67%)
- **FT% lift (naive method)**: Appeared larger, but this was the biased version we included only to demonstrate why you don't average percentages directly

**Findings**: The home free-throw advantage (both rate and accuracy) remained rock-solid after the 2015-16 rule changes. No meaningful change in how often home teams reached the line or how well they shot once there.

**Interpretation**: The post-rule drop in HRE was not driven by free-throw dynamics. The mechanism had to be elsewhere—fouls committed, pace/variance, turnovers, or shooting percentages.

**Basketball Takeaway**: The whistle didn't change. Home teams still draw ~2 more whistles in their favor, so the drop in HCA can't be blamed on refs going neutral.

### The Officiating Deep Dive (Query 32_fouls_team_lift.sql)

**Testing the "Home Whistle" Theory**: If refs became more neutral, we'd expect the foul differential to compress.

**Results**:
- **Mean fouls gap (home - away)**: ~-1.7 fouls per game across all three seasons
- **Trend**: -1.67 (2014-15) → -1.73 (2015-16) → -1.76 (2016-17)

**The Surprise**: Home teams consistently received ~1.7 fewer foul calls than on the road, and this advantage was completely unchanged post-rule change. The "home whistle" culture survived intact.

**Combined with FT Results**: Together, these findings ruled out officiating bias as the driver of HRE decline. Refs still favored home teams with fewer fouls called and more free throw opportunities awarded.

**Basketball Takeaway**: Coaches shouldn't expect fewer fouls at home post-2016—the "home whistle" advantage persisted unchanged.

### The Shooting Comfort Test (Query 33_shooting_team_lift.sql)

**Hypothesis**: Maybe players lost their shooting comfort at home—worse sightlines, crowd pressure, something changed.

**Team-Season Normalized Results**:
- **2014-15**: FG% lift +2.9pp, 2P% lift +3.6pp, 3P% lift +1.5pp (351 team-seasons)
- **2015-16**: FG% lift +2.7pp, 2P% lift +3.6pp, 3P% lift +1.1pp
- **2016-17**: FG% lift +2.8pp, 2P% lift +3.9pp, 3P% lift +1.3pp

**The Stability**: Shooting lifts barely moved across seasons. Home teams maintained their typical basketball effect size of ~+3-4pp on two-pointers and ~+1pp on three-pointers.

**Interpretation**: The post-2016 decline in overall home edge was not explained by shooting accuracy. Players maintained the same relative shooting boost at home before and after rule changes.

**Basketball Takeaway**: Players' shooting comfort (better sightlines, crowd energy, familiar rims) remained steady. The rules didn't touch this fundamental advantage—so shooting accuracy isn't why the home bump shrank.

### Ball Security & Effort Metrics (Queries 36-39)

**Turnover Analysis** (36_turnovers_team_lift.sql + 37_turnovers_sanity_check.sql):

**Results**:
- **2014-15**: +0.72 fewer turnovers at home (351 team-seasons)
- **2015-16**: +0.63 fewer turnovers  
- **2016-17**: +0.73 fewer turnovers

**Methodological Note**: Used team-season approach rather than direct opponent comparisons to eliminate schedule bias (teams might face elite defenses on the road by coincidence). This normalization against each team's own performance is the standard method in HCA studies.

**Finding**: Teams consistently committed ~0.7 fewer turnovers at home throughout the study period. Unlike points margin (which fell ~3.7 points in 2016-17), turnover protection at home stayed constant.

**Basketball Takeaway**: Home teams still handle the ball ~0.7 turnovers better. The "home cushion" in ball security persists—but it's not enough to explain the overall decline.

**Rebounding Analysis** (39_rebounds_team_lift_summary.sql):

**Results**: Home teams actually rebounded very slightly worse than on the road (-0.09 to -0.21 rebounds per game), but gaps were negligible and showed no meaningful trends.

**Interpretation**: Rebounding doesn't explain the post-2016-17 drop in home-court edge. Useful negative finding that lets us rule this out and maintain focus on other channels.

**Basketball Takeaway**: There's no rebounding edge for home teams. Coaches can't expect the crowd to lift effort on the glass.

### The Pace Paradox (Query 41_pace_team_lift_summary.sql)

**NCAA-Adjusted Formula Results** (using 0.475 FTA factor):
- **2014-15**: +0.351 possession advantage at home
- **2015-16**: +0.392 possessions
- **2016-17**: +0.439 possessions

**The Contradiction**: Home teams consistently played faster than away teams, and this gap actually widened slightly post-rule change. With D-I games averaging ~68-71 possessions, a +0.35 to +0.44 advantage means about one extra possession at home every 2-3 games.

**The Puzzle**: Rules sped the game up overall, and home teams grabbed a slightly larger slice of that tempo boost. But this didn't increase HCA—if anything, the pace gap widened while overall HCA shrank.

**Basketball Takeaway**: Games sped up slightly, and home teams pushed tempo a bit more. But faster pace just revealed true skill more consistently, reducing the crowd/venue effect in close games.

---

## Phase 2: Channel Summary - The "Usual Suspects" All Held Firm

### What We Expected vs What We Found

**The Hypothesis**: If home edge softened, we should see cracks in the obvious places—whistles (fouls/FT rate), ball security (turnovers), effort (rebounding), or shooting comfort.

**The Shocking Results**:
- **Free throws & fouls**: No change. Home FT rate stable (~+0.05 lift), foul gap stable (~-1.7 calls per game). The "home whistle" story doesn't explain the drop.
- **Shooting percentages**: Stable. Home teams still shoot ~+3-4pp better on 2s, ~+1pp better on 3s, across all seasons. Comfort boost didn't shrink.
- **Turnovers**: Stable. Teams commit ~0.7 fewer turnovers at home. Cushion persists unchanged post-2016.
- **Rebounds**: Negligible gaps (~0), no trends across years.
- **Pace**: Actually sped up slightly; home teams got ~1 extra possession every 2-3 games versus away, but this didn't widen HCA.

### The Big Picture Paradox

**What This Means**: The home-road edge decline is not explained by classic box-score channels. All the "usual suspects" (refs, shooting, turnovers, boards) stayed steady. Only pace changed meaningfully—games sped up overall, variance compressed (σ dropped), and each possession mattered more. But faster pace didn't amplify HCA; if anything, it coincided with its shrinkage.

**The Close Game Reality**: Close-game share stayed basically flat (~25-27% across all seasons). This confirms the σ shrinkage was about fewer blowouts, not more coin-flips.

**Interpretation**: Post-2015-16 softening of HCA aligns with a structural change, not a single statistical shift. More possessions meant talent differences showed more clearly. Fewer stoppages meant refs and crowds became less influential. The σ drop created tighter games where margins mattered more—but the home side didn't scale its edge accordingly. Traditional advantages that used to tilt marginal games (whistles, stoppages, "crowd swing" moments) were diluted in the faster environment.

**Basketball Takeaway**: Coaches can't count on the old "hidden bumps" (crowd-fueled whistles, road jitters, or late-game momentum swings) to stretch margins anymore. The environment became steadier, so execution and roster quality matter more than venue.

---

## Phase 2.5: Robustness Testing - The Story Survives Every Cut

### Conference-Only Analysis (Query 42_conference_only_team_lift_summary.sql)

**The Control Test**: Restricted analysis to intra-conference games only to eliminate non-conference scheduling mismatches that might inflate home advantages.

**Results**:
- **2014-15**: +6.21 point home advantage (n=306 team-seasons, ~9H/9A each)
- **2015-16**: +6.55 points (n=315)
- **2016-17**: +5.50 points (n=316)

**Key Insight**: Conference-only games roughly halve the apparent HRE (≈6 points vs ≈12 points all-games), since non-conference mismatches do inflate the edge. But the pattern still holds—stable in 2015-16, decline in 2016-17.

**What This Proves**: The decline in home edge isn't just from non-conference blowouts. It shows up within leagues too, pointing to structural drivers (rule environment, officiating style, pace) rather than schedule quirks.

### The Conference Tier Revelation (Queries 42/43)

**The Breakdown That Changed Everything**:
- **Power Six**: 12.16 → 12.70 → 13.63 (edge actually grew)
- **Mid-Majors**: 12.78 → 10.42 → 10.22 (steady ~2.5 point decline)  
- **Other D-I**: 18.04 → 18.78 → 12.51 (flat pre-rule, then massive ~6 point drop post)

**The Plot Twist**: The national decline wasn't uniform at all. Power Six leagues held firm—if anything, strengthening their home edge. The decline came from outside the Power Six, with both Mid-Majors and especially the broad "Other D-I" bucket pulling down the national average.

**Basketball Interpretation**: The 2015-16 rules bundle acted like a system shock, but each league adapted differently depending on referees, venues, geography, and playing style:
- **ACC/AAC**: Home edge rose (fast, athletic styles benefited from quicker pace)
- **Pac-12/MWC/A-10**: Sharp declines (potential factors could include travel fatigue and grind-heavy styles being less effective under faster pace)
- **Other D-I**: Dragged national average down through sheer volume

**The MWC Case Study**: Mountain West's home edge declined sharply (10.0 → 5.9 points). Plausible factor: altitude and travel fatigue used to exaggerate home edges, but the faster pace + more possessions environment reduced the relative penalty of fatigue on visiting teams. Both sides tire more evenly now, shrinking the gap.

**Basketball Takeaway**: Don't assume "home court" means the same thing in the ACC versus MWC. Preparation and style adaptation shaped outcomes more than ever.

### Head-to-Head Validation (Query 45_paired_swaps_summary.sql)

**The Cleanest Test**: Each team faces the same opponent both home and away—pure apples-to-apples comparison.

**Results**:
- **2014-15**: +3.22 point venue effect (n=1,297 pairs; 2,597 games)
- **2015-16**: +3.03 points (n=1,299 pairs; 2,598 games)
- **2016-17**: +2.67 points (n=1,285 pairs; 2,570 games)

**Standard deviation**: ~7-7.5 points (expected noise at team-pair level)

**Confirmation**: Pattern matches all other methods—flat in 2015-16, then clear decline in 2016-17 (~0.5 points, approximately 15-20%). Sample size stayed steady, so decline isn't a sampling artifact.

**Why This Matters**: Absolute venue effect is smaller than other methods (~3 points vs ~6 conference-only vs ~12 all games) because paired swaps strip out all mismatch inflation. But even in pure head-to-head settings, the home boost shrank after 2015-16.

**Basketball Takeaway**: The "built-in bump" is softer no matter how you cut the data. The rules bundle coincided with real shifts in how games play out, even in like-for-like matchups.

### Rule Bundle Verification (Query 46_rule_bundle_scoring_pace_check.sql)

**Confirming the Rules Worked as Intended**:
- **2014-15**: 130.4 points/game, ~64 possessions/team, FG% ≈ 43.5%
- **2015-16**: 141.0 points/game, ~68 possessions, FG% ≈ 44.0%
- **2016-17**: 145.8 points/game, ~71 possessions, FG% ≈ 44.2%

**Dataset Integrity Check**: Clear jump in 2015-16—scoring +10 points, possessions +6%, field goal percentage ticked up. Gains held and even rose slightly in 2016-17. This matches NCAA commentary that the 30-second clock and freedom-of-movement rules boosted pace and offense.

**Critical Context**: While offense sped up immediately in 2015-16, the home-road edge (HRE) didn't fall until 2016-17. This suggests the drop in home advantage wasn't simply about "more possessions," but about how the new environment redistributed crowd and venue effects.

### Close Game Analysis (Query 47_close_game_share.sql)

**Results**:
- **2014-15**: ~26.6% of games within 5 points (n=5,505)
- **2015-16**: ~25.4% (n=5,516)
- **2016-17**: ~25.5% (n=5,186)

**The Flat Line**: Small dip in the rule year, then no recovery. This matches our σ finding—variance compression came from fewer extreme blowouts, not more/fewer coin-flips in the middle of the distribution.

**Basketball Takeaway**: Coaches and players can't count on the new rules creating more "one-possession finishes." What changed was the disappearance of some runaway blowouts—games stayed competitive longer, but the late-game coin-flip share stayed steady.

---

## Phase 2.5: The Power Six Discovery - Elite Programs Tell a Different Story

### Power Six Shooting & Pace Analysis

**The Hypothesis Test**: If national home-court advantage softened, maybe the big programs would show cracks in shooting comfort or tempo control.

**Shooting Results for Power Six**:
- **FG% lift**: Stayed ~+3 percentage points
- **2P% lift**: Locked at ~+4 percentage points (the classic "finish better at home" boost)
- **3P% lift**: Steady at ~+1 percentage point

**Pace Results for Power Six**:
- **Tempo gap**: Actually grew from +0.65 to +0.87 possessions per game
- **Interpretation**: Home teams widened their pace advantage rather than losing it

**The Shocker**: The usual home-court boosters in the biggest, richest, best-resourced leagues didn't decline. If anything, they held or strengthened. The national dip in HCA wasn't driven by the Power Six—it was driven outside them.

**Basketball Takeaway**: Big leagues kept their comforts—shooters still shot better, teams still ran faster at home. The refereeing quality, sightlines, and depth of resources insulated them from the national erosion.

### Conference Tier Roll-Up: The Hidden Story

**What the Tier Analysis Revealed**:
- **Power Six**: 12.16 → 12.70 → 13.63 (edge actually grew slightly)
- **Mid-Majors**: 12.78 → 10.42 → 10.22 (steady ~2.5 point decline across window)
- **Other D-I**: 18.04 → 18.78 → 12.51 (flat pre-rule, then big ~6 point drop post)

**The Meta-Discovery**: This split was the analytical unlock. It revealed the "hidden story" that a simple national average would completely miss. The national decline wasn't uniform—it was driven by volume from mid-major and lower-tier programs losing their traditional advantages.

**Basketball Interpretation**: Elite programs adapted better thanks to talent depth, travel budgets, and coaching infrastructure that insulated their home edge. Mid-majors and smaller leagues lost traditional boosts like travel fatigue effects, altitude quirks, and grind-heavy styles as pace increased.

**Business Insight**: Default home bump nationally (~2 points) masks crucial tier splits. For modeling, use stronger adjustments (~+3 points) for Power Six and weaker ones (~+1 point or less) for non-Power conferences.

---

## The Narrative Arc: Rules, Pace, and Unintended Consequences

### Cause → Mechanism → Effect

**The Policy Shift (Cause)**:
2015-16 NCAA reforms implemented 30-second shot clock, restricted arc changes, and timeout reductions. Official intent was to speed up pace, reduce stoppages, and improve game flow.

**What We Observed**:
- Games sped up significantly (64 → 71 possessions per team-game)
- Home teams maintained a small tempo advantage that actually grew slightly
- Road teams' scoring increased more than home teams' scoring (+9.3 ppg vs +6.1 ppg)
- Game variance compressed (σ dropped from ~25 to ~17 points), creating tighter contests
- Traditional home advantages (shooting, free throws, fouls) remained stable

**What We Measured (Effect)**:
- National Home-Road Edge dropped ~3.7 points (~1.9-point venue effect)
- In tight games, that's ~4-5 percentage points lower home win chance
- Not uniform: ACC/Big Ten actually rose; Pac-12/MWC fell hard; Power Six as a whole held while everyone else declined

### The Delayed Impact Mystery

**Timing Reveals the Story**: Home court advantage remained stable during the rule implementation year (2015-16) but declined sharply in 2016-17. This delay suggests teams and officials needed time to fully adapt to the new environment. The initial focus was on implementing rules correctly; the systemic effects only became apparent once the new pace and style normalized.

**Why the Delay Matters**: This wasn't an immediate mechanical effect of rule changes—it was an ecosystem adaptation. The basketball community learned to play in the new environment, and that learning process gradually eroded traditional venue advantages.

---

## Business & Basketball Implications

### For Predictive Modeling

**Tier-Specific Calibration**:
- **Power Six**: Maintain or slightly increase home court adjustments (~+3 points)
- **Mid-majors**: Reduce home adjustment to ~+1-2 points  
- **Lower-tier programs**: Minimal home adjustment (<+1 point)
- **National baseline**: Reduce default assumption from traditional ~4 points to ~2 points

### For Basketball Strategy

**Coaching Adjustments**: Can't count on venue to bail out poor execution. The environment is steadier, so preparation and roster quality matter more than ever. Traditional "hidden bumps" (crowd-fueled runs, road team jitters, late-game momentum swings) are less reliable.

**Recruiting & Development**: Elite programs with better infrastructure maintained their advantages, suggesting resource depth and player development systems travel better than venue effects in the modern game.

### The Data Analytics Perspective

**Methodological Robustness**: The finding survived multiple analytical approaches—season pulse, team normalization, conference-only cuts, head-to-head pairs. This cross-validation strengthens confidence that the decline is real, not an analytical artifact.

**Variance Analysis Innovation**: The standard deviation insights provided crucial context. The drop from σ=25 to σ=17 revealed that tighter games amplified the importance of each point while traditional venue advantages failed to scale accordingly.

**Tier-Based Modeling**: The conference breakdown demonstrates why national averages can mislead. Effective modeling requires league-specific parameters that account for resource disparities and stylistic differences.

---

## Technical Appendix

### Definitions & Metrics

**Home-Road Edge (HRE)**: Season-level average of (home margin - road margin). Measures how much stronger a team performs at home versus away.

**Home Court Advantage (HCA)**: The venue effect, approximated as HRE ÷ 2 under symmetry assumptions.

**Points-to-Win Translation**: How much one point of margin affects win probability in close games. Dataset-specific factors: ~1.5-2.3pp per point depending on season variance.

### Data Quality Assurance

**Neutral Site Sensitivity**: Including neutrals in 2016-17 reduced metrics by only 0.4-0.5 points—confirming our NULL treatment decisions were sound.

**Points Accounting**: Box-score component verification (35_boxscore_points_sanity.sql) found only handful of mismatches across thousands of games; differences were minimal and didn't affect season-level conclusions.

**Tournament Consistency**: ~430 tournament games per season across 2014-16, providing stable exclusion criteria.

### Key Decisions & Assumptions

**Scope**: Three-season window (2014-15 pre-rule, 2015-16 implementation, 2016-17 post-adaptation)
**Exclusions**: Tournament games, neutral sites, teams with <8 home or away games
**Language**: Use "coincides with" rather than "caused by" when discussing rule impacts
**Sample Sizes**: ~351 team-seasons per year, ~5,500 games per season after filters

---

## The So-What in Plain English

**Fan-Friendly Version**: Home court isn't as big a boost as it used to be. After the 2015-16 rule changes, the built-in home bump got about 2 points smaller. In tight games, that smaller bump means the home team wins roughly 4-5% less often—think one fewer home win out of every 20 toss-up games.

**Business Translation**: If you predict games or set lines, you can't give home teams quite as much credit as before. They still have an edge—just a smaller one. And it varies dramatically by conference tier.

**The Broader Lesson**: Environmental advantages don't automatically survive structural changes. Even when individual performance metrics remain stable, the overall competitive dynamic can shift due to systemic factors like pace and game flow.

**On-Air Ready**: "Home court still helps, just less. The rules made games faster and tighter, but execution carries more weight now. Don't just pencil in the home team anymore—especially outside the major conferences where the drop was sharpest."

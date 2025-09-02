**Quick links:** [One-page summary](SUMMARY.md) • [Slides (v7)](presentation/case_study_v7.pdf)

# Home Court Advantage in NCAA Basketball: The Unintended Consequence of Rule Changes

A comprehensive analysis examining how NCAA rule changes in 2015-16 coincided with unexpected shifts in home court advantage across Division I men's basketball.

## The Discovery

While NCAA rule changes successfully sped up college basketball (30-second shot clock, restricted arc expansion, timeout reductions), they came with an unintended consequence: **home court advantage quietly eroded by approximately 23%** outside the major conferences.

## Key Findings

- **National Decline**: Home-Road Edge (HRE) dropped from ~16 points to ~12 points (2014-15 to 2016-17)
- **Delayed Effect**: Advantage remained stable during rule implementation year (2015-16), then declined sharply in 2016-17
- **Tier-Specific Impact**: 
  - **Power Six conferences**: Advantage actually increased slightly (12.2 → 13.6 points)
  - **Mid-majors & Other D-I**: Significant erosion (12.8 → 10.2 and 18.0 → 12.5 points respectively)
- **Variance Compression**: Games tightened overall (fewer blowouts), making each point of margin more valuable

## The Detective Work

Systematic investigation ruled out traditional explanations:
- **Officiating**: Free throw rates and foul differentials unchanged
- **Shooting**: Home shooting advantages remained constant (~3-4pp on 2-pointers)
- **Effort Metrics**: Turnover and rebounding edges held steady
- **Pace**: Home tempo advantage actually increased slightly

**The Mechanism**: Road teams caught up offensively. While both home and away scoring increased post-rule changes, road teams gained more (+9.3 ppg vs +6.1 ppg), narrowing the traditional gap.

## Methodology

- **Scope**: 2014-17 Division I men's basketball (3-season window: pre/during/post rule changes)
- **Data**: ~5,500 games per season, 351 team-seasons annually
- **Exclusions**: Tournament games, neutral sites
- **Normalization**: Team-season level analysis (≥8 home & ≥8 road games)
- **Robustness**: Multiple analytical approaches (season pulse, paired swaps, conference-only cuts)

## Business Applications

### Modeling & Predictions
- Reduce default home court parameters nationally
- Implement tier-specific adjustments (Power Six vs others)
- Monitor free throw and foul gaps as early indicators

### Strategic Insights
- Home advantage more fragile in faster-paced environments
- Elite programs with superior resources maintain venue effects
- Traditional "cushion" effects diminished outside major conferences

## Technical Implementation

**Primary Metric**: Home-Road Edge (HRE) = avg home margin - avg road margin  
**Venue Effect**: ≈ HRE ÷ 2 (classical interpretation)  
**Win Probability Impact**: ~1.7 percentage points per point of margin  

**Key Insight**: Environmental advantages don't automatically survive structural changes. Even when individual performance metrics remain stable, overall competitive dynamics can shift due to systemic factors.

## Repository Structure

```
/sql/           # all queries (setup, season pulse, team HRE, channels, tiers, swaps)
/slides/        # final deck (PDF)
/README.md      # this file
/SUMMARY.md     # 1-page recap (executive view)
```

## What's Next

- **Validation**: Extend analysis to additional seasons
- **Deep Dive**: Shot profiles, possession types, officiating patterns
- **Ground Truth**: Film analysis to connect data insights to game reality
- **Operational**: Real-time monitoring dashboard for ongoing trends

---

*This analysis demonstrates how rule changes designed to improve game flow had unintended consequences on competitive balance, providing actionable insights for sports analytics, modeling, and strategic decision-making.*

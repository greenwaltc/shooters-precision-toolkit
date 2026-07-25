# Bramwell’s Precision Test Kit: Software Instructions

## Overview

Bramwell’s Precision Test Kit is designed to compare firearm (or other projectile) shot consistency. It allows you to compare the precision of different factors, such as cartridge designs, shooting stances, etc. For efficiency, you can test up to four different factors simultaneously without increasing the required sample size.

## Key Concepts

**Two-Shot Groups:** This analysis is based on the average distance between shots in two-shot groups. This is a very natural way to think of variation, since it tells how far apart, on average, two shots will be. Unlike methods such as group size, mean radius, and Circle Error Probable, this method tells you how many samples you need to detect a chosen difference, plus it gives you an alpha risk and allows the economical simultaneous testing of multiple factors.

**Factors and States:** A [factor](https://statisticsbyjim.com/glossary/factors/) is a variable that may influence your outcome (e.g., shooting stance). Each factor can have two **states** (e.g., Weaver vs. isosceles stance). If you are testing cartridge recipes, you can simultaneously test bullet type, powder charge, primer type, and bullet seating depth, for example.

**Alpha (𝛂) Risk:** This represents the risk that the test indicates a difference when none exists. While 5% is standard for magnitude tests, 10% is generally more practical for variation tests, which require larger samples.

**Minimum Detectable Difference:** Detecting small differences in variation requires large samples. As a general rule, it is necessary to quadruple the sample size to cut the minimum detectable difference in half, so tests of variation often target a detection threshold of approximately ±25% to ±30%. Each sample-size option on the setup form shows the difference it can detect at your chosen risk level.

**Sample Size:** The requirement for large sample sizes is not a failure of the analytical technique. Rather, it reflects the nature of all tests of variation. You are not likely to get a better result with fewer data by any other method.

## Running the Test

1. **Setup:** On the opening screen, enter your **Project Name**, choose the structure of your experiment (the number of factors), then name each factor and its two states.
2. **Configuration:** Select your preferred 𝛂 risk and the sample size appropriate for your required test resolution.
3. **Submission:** Click **Submit** to generate the data matrix.
4. **Data Input:** Enter your two-shot group sizes into the **Group Size** column. For tests of multiple factors, shoot groups according to the combinations of factor states in the left columns. You must pair Shot 1 with Shot 2, then Shot 3 with Shot 4, and so on. Do not pair Shot 2 with Shot 3, as the pairs must be independent.
5. **Results:** Once entries are complete, click **Show Results**.
   - The resulting chart displays a centerline with upper and lower decision limits.
   - If the average for a state falls outside these limits, that state is statistically different from the overall average at your chosen level of risk.
   - Use **Export** to save the results as a PNG, JPEG, or PDF (optionally including the data matrix).

## Data Entry Tips

- Values can be entered as decimals or fractions — typing `1/4` records `0.25`.
- Enter and Tab advance to the next cell, spreadsheet-style, and Cmd/Ctrl+Z undoes changes.
- Switch on **Randomize order?** to shuffle the shooting sequence, which guards against drift (barrel heating, fatigue, changing light) biasing one factor state.
- **Clear All Group Sizes** erases every entry if you need to start the data over.
- Your project saves automatically, so you can leave the app mid-test and pick up where you left off.

**Pro-tip:** To establish a reliable basis for comparison, shoot a set of two-shot groups with a setup you already prefer.

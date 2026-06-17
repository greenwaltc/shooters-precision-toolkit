# Software instructions


Bramwell’s Precision Test Kit is a simple way to test firearm shot consistency.  You can test the variation of one cartridge design vs. another, or one shooting stance vs. another, or any other comparison of shot placement consistency that you want to make.  For economy, you can test up to four different factors at once with no increase in required sample size.

This test is based on the average of many two-shot groups.  This is called the mean range, which is a very intuitive measure of shot dispersion.  It tells how far apart, on average, two shots will be.  The data input column of the software is labelled RANGES.  That is where you should enter the size of each of your two-shot groups, one group per cell. 

Measures of variation (as opposed to magnitudes such as length, pressure, and speed) are slippery devils that do not like to be cornered and made to tell the truth.  Accordingly, tests of variation or dispersion tend to require large samples.  This is not a shortcoming of the analysis method.  Rather, it is the effect of the innate information content of measures of variation.  You are not likely to get a better answer from fewer data by any other method.

Any test that is based on a sample will have some risk associated with it.  One of the main risks is that the test will say that a real difference exists, when actually none does.  This is called 𝛂 (alpha) risk.  For tests of magnitude, 5% is a common choice.  However, since tests of variation tend to require larger samples, 10% 𝛂 risk is usually the more practical choice.

Increasing sample size improves your ability to detect small differences in variation.  However, as a general rule, it is necessary to quadruple sample size to decrease the minimum detectable difference by half.   So most variation testers will settle for detecting differences on the order of 25%. 

A [__factor__](https://statisticsbyjim.com/glossary/factors/) is something that might influence the outcome.  Factors are allowed to have two __states__.  So you might be concerned about a factor such as shooting stance.  Two states might be Weaver and isosceles.  Or, if you are developing a new load, the factors might be bullet type, charge weight, and seating depth, with states monometal and lead core, 90% and 100%, and .030” or .050” off the lands, respectively.

You can test up to four factors at once with no increase in required sample size.  So you can test states sling vs. none, both eyes vs. one eye, trigger at the finger pad vs. trigger at the joint crease, and bipod vs. bench rest, and get answers for all four factors for the same price as testing one factor. 

At the opening screen, enter your PROJECT NAME, your number of factors, name your FACTOR(s), and the two states of each factor.  Choose your 𝛂 risk and the sample size that provides the appropriate level of test resolution.  Then click SUBMIT.  A data matrix will then appear.  Shoot the appropriate two-shot groups and enter the size of the groups in the RANGES column.  Note: You can pair shot 1 and shot 2, then shot 3 and shot 4.  You cannot pair shot 2 and shot 3.  The pairs must be independent.

When all the ranges have been entered, click SHOW RESULTS.  You’ll see a chart with a centerline and upper and lower decision limits.  If the average of a state is outside the decision limit, it is different from the average of all the data at your chosen level of risk or better. 

If you have a setup that you already like, it is a good idea to shoot a set of ranges with it, so you have a basis for comparison. 


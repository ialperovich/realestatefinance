#############
# Topic 1 Companion R Code
# Introduction to Causality and Randomization
#############

# Libraries
library(lfe); library(dplyr); library(magrittr)

## ESTIMATING AN ATE ##
set.seed(123) # Set seed for replication
N <- 100000 # Number of observations

# Create potential outcomes dataset
## Outcome if not treated Y(0). Assume a 20% probability of success
## (experience economic mobility)
Y0 <- rbinom(N, 1, 0.2)
## Outcome if treated Y(1). Assume a 25% probability of success
## (experience economic mobility)
Y1 <- rbinom(N, 1, 0.25)
## Assume a 50% probability of being in the treatment group
## (moved to high opportunity area)
D <- rbinom(N, 1, 0.5)
## Construct the observed outcome based on treatment status
Y <- ifelse(D == 1, Y1, Y0)

# Combine two observed variables to create dataset
dataset <- data.frame(Y, D)

# "True" ATE is E[Y1] - E[Y0] = 0.25 - 0.2 = 0.05

# Estimate ATE
estimation <- felm(Y ~ D, data = dataset)
summary(estimation)
## OLS estimate of ATE should be close to 0.05

# Display the estimated Average Treatment Effect (ATE)
ate_estimate <- coef(estimation)["D"]
ate_estimate ## ATE estimate should be close to 0.05

# Create selection bias by making treatment
# more likely for those with higher Y(0)
# i.e. people that choose to move to high opportunity areas
# are more likely to have higher economic mobility even without treatment
## Outcome if not had been treated Y_0 conditional on being treated D=1
## Assume a 22% probability of success
## (experience economic mobility) for those treated D=1 had they
## not been treated
Y0_condD1 <- rbinom(N, 1, 0.22)
## Condition higher success rate in treatment group even had not been treated
Y0_dependingonD <- ifelse(D == 1, Y0_condD1, Y0)
## Combine two observed variables and one unobserved to create dataset
dataset_withbias <- data.frame(Y, D, Y0_dependingonD)

# Estimate biased OLS
estimation <- felm(Y ~ D, data = dataset_withbias)
summary(estimation)
## OLS estimate should be close to 0.05
## Display the biased difference-in-means estimate
biased_estimate <- coef(estimation)["D"]
biased_estimate ## Biased estimate should be close to 0.05
## Biased in this case since difference-in-means is
### ATT + selection bias
EY0_conditional_D1 <- dataset_withbias %>% filter(D==1) %>%
  summarise(mean_value = mean(Y0_condD1, na.rm = TRUE)) %>%
  pull(mean_value)
EY0_conditional_D1

EY1_conditional_D1 <- dataset_withbias %>% filter(D==1) %>%
  summarise(mean_value = mean(Y, na.rm = TRUE)) %>%
  pull(mean_value)
EY1_conditional_D1
ATT <- EY1_conditional_D1 - EY0_conditional_D1
ATT

EY0_conditional_D0 <- dataset_withbias %>% filter(D==0) %>%
  summarise(mean_value = mean(Y, na.rm = TRUE)) %>%
  pull(mean_value)
EY0_conditional_D0

selection_bias <- EY0_conditional_D1 - EY0_conditional_D0
selection_bias

# Verify that biased estimate = ATT + selection bias
biased_estimate
ATT + selection_bias

# Check if the biased estimate equals ATT + selection bias
stopifnot(all.equal(unname(biased_estimate), unname(ATT + selection_bias), tolerance = 1e-5))
## Results have bias because we do not have randomization
## OLS estimates difference-in-means but combination of ATT
## and selection bias in this case
## Could separate if we observed EY0_conditional_D1 but 
## we do not unless we have randomization
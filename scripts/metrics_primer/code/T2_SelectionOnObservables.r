#############
# Topic 2 Companion R Code
# Selection on Observables
#############

# Libraries
library(lfe); library(dplyr); library(magrittr)

# Set a seed for reproducibility
set.seed(42)

# Set the number of observations
n <- 1000

# Generate data
W1 <- rnorm(n) # Confounder 1 such as property size
W2 <- rnorm(n) # Confounder 2 such as property age
# Error term for regression of treatment (think lease maturity) on confounders
epsilon <- rnorm(n)
# Error term for regression of outcome (house price) 
# on treatment and confounders
nu <- rnorm(n)

# Simulate treatment and outcome
# Want to recover the coefficient on X (treatment)
# and interpret it based on Frisch-Waugh breakdown

# There is a relation between X and W1, W2
# In our Real Estate example, lease maturity (X) is
# related to property size (W1) and age (W2)
X <- 3 + 10 * W1 + 13 * W2 + epsilon

# Y is related to X, W1, and W2, what does the 4 mean
# according Frisch-Waugh?
Y <- 11 + 4 * X + 25 * W1 + 15 * W2 + nu

# Store variables in a data frame
df <- data.frame(Y, X, W1, W2)

### Regression Anatomy ###
# Long model
long_model <- felm(Y ~ X + W1 + W2, data = df)
print("--- Long Model: Y ~ X + W1 + W2 ---")
print(summary(long_model))

# A long model (usually reported in research)
# can be hard to interpret at a glance
# Regression anatomy helps with this.

# Regress X on W1 and W2 and predict residuals
aux_model_12 <- felm(X ~ W1 + W2, data = df)
# Get X residuals after removing variation explained by W1 and W2
# Obtain lease maturity (X) variation orthogonal
# to property size (W1) and age (W2)
df$uhat12 <- residuals(aux_model_12)

# Run bivariate regression (short model) of Y on X but where X is variation
# orthogonal to W1 and W2 (the other confounders in the long model)
model_uhat12 <- felm(Y ~ uhat12, data = df)
print("--- Model: Y ~ uhat12 (Residuals of X ~ W1 + W2) ---")
print(summary(model_uhat12))

# The coefficient on uhat12 (X removing variation explained by W1 and W2)
# in this short model is identical
# to the coefficient on X in the long model
print("Coefficient on X in long model:")
print(coef(long_model)["X"])
print("Coefficient on uhat12 in short model:")
print(coef(model_uhat12)["uhat12"])

# Short model shows more clearly the interpretation of the coefficient
# on X in the long model
# The coefficient on X represents the (closer to causal) effect
# of lease maturity on house price (Y) because it is X (lease maturity)
# after removing variation in it explained by
# confounders W1 and W2 (property size and age)

# This is the Frisch-Waugh theorem in action!

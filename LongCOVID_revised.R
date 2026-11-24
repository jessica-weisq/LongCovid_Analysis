
react <- readRDS("react_lc_2026.rds")

# Duplicate IDs and extreme ages are kept on purpose: the synthetic sample
# is designed to represent the population. Only exclusion is missing data.

n0 <- nrow(react)                                         # start, 10,000
d  <- subset(react, U_AGE >= 18)                          # inclusion · adults only

# Codebook items (all coded 0 = no, 1 = yes)
hcw_vars  <- c("WORKTYP1_1",    # healthcare worker, direct patient contact
               "WORKTYP1_3")    # care home worker, direct client contact
cond_vars <- c("HEALTHA_2",     # diabetes
               "HEALTHA_3",     # heart disease
               "HEALTHA_4",     # hypertension
               "HEALTHA_10",    # asthma
               "HEALTHA_15",    # depression
               "HEALTHA_16")    # anxiety

# Special codes (-77, -91, -92) and impossible negatives become NA
use_vars <- c("CONTACT1", "COVIDA", "LONGCOVID1", "U_GENDER", "IMD_DECILE",
              hcw_vars, cond_vars)
d[use_vars] <- lapply(d[use_vars], function(x) { x[x < 0] <- NA; x })


# Outcome · Long COVID among all adults
#   COVIDA is asked first; LONGCOVID1 is asked only if COVIDA = 1-3
#   1  = previous COVID (COVIDA 1-3) and ongoing symptoms (LONGCOVID1 1-2)
#   0  = no previous COVID (COVIDA 4), or previous COVID and recovered (LONGCOVID1 3-4)
#   NA = COVIDA missing, or LONGCOVID1 code 5 / missing after previous COVID
d$longcovid <- NA
d$longcovid[d$COVIDA == 4] <- 0
d$longcovid[d$COVIDA %in% 1:3 & d$LONGCOVID1 %in% 3:4] <- 0
d$longcovid[d$COVIDA %in% 1:3 & d$LONGCOVID1 %in% 1:2] <- 1

# Exposure · contacts outside the household yesterday
# Cut points chosen from the distribution (median 1, heavy right skew)
# to give reasonably sized groups; reference = 0 contacts
d$contact_cat <- cut(d$CONTACT1, breaks = c(-Inf, 0, 2, 5, 10, Inf),
                     labels = c("0", "1-2", "3-5", "6-10", "11+"))

# Confounders (chosen a priori from the DAG)
d$age_group <- cut(d$U_AGE, breaks = c(17, 34, 49, 64, Inf),
                   labels = c("18-34", "35-49", "50-64", "65+"))

d$gender <- factor(d$U_GENDER, levels = c(1, 2),
                   labels = c("Male", "Female"))          # code 9 becomes NA

d$imd_q <- cut(d$IMD_DECILE, breaks = c(0, 2, 4, 6, 8, 10),
               labels = c("1 most deprived", "2", "3", "4", "5 least deprived"))

# Patient or client facing health/care worker
d$hcw <- factor(ifelse(apply(d[hcw_vars] == 1, 1, any), "Yes", "No"),
                levels = c("No", "Yes"))

# Any pre-existing condition
#   Yes = any item answered yes
#   No  = no item yes, and at least one item answered
#   NA  = no item answered
cond_answered <- rowSums(sapply(d[cond_vars], function(x) x %in% c(0, 1)))
cond_yes      <- rowSums(sapply(d[cond_vars], function(x) x %in% 1))
d$any_cond <- factor(ifelse(cond_yes > 0, "Yes",
                            ifelse(cond_answered >= 1, "No", NA)),
                     levels = c("No", "Yes"))

# Checking each recode
table(d$COVIDA, d$longcovid, useNA = "ifany")
table(d$contact_cat, useNA = "ifany")
table(d$age_group, useNA = "ifany")
table(d$gender, useNA = "ifany")
table(d$imd_q, useNA = "ifany")
table(d$hcw, useNA = "ifany")
table(d$any_cond, useNA = "ifany")


# Complete case on outcome, exposure and confounders, in this order

core_vars <- c("longcovid", "contact_cat", "age_group", "gender", "imd_q", "hcw", "any_cond")

step1 <- d[!is.na(d$longcovid), ]                         # missing outcome removed
step2 <- step1[!is.na(step1$contact_cat), ]               # missing contacts removed
dat   <- step2[complete.cases(step2[, core_vars]), ]      # missing confounders removed

flow <- c(start                = n0,
          adults               = nrow(d),
          excl_covid_history   = sum(is.na(d$COVIDA)),
          excl_longcovid1      = sum(!is.na(d$COVIDA) & is.na(d$longcovid)),
          excl_contacts        = nrow(step1) - nrow(step2),
          excl_confounders     = nrow(step2) - nrow(dat),
          analytic_sample      = nrow(dat))
flow                                                      # numbers for the flowchart
sum(dat$longcovid)                                        # Long COVID cases


# TABLE 1 · CHARACTERISTICS AND % WITH LONG COVID (covers Aim 2)

# Helper · % with 95% CI from prop.test (Wilson interval)
prop_ci <- function(x) {
  pt <- prop.test(sum(x), length(x), correct = FALSE)
  sprintf("%.1f (%.1f to %.1f)", 100 * pt$estimate,
          100 * pt$conf.int[1], 100 * pt$conf.int[2])
}

table1_vars <- c("age_group", "gender", "imd_q", "contact_cat", "hcw", "any_cond")
table1 <- do.call(rbind, lapply(table1_vars, function(v) {
  lv <- levels(dat[[v]])
  n  <- as.vector(table(dat[[v]]))
  data.frame(variable        = v,
             group           = lv,
             n               = n,
             pct_of_sample   = round(100 * n / nrow(dat), 1),
             longcovid_n     = as.vector(tapply(dat$longcovid, dat[[v]], sum)),
             longcovid_pct   = sapply(lv, function(l) prop_ci(dat$longcovid[dat[[v]] == l])),
             row.names = NULL)
}))
table1


# AIM 1 · DEFINE AND DESCRIBE THE OVERALL LEVEL OF LONG COVID

prop_ci(dat$longcovid)                                    # % of all adults (95% CI)
prop_ci(dat$longcovid[dat$COVIDA %in% 1:3])               # % of those with previous COVID


# AIM 2 · DIFFERENCES BY AGE, DEPRIVATION AND GENDER
# Use the age_group, gender and imd_q rows of Table 1:
# % with Long COVID (95% CI) in each group.
# Adjusted ORs for these variables are available from the full model below.


# AIM 3 · CONTACTS AND LONG COVID

# Helpers
contact_or <- function(f) {                               # contact rows only
  rows <- grep("contact_cat", names(coef(f)))
  exp(cbind(OR = coef(f), confint.default(f)))[rows, , drop = FALSE]
}
fmt <- function(m) sprintf("%.2f (%.2f to %.2f)", m[, 1], m[, 2], m[, 3])

# MODEL 1 · crude
fit_crude <- glm(longcovid ~ contact_cat,
                 family = binomial(link = logit), data = dat)

# MODEL 2 · fully adjusted (the inferential model)
fit_adj <- glm(longcovid ~ contact_cat + age_group + gender + imd_q + hcw + any_cond,
               family = binomial(link = logit), data = dat)

# Results table · reference category shown, no p values
results <- data.frame(
  contacts = levels(dat$contact_cat),
  n        = as.vector(table(dat$contact_cat)),
  cases    = as.vector(tapply(dat$longcovid, dat$contact_cat, sum)),
  crude    = c("1 (ref)", fmt(contact_or(fit_crude))),
  adjusted = c("1 (ref)", fmt(contact_or(fit_adj))))
results

# Aim 2 · adjusted ORs for age, gender and IMD from the same full model
adj_all <- exp(cbind(OR = coef(fit_adj), confint.default(fit_adj)))
round(adj_all[grep("age_group|gender|imd_q", rownames(adj_all)), ], 2)

# Magnitude · predicted % with Long COVID for a typical person, varying contacts only
newd <- data.frame(contact_cat = levels(dat$contact_cat),
                   age_group = "35-49", gender = "Female", imd_q = "3",
                   hcw = "No", any_cond = "No")
data.frame(contacts = newd$contact_cat,
           predicted_pct = round(100 * predict(fit_adj, newdata = newd, type = "response"), 1))


# SENSITIVITY ANALYSIS · AIM 3
# MODEL 3 · fully adjusted model restricted to adults who reported previous COVID.
# Asks whether contacts are associated with Long COVID beyond the risk of
# catching COVID in the first place.

dat_sens <- subset(dat, COVIDA %in% 1:3)
fit_sens <- update(fit_adj, data = dat_sens)

sens <- data.frame(
  contacts            = levels(dat$contact_cat),
  main_adjusted       = c("1 (ref)", fmt(contact_or(fit_adj))),
  previous_covid_only = c("1 (ref)", fmt(contact_or(fit_sens))))
sens
c(main = nrow(dat), sensitivity = nrow(dat_sens))         # n for each model


# FIGURE · FOREST PLOT OF CONTACT ORs (base R), reference shown

lev   <- levels(dat$contact_cat)
k     <- length(lev)
y     <- k:1                                    # reference at the top
yy    <- y[-1]                                  # rows for non-reference groups
or_c  <- contact_or(fit_crude)
or_a  <- contact_or(fit_adj)
col_c <- "grey55"; col_a <- "navy"

png("forest_contacts.png", width = 12, height = 6.75, units = "in", res = 300)
par(mar = c(5, 8, 4, 12), cex = 1.6)            # wide right margin for the OR labels

plot(NA, log = "x", xlim = range(c(or_c, or_a, 1)), ylim = c(0.5, k + 0.5),
     yaxt = "n", xlab = "Odds ratio of Long COVID (log scale)", ylab = "")
abline(v = 1, lty = 2)

points(1, y[1], pch = 15, cex = 1.3)                                     # reference
segments(or_c[, 2], yy + 0.15, or_c[, 3], yy + 0.15, col = col_c, lwd = 3)
points(or_c[, 1], yy + 0.15, pch = 19, cex = 1.3, col = col_c)           # crude
segments(or_a[, 2], yy - 0.15, or_a[, 3], yy - 0.15, col = col_a, lwd = 3)
points(or_a[, 1], yy - 0.15, pch = 19, cex = 1.3, col = col_a)           # adjusted

axis(2, at = y, labels = lev, las = 1)
mtext("Contacts yesterday", side = 2, line = 4.5, cex = 1.6)

mtext("1 (reference)", side = 4, at = y[1], las = 1, line = 1, cex = 1.3)
mtext(fmt(or_c), side = 4, at = yy + 0.15, las = 1, line = 1, col = col_c, cex = 1.3)
mtext(fmt(or_a), side = 4, at = yy - 0.15, las = 1, line = 1, col = col_a, cex = 1.3)

legend("top", inset = c(0, -0.14), xpd = TRUE, horiz = TRUE, bty = "n",
       legend = c("Crude", "Adjusted"), col = c(col_c, col_a), pch = 19, lwd = 3)

dev.off()


# ASSUMPTION CHECKS 
# Independent observations · by design (one record per participant)
# Linearity in the log odds · not needed, all predictors are categorical

table(dat$contact_cat, dat$longcovid)                     # events in every contact group
sum(dat$longcovid) / (length(coef(fit_adj)) - 1)          # events per parameter (want > 10)
car::vif(fit_adj)                                         # multicollinearity, GVIF^(1/(2*Df))
# Long Covid Analysis

## Introduction to Long COVID and Risk Factors

- While most individuals recover from COVID-19 within days, others experience Long COVID, defined as symptoms persisting for more than four weeks beyond the acute phase1.

- Some people develop Long COVID with persistent multi-system complications that present a substantial public health burden in England1.

- Some risk factors for Long COVID have been identified, including pre-existing comorbidities and female sex1,2. However, whether reinfection and recurrent viral exposure increase the risk remains inconsistent2,3.

- More contacts may lead to more exposures4, reinfections, or higher viral burden, plausibly raising Long COVID risk.

- The influence of contact numbers on Long COVID has rarely been studied


## Study Aims

1. Conduct an exploratory analysis on the overall level of Long COVID in England
2. Identify the demographic differences in Long COVID by key populations.
3. Investigate the association between the number of people contacted and the odds of reporting Long COVID

## Methodology

<img width="884" height="455" alt="Screenshot 2026-11-24 at 20 14 57" src="https://github.com/user-attachments/assets/09bc12a8-3807-4a24-8039-c9987452000d" />

- A cross-sectional secondary analysis was conducted using a simulated REACT dataset comprising 10,000 participant records, generated from the joint distribution of REACT-1 and REACT-2 survey responses in England

- Data cleaning and preprocessing: Adults aged 18 years or above were included. Invalid response codes were recoded as missing values, and participants with missing COVID history, Long COVID status, social contact frequency or relevant covariates were excluded through complete-case analysis. Feature engineering was performed to derive binary Long COVID status, categorise social contact frequency and age, construct socioeconomic deprivation quintiles, and consolidate occupational and pre-existing health condition variables. The final analytical cohort comprised 5,659 adults, including 562 Long COVID cases.

- Modelling and statistical analysis: Statistical analysis was conducted in R. Prevalence estimates were calculated with Wilson 95% confidence intervals, alongside chi-square tests for subgroup comparisons. Crude and multivariable logistic regression models (GLMs with a binomial distribution and logit link) were fitted, with confounders selected using a directed acyclic graph (DAG). Associations were quantified using adjusted odds ratios and 95% confidence intervals, with likelihood ratio tests for hypothesis testing.

- Model diagnostics and sensitivity analysis: Model adequacy was assessed using variance inflation factors (VIFs) for multicollinearity and events per parameter. Three sensitivity analyses were conducted to evaluate robustness: restricting the cohort to previously infected individuals, redefining the outcome as current Long COVID, and modelling social contact frequency as a log-transformed continuous variable.

## Results

<img width="883" height="504" alt="Screenshot 2026-11-24 at 20 13 31" src="https://github.com/user-attachments/assets/024512d7-779d-4511-969f-38cf6f2fedd4" />

<img width="883" height="498" alt="Screenshot 2026-11-24 at 20 13 38" src="https://github.com/user-attachments/assets/7ac76a33-6c1a-46ad-b261-4128ff52b9ec" />

<img width="882" height="499" alt="Screenshot 2026-11-24 at 20 14 01" src="https://github.com/user-attachments/assets/2a6dcc40-8da0-4df2-bc85-3c71c945b92b" />

<img width="882" height="498" alt="Screenshot 2026-11-24 at 20 14 25" src="https://github.com/user-attachments/assets/a4df29f9-8b3d-4296-8b46-a6ba04b2ebbd" />

<img width="880" height="498" alt="Screenshot 2026-11-24 at 20 14 33" src="https://github.com/user-attachments/assets/b9de1939-41cd-45fc-8b6f-7f84e7d2d844" />


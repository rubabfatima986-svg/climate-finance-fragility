# ============================================================
# PROJECT: Do Fragile States Receive Less Climate Aid?
# Author: Rubab Fatima
# Date: 2026
# 
# Panel: 2010-2023 | ~180 countries
# ============================================================

# STEP 1 - Load libraries
library(tidyverse)
library(readxl)
library(WDI)
library(plm)
library(did)

# ============================================================
# STEP 2 - Load FSI Data
# ============================================================
fsi_files <- list.files(
  path = "C:/Users/user/OneDrive/Desktop/FSI_data",
  pattern = "*.xlsx",
  full.names = TRUE
)

# Read one file first to check structure
test <- read_excel(fsi_files[1])
print(colnames(test))
print(head(test))

# Remove everything except test
rm(fsi_data, fsi_files, wdi_data)

# Check what remains
ls()

# Rename test 
fsi <- test

# Remove test
rm(test)
rm(fsi_2010)
# Check
ls()

colnames(fsi)
head(fsi)

# Load all FSI files and fix year
fsi_files <- list.files(
  path = "C:/Users/user/OneDrive/Desktop/FSI_data",
  pattern = "*.xlsx",
  full.names = TRUE
)

fsi_all <- map_df(fsi_files, ~{
  df <- read_excel(.x)
  df <- df %>%
    mutate(Year = as.integer(format(as.POSIXct(Year, 
                                               origin = "1970-01-01", 
                                               tz = "UTC"), "%Y")))
  return(df)
})

# Check
dim(fsi_all)
table(fsi_all$Year)

# Install missing package
install.packages("did")

# Reload FSI with proper year fix
fsi_all <- map_df(fsi_files, ~{
  df <- read_excel(.x)
  df <- df %>%
    mutate(Year = case_when(
      is.numeric(Year) ~ as.integer(Year),
      TRUE ~ as.integer(format(as.POSIXct(
        as.numeric(Year), 
        origin = "1970-01-01", 
        tz = "UTC"), "%Y"))
    ))
  return(df)
})

# Check
table(fsi_all$Year)

# Load WDI from Desktop
wdi_data <- read_excel(
  "C:/Users/user/OneDrive/Desktop/WDI/P_Data_Extract_From_World_Development_Indicators.xlsx",
  sheet = 1
)

# Check
dim(wdi_data)
colnames(wdi_data)

# Clean and reshape WDI data
wdi_clean <- wdi_data %>%
  # Remove last few rows which are notes
  filter(!is.na(`Country Code`)) %>%
  # Pivot from wide to long
  pivot_longer(
    cols = starts_with("20"),
    names_to = "Year",
    values_to = "Value"
  ) %>%
  # Clean year column
  mutate(Year = as.integer(substr(Year, 1, 4))) %>%
  # Pivot series to columns
  pivot_wider(
    names_from = `Series Name`,
    values_from = Value
  ) %>%
  # Rename columns
  rename(
    country = `Country Name`,
    iso3c = `Country Code`
  ) %>%
  # Clean up
  select(-`Series Code`)

# Check
dim(wdi_clean)
colnames(wdi_clean)
head(wdi_clean)

# Clean WDI - rename columns and fix types
wdi_clean <- wdi_clean %>%
  rename(
    gdp_pc = `GDP per capita (current US$)`,
    population = `Population, total`,
    co2 = `Carbon dioxide (CO2) emissions excluding LULUCF per capita (t CO2e/capita)`
  ) %>%
  mutate(
    gdp_pc = as.numeric(gdp_pc),
    population = as.numeric(population),
    co2 = as.numeric(co2)
  )

# Check
head(wdi_clean)
dim(wdi_clean)


# Clean FSI country names to match WDI
fsi_clean <- fsi_all %>%
  rename(
    country = Country,
    year = Year,
    fsi_score = Total
  ) %>%
  select(country, year, fsi_score)

# Merge FSI with WDI
merged_data <- fsi_clean %>%
  left_join(wdi_clean, by = c("country" = "country", 
                              "year" = "Year"))

# Check
dim(merged_data)
head(merged_data)

# Check how many matched
sum(!is.na(merged_data$gdp_pc))



# Fix WDI first - collapse to one row per country per year
wdi_fixed <- wdi_clean %>%
  group_by(country, iso3c, Year) %>%
  summarise(
    gdp_pc = sum(gdp_pc, na.rm = TRUE),
    population = sum(population, na.rm = TRUE),
    co2 = sum(co2, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  # Replace 0s with NA (from na.rm = TRUE on empty rows)
  mutate(
    gdp_pc = ifelse(gdp_pc == 0, NA, gdp_pc),
    population = ifelse(population == 0, NA, population),
    co2 = ifelse(co2 == 0, NA, co2)
  )

# Now merge again
merged_data <- fsi_clean %>%
  left_join(wdi_fixed, by = c("country" = "country",
                              "year" = "Year"))

# Check
dim(merged_data)
head(merged_data)
sum(!is.na(merged_data$gdp_pc))



# Download OECD climate finance data using API
install.packages("httr")
install.packages("jsonlite")

library(httr)
library(jsonlite)

# Use WDI climate finance indicator
climate_finance <- WDI(
  country = "all",
  indicator = c(
    climate_aid = "DT.ODA.ALLD.CD"
  ),
  start = 2010,
  end = 2023
)

# Check
head(climate_finance)
dim(climate_finance)

# Clean climate finance data
climate_clean <- climate_finance %>%
  select(country, iso3c, year, climate_aid) %>%
  filter(!is.na(climate_aid))

# Final merge - FSI + WDI + Climate Finance
final_data <- merged_data %>%
  left_join(climate_clean, by = c("country" = "country",
                                  "year" = "year"))

# Check
dim(final_data)
head(final_data)

# How many countries have climate aid data?
sum(!is.na(final_data$climate_aid))


# Final clean
final_data <- final_data %>%
  select(-iso3c.y) %>%
  rename(iso3c = iso3c.x) %>%
  # Create fragile state dummy (FSI score above 90 = fragile)
  mutate(
    fragile = ifelse(fsi_score >= 90, 1, 0),
    log_climate_aid = log(climate_aid + 1),
    log_gdp_pc = log(gdp_pc + 1),
    log_pop = log(population + 1)
  )

# Check
table(final_data$fragile)
head(final_data)

Q

ls()

#####regression
reg_data <- final_data %>%
  filter(!is.na(log_climate_aid) & 
           !is.na(fsi_score) & 
           !is.na(log_gdp_pc) & 
           !is.na(log_pop))

dim(reg_data)

panel_model <- plm(
  log_climate_aid ~ fsi_score + log_gdp_pc + log_pop,
  data = reg_data,
  index = c("country", "year"),
  model = "within",
  effect = "twoways"
)

summary(panel_model)
################
install.packages("modelsummary")
library(modelsummary)

modelsummary(
  list("Model 1" = model1, 
       "Model 2" = model2, 
       "Model 3" = model3),
  title = "Does Fragility Affect Climate Aid Receipt?",
  coef_rename = c(
    fsi_score = "FSI Score",
    log_gdp_pc = "Log GDP per Capita",
    log_pop = "Log Population"
  ),
  gof_map = c("nobs", "r.squared", "adj.r.squared"),
  notes = "Two-way fixed effects panel regression 2010-2023. 177 countries.",
  stars = c('*' = .1, '**' = .05, '***' = .01),
  output = "C:/Users/user/OneDrive/Desktop/regression_table.html"
)

# Model 1 - FSI only
model1 <- plm(
  log_climate_aid ~ fsi_score,
  data = reg_data,
  index = c("country", "year"),
  model = "within",
  effect = "twoways"
)

# Model 2 - FSI + GDP
model2 <- plm(
  log_climate_aid ~ fsi_score + log_gdp_pc,
  data = reg_data,
  index = c("country", "year"),
  model = "within",
  effect = "twoways"
)

# Model 3 - Full model
model3 <- plm(
  log_climate_aid ~ fsi_score + log_gdp_pc + log_pop,
  data = reg_data,
  index = c("country", "year"),
  model = "within",
  effect = "twoways"
)

# Now make table
modelsummary(
  list("Model 1" = model1, 
       "Model 2" = model2, 
       "Model 3" = model3),
  title = "Does Fragility Affect Climate Aid Receipt?",
  coef_rename = c(
    fsi_score = "FSI Score",
    log_gdp_pc = "Log GDP per Capita",
    log_pop = "Log Population"
  ),
  gof_map = c("nobs", "r.squared", "adj.r.squared"),
  notes = "Two-way fixed effects panel regression 2010-2023. 177 countries.",
  stars = c('*' = .1, '**' = .05, '***' = .01),
  output = "C:/Users/user/OneDrive/Desktop/regression_table.html"
)

modelsummary(
  list("Model 1" = model1, 
       "Model 2" = model2, 
       "Model 3" = model3),
  title = "Does Fragility Affect Climate Aid Receipt?",
  coef_rename = c(
    fsi_score = "FSI Score",
    log_gdp_pc = "Log GDP per Capita",
    log_pop = "Log Population"
  ),
  gof_map = c("nobs", "r.squared", "adj.r.squared"),
  notes = "Two-way fixed effects panel regression 2010-2023. 177 countries.",
  stars = c('*' = .1, '**' = .05, '***' = .01),
  output = "C:/Users/user/OneDrive/Desktop/regression_table.html"
)
modelsummary(
  list("Model 1" = model1, 
       "Model 2" = model2, 
       "Model 3" = model3),
  title = "Does Fragility Affect Climate Aid Receipt?",
  coef_rename = c(
    fsi_score = "FSI Score",
    log_gdp_pc = "Log GDP per Capita",
    log_pop = "Log Population"
  ),
  gof_map = c("nobs", "r.squared", "adj.r.squared"),
  notes = "Two-way fixed effects panel regression 2010-2023. 177 countries.",
  stars = c('*' = .1, '**' = .05, '***' = .01),
  output = "C:/Users/user/OneDrive/Desktop/regression_table.txt"
)

modelsummary(
  list("Model 1" = model1, 
       "Model 2" = model2, 
       "Model 3" = model3),
  title = "Does Fragility Affect Climate Aid Receipt?",
  coef_rename = c(
    fsi_score = "FSI Score",
    log_gdp_pc = "Log GDP per Capita",
    log_pop = "Log Population"
  ),
  gof_map = c("nobs", "r.squared", "adj.r.squared"),
  notes = "Two-way fixed effects panel regression 2010-2023. 177 countries.",
  stars = c('*' = .1, '**' = .05, '***' = .01),
  output = "C:/Users/user/OneDrive/Desktop/regression_table.txt"
)



# Plot - FSI score vs Climate Aid
ggplot(reg_data, aes(x = fsi_score, 
                     y = log_climate_aid,
                     color = factor(fragile))) +
  geom_point(alpha = 0.3) +
  geom_smooth(method = "lm", se = TRUE) +
  scale_color_manual(
    values = c("0" = "steelblue", "1" = "red"),
    labels = c("0" = "Stable", "1" = "Fragile")
  ) +
  labs(
    title = "Do Fragile States Receive More Climate Aid?",
    subtitle = "Panel Data 2010-2023 | 117 Countries",
    x = "FSI Score (Higher = More Fragile)",
    y = "Log Climate Aid Received (USD)",
    color = "Country Status",
    caption = "Sources: Fragile States Index, World Bank WDI"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(size = 11),
    legend.position = "bottom"
  )

# Save plot
ggsave(
  "C:/Users/user/OneDrive/Desktop/FSI_data/climate_aid_plot.png",
  width = 10, height = 6, dpi = 300
)
# Save your complete dataset
write.csv(
  final_data,
  "C:/Users/user/OneDrive/Desktop/FSI_data/final_dataset.csv",
  row.names = FALSE
)

# Save your R script
# Click File → Save As → 
# "C:/Users/user/OneDrive/Desktop/FSI_data/climate_fragility_analysis.R"







































































# Climate Finance & Fragility: Do Fragile States Get Left Out?
This project examines whether fragile and conflict-affected states 
receive systematically different levels of climate finance compared 
to stable countries. Using panel data from 117 countries over 
2010–2023, I apply a two-way fixed effects panel regression 
framework to identify the relationship between state fragility 
and climate aid receipt.

## Key Results
The empirical findings reveal statistically significant 
relationships between state fragility and climate aid receipt:

- **FSI Score:** Robustly positive and significant across all 
  model specifications (+0.014, p < 0.01), indicating that each 
  additional point of fragility is associated with a 1.4% increase 
  in climate aid received
- **GDP per Capita:** Positive and significant (+0.172, p < 0.05), 
  suggesting richer countries also attract more climate finance
- **Population Size:** Negative but insignificant (−0.274, p > 0.1), 
  indicating population size alone does not drive climate aid allocation

Contrary to expectations, fragile states receive **more** climate 
aid in absolute terms. However, this may reflect humanitarian and 
emergency bias rather than strategic climate investment — raising 
important questions about aid quality and long-term effectiveness.

## Regression Results

|  | Baseline | Model 2 | Model 3 |
|---|---|---|---|
| FSI Score | 0.014** | 0.014** | 0.014** |
| | (0.005) | (0.005) | (0.005) |
| Log GDP per Capita | | 0.172* | 0.172* |
| | | (0.084) | (0.084) |
| Log Population | | | −0.274 |
| | | | (0.294) |
| Num. Obs. | 1460 | 1460 | 1460 |
| R² | 0.007 | 0.008 | 0.009 |
| R² Adj. | −0.091 | −0.090 | −0.090 |
| FE: Country | ✓ | ✓ | ✓ |
| FE: Year | ✓ | ✓ | ✓ |

*p<0.1, ** p<0.05, *** p<0.01*  
Standard errors in parentheses, clustered by country.

## Conclusion
Overall, the results provide robust evidence that state fragility 
is positively associated with climate aid receipt, even after 
accounting for country-level heterogeneity and global time trends. 
However, the low R² suggests that fragility alone explains limited 
variation in climate finance flows, pointing to the need for 
richer data on aid quality, modality, and sectoral targeting. 
These findings reinforce the importance of integrating fragility 
risk into climate finance allocation frameworks, particularly for 
conflict-affected and least developed nations.

## Data Sources

| Dataset | Source | Years |
|---|---|---|
| Fragile States Index | Fund for Peace | 2010–2023 |
| Total ODA Received | World Bank WDI | 2010–2023 |
| GDP, Population | World Bank WDI | 2010–2023 |



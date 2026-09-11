# Fuel regression-rate data

`regression.csv` contains only the coefficients used by the simulator.
The coefficient `a_SI` assumes regression rate in `m/s` and oxidizer mass flux in `kg/(m^2 s)`.

## n2o_pe

- Simulator combination: N2O / PE
- Experimental material: HDPE
- Coefficient source: E. Doran et al., *Nitrous Oxide Hybrid Rocket Motor Fuel Regression Rate Characterization* (2007)
- DOI: https://doi.org/10.2514/6.2007-5352
- Stored values: `a_SI = 1.16e-4`, `n = 0.33`
- Conversion check: Hyzy et al. (2025) report `a = 0.248` and `n = 0.331` for regression rate in `mm/s` and oxidizer mass flux in `g/(cm^2 s)`. Converting `a` to the simulator's SI units gives approximately `1.16e-4`.
- Note: The stored values preserve the rounded coefficients previously used by Mode 5.

Hyzy et al. (2025) estimated the tested oxidizer mass-flux range as `30-270 kg/(m^2 s)` from plots in the source paper. This range is reference information and is not used by the simulator.

Reference: https://doi.org/10.13009/EUCASS2025-391

PP and ABS are intentionally absent until a coefficient source is selected and documented.

# Fuel regression-rate data

`regression.csv` contains only values used by the simulator. Source details,
limits, and assumptions are kept in this file so that the runtime data remain
easy to read.

All rows use

```text
regression rate [m/s] = a_SI * oxidizer mass flux [kg/(m^2 s)] ^ n
```

The `port` column selects the coefficient set. In the current trial,
`star_swirl` still uses the simulator's circular-port geometry. It changes the
regression-rate correlation only; it does not reproduce the star-fractal
surface area or its shape evolution.

## n2o_pe

- Selection: `N2O / PE / circle`
- Experimental material: HDPE
- Source: E. Doran et al., *Nitrous Oxide Hybrid Rocket Motor Fuel Regression Rate Characterization* (2007)
- DOI: https://doi.org/10.2514/6.2007-5352
- Stored values: `a_SI = 1.16e-4`, `n = 0.33`
- Status: existing rounded Mode 5 values
- Reference range: approximately `30-270 kg/(m^2 s)` as estimated from the source plots by Hyzy et al. (2025), https://doi.org/10.13009/EUCASS2025-391

## n2o_pp

- Selection: `N2O / PP / circle`
- Stored values: `a_SI = 7.49e-5`, `n = 0.68`
- Status: provisional engineering estimate; not a published two-parameter fit
- Basis: Doran et al. report one PP point at `Gox = 24 kg/(m^2 s)` and `rdot = 0.65 mm/s`. The exponent `n = 0.68` comes from the N2O/PP four-parameter model of Chelaru et al. The coefficient was recalculated as `0.65e-3 / 24^0.68 = 7.49e-5` so the simplified model passes through the Doran point.
- Limitation: only the reference point is experimentally anchored. Extrapolation must be treated as preliminary.
- Sources: https://doi.org/10.2514/6.2007-5352 and https://doi.org/10.1109/RAST.2011.5966936

Chelaru et al. use pressure and port-diameter exponents in addition to `a` and
`n`. Their coefficient `a` is therefore not copied directly into this
two-parameter table.

## n2o_abs

- Selection: `N2O / ABS / circle`
- Source: Y. Funami and A. Takano, *Averaged Regression Rate Evaluation of Hybrid Rocket Fuel Grain with a Star Fractal Port* (2020)
- DOI: https://doi.org/10.2322/astj.JSASS-D-19-00031
- Published equation: `rdot [mm/s] = 0.00870 * Gox^0.930`, with `Gox` in `kg/(m^2 s)`
- Stored values: `a_SI = 8.70e-6`, `n = 0.930`
- Status: conditional; fitted to three circular-port points after one unexplained outlier was excluded
- Reference range: approximately `110-205 kg/(m^2 s)`, reconstructed from the published test table and equations
- Material condition: sparse FDM ABS, material density `1040 kg/m^3`, effective grain density `768 kg/m^3`

## n2o_abs_sf

- Selection: `N2O / ABS / star_swirl`
- Source: Y. Funami and A. Takano, *Regression-Rate Evaluation of Hybrid-Rocket Fuel Grain with a Star-Fractal Swirl Port* (2023)
- DOI: https://doi.org/10.2322/tjsass.66.61
- Published equation: `rdot [mm/s] = 0.0107 * Gox^1.02`, with `Gox` in `kg/(m^2 s)`
- Stored values: `a_SI = 1.07e-5`, `n = 1.02`
- Status: trial approximation when used with the simulator's circular-port geometry
- Experimental range: `78.7-130 kg/(m^2 s)` over seven tests
- Fit quality: multiple `R^2 = 0.746`, adjusted `R^2 = 0.695`
- Material condition: sparse FDM ABS with effective grain density `768 kg/m^3`

The external fuel-property sheet previously used with this project listed ABS
at `1050 kg/m^3`. At the same area and regression rate, using `1050` instead of
the source value `768 kg/m^3` increases the calculated fuel mass flow by about
`36.7%`. This density mismatch must be included when interpreting results.

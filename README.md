
<!-- README.md is generated from README.Rmd. Please edit that file -->

# sleeper

<!-- badges: start -->

[![R-CMD-check](https://github.com/jhuwit/sleeper/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/jhuwit/sleeper/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

The goal of `sleeper` is to wrap code to run sleep estimation from
wrist-worn accelerometry.  
The package wraps the code from
<https://github.com/wadpac/Sundararajan-SleepClassification-2021>, that
was the modeling code from [Sundararajan
(2021)](https://doi.org/10.1038/s41598-020-79217-x). The work creted
random forests to classify raw wrist-worn accelerometry into
sleep/wake/non-wear categories and released the models at
<https://zenodo.org/records/3752645>. The models released were for
sleep/wake/non-wear categories, the models for sleep states (e.g. N1 vs
REM) were not released.

## Installation

You can install the development version of sleeper from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("jhuwit/sleeper")
```

## Example

``` r
library(sleeper)
zip_file = "/path/to/zip_file.zip"
sl_download_models(zip_file)
```

``` r
model_dir = "/path/to/models"
if (file.exists(zip_file)) {
  unzip(zip_file, exdir = model_dir, junkpaths = TRUE)
}
```

``` r
library(sleeper)
library(readr)

file = system.file("extdata", "example_data.csv.gz", package = "sleeper")
data = readr::read_csv(file)
#> Rows: 1296000 Columns: 4
#> ── Column specification ────────────────────────────────────────────────────────
#> Delimiter: ","
#> dbl  (3): X, Y, Z
#> dttm (1): time
#> 
#> ℹ Use `spec()` to retrieve the full column specification for this data.
#> ℹ Specify the column types or set `show_col_types = FALSE` to quiet this message.
if (sl_python_modules_installed()) {
  res = sl_features(data)
  names(res)
  head(as.data.frame(res))
}
#>                           times     ENMO.1     ENMO.2    ENMO.3      ENMO.4
#> 1 2017-10-30T15:00:00.000000000 0.01434644 0.01772052 0.1975212 0.009440902
#> 2 2017-10-30T15:00:30.000000000 0.01701947 0.02266649 0.5414451 0.009864418
#> 3 2017-10-30T15:01:00.000000000 0.02417810 0.04656924 0.5961219 0.023924088
#> 4 2017-10-30T15:01:30.000000000 0.02411672 0.01852455 0.1809331 0.011838206
#> 5 2017-10-30T15:02:00.000000000 0.01385429 0.01266273 0.1096779 0.010300577
#> 6 2017-10-30T15:02:30.000000000 0.03306845 0.06664564 0.7120015 0.028274721
#>      ENMO.5   ENMO.6        ENMO.7        ENMO.8       ENMO.9       ENMO.10
#> 1 1.2654473 2.884417  0.000000e+00  2.673031e-03  0.000000000  0.0062523476
#> 2 0.1994124 1.867399  2.673031e-03  7.158634e-03  0.002673031  0.0071279432
#> 3 0.6706424 2.212573  7.158634e-03 -6.138194e-05  0.008495149 -0.0051925963
#> 4 1.7874672 3.860443 -6.138194e-05 -1.026243e-02  0.003517935 -0.0006553512
#> 5 1.6081940 2.987287 -1.026243e-02  1.921416e-02 -0.010293120  0.0318796418
#> 6 0.6289889 2.453014  1.921416e-02  2.533097e-02  0.014082941  0.0084541233
#>        ENMO.11      ENMO.12 angle_z.1 angle_z.2 angle_z.3 angle_z.4 angle_z.5
#> 1  0.000000000  0.005445708 -52.25549  32.06366  86.46509  27.91426  1.429398
#> 2  0.002673031  0.006784922 -47.78410  28.94895  80.75432  25.48653  1.243141
#> 3  0.008495149  0.008181617 -38.51319  27.49593  87.80717  25.41225  1.970863
#> 4  0.005602051  0.008375249 -46.52415  12.45985  48.15117  10.75197  2.287344
#> 5 -0.006060891  0.021279205 -37.23653  26.48098  75.85685  24.82435  1.413818
#> 6  0.013276301 -0.005243379 -45.36372  25.48814 113.11445  21.56025  1.847085
#>   angle_z.6 angle_z.7 angle_z.8 angle_z.9 angle_z.10 angle_z.11 angle_z.12
#> 1  2.602494  0.000000  4.471390  0.000000   9.106846  0.0000000   9.741000
#> 2  2.116050  4.471390  9.270912  4.471390   5.265433  4.4713901   5.874706
#> 3  3.025502  9.270912 -8.010959 11.506607  -3.367149 11.5066072  -4.525293
#> 4  4.251617 -8.010959  9.287620 -3.375503   5.224028 -0.3398879  17.170469
#> 5  2.568265  9.287620 -8.127185  5.282141  -6.960097  9.0327043  18.868565
#> 6  3.614052 -8.127185  2.334176 -3.483375  27.956474 -2.8492216  40.879115
#>     LIDS.1     LIDS.2    LIDS.3     LIDS.4   LIDS.5   LIDS.6     LIDS.7
#> 1 53.14782 19.1196898 63.945102 15.0541372 2.448610 4.584666   0.000000
#> 2 32.19773  2.2306102  7.627749  1.9348281 2.991816 5.290004 -20.950094
#> 3 25.42056  1.6340474  5.760051  1.4049276 2.990934 5.289333  -6.777171
#> 4 20.17162  1.3178801  4.563923  1.1392460 2.985203 5.283784  -5.248940
#> 5 16.54282  0.8248825  2.861095  0.7130328 2.988105 5.286473  -3.628802
#> 6 14.16962  0.5742193  1.994631  0.4966622 2.992615 5.291851  -2.373191
#>       LIDS.8     LIDS.9    LIDS.10    LIDS.11    LIDS.12
#> 1 -20.950094   0.000000 -24.338680   0.000000 -29.564643
#> 2  -6.777171 -20.950094  -9.401641 -20.950094 -13.121575
#> 3  -5.248940 -17.252218  -7.063341 -17.252218  -9.614420
#> 4  -3.628802  -8.637525  -4.815398 -16.750419  -6.697164
#> 5  -2.373191  -6.253272  -3.287757 -16.191616  -4.784727
#> 6  -1.829133  -4.187592  -2.576937  -9.413555  -3.767697
```

``` r
if (sl_have_models(model_dir)) {
  output = estimate_sleep(data, model_dir = model_dir)
  print(head(output))
}
#> Predicting nonwear with model 1
#> Predicting nonwear with model 2
#> Predicting nonwear with model 3
#> Predicting nonwear with model 4
#> Predicting nonwear with model 5
#> Predicting sleep states with model 1
#> Predicting sleep states with model 2
#> Predicting sleep states with model 3
#> Predicting sleep states with model 4
#> Predicting sleep states with model 5
#> Predicting sleep states with model 6
#> # A tibble: 6 × 2
#>   time                          classification
#>   <chr>                         <chr>         
#> 1 2017-10-30T15:00:00.000000000 Sleep         
#> 2 2017-10-30T15:00:30.000000000 Sleep         
#> 3 2017-10-30T15:01:00.000000000 Sleep         
#> 4 2017-10-30T15:01:30.000000000 Sleep         
#> 5 2017-10-30T15:02:00.000000000 Sleep         
#> 6 2017-10-30T15:02:30.000000000 Wake
```

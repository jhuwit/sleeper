standardize_data = function(data) {
  x = y = z = timestamp = NULL
  rm(list = c("x", "y", "z", "timestamp"))
  data = data %>%
    dplyr::rename_all(tolower)
  data = data %>%
    dplyr::rename(timestamp = dplyr::any_of("time")) %>%
    dplyr::rename(timestamp = dplyr::any_of("header_timestamp")) %>%
    dplyr::rename(timestamp = dplyr::any_of("header_time_stamp"))

  data = data %>%
    dplyr::select(timestamp, x, y, z)
}

#' @rdname estimate_sleep
#' @export
sl_python_modules_installed = function() {
  modules = c("pandas",
    "numpy",
    "joblib",
    "collections",
    "scipy")
  all(sapply(modules, reticulate::py_module_available))
}

#' @rdname estimate_sleep
#' @export
sl_features = function(data) {

  data = standardize_data(data)

  file = system.file("features.py", package = "sleeper")
  reticulate::source_python(file)

  res = compute_features_out(
    data = data,
    time_interval = 30L)
  names(res) = c("times", "ENMO", "angle_z", "LIDS")
  res
}



#' Estimate Sleep from Wrist-Worn Accelerometry
#'
#' @param data A `data.frame` with columns of `timestamp`, `x`, `y`, `z`
#' @param model_dir path to the folder with models from
#' \href{https://doi.org/10.5281/zenodo.3752645}{https://doi.org/10.5281/zenodo.3752645}
#'
#' @return A `tibble` of times and classfication of category.
#' @export
#'
#' @examples
#' file = system.file("extdata", "example_data.csv.gz", package = "sleeper")
#' if (requireNamespace("readr", quietly = TRUE)) {
#'   data = readr::read_csv(file)
#'   if (sl_python_modules_installed()) {
#'      sl_features(data)
#'   }
#' }
estimate_sleep = function(
    data,
    model_dir) {
  data = standardize_data(data)

  # times = unique(lubridate::floor_date(data$timestamp, "30 seconds"))

  model_dir = path.expand(model_dir)
  model_dir = normalizePath(model_dir, winslash = "/", mustWork = TRUE)

  file = system.file("get_sleep_stage.py", package = "sleeper")
  reticulate::source_python(file)

  res = get_sleep_stage(
    data = data,
    time_interval = 30L,
    modeldir = model_dir,
    mode = "binary")

  file = system.file("features.py", package = "sleeper")
  reticulate::source_python(file)
  times = get_resampled_time(data, time_interval = 30L)
  times = c(times)
  output = dplyr::tibble(
    time = times,
    classification = res
  )
  output
}

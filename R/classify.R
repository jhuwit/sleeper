standardize_data = function(data) {
  x = y = z = timestamp = NULL
  rm(list = c("x", "y", "z", "timestamp"))
  data = data |>
    dplyr::rename_all(tolower)
  data = data |>
    dplyr::rename(timestamp = dplyr::any_of("time")) |>
    dplyr::rename(timestamp = dplyr::any_of("header_timestamp")) |>
    dplyr::rename(timestamp = dplyr::any_of("header_time_stamp"))

  data = data |>
    dplyr::select(timestamp, x, y, z)
}

#' @rdname estimate_sleep
#' @export
sl_python_modules_installed = function() {
  modules = c("pandas",
    "numpy",
    "joblib",
    "collections",
    "scipy",
    "sklearn")
  all(sapply(modules, reticulate::py_module_available))
}

#' Get Sleep Features
#'
#' @param data A `data.frame` with columns of `timestamp`, `x`, `y`, `z`
#'
#' @return A `tibble` of times and classification of category.
#' @export
#' @examples
#' file = system.file("extdata", "example_data.csv.gz", package = "sleeper")
#' if (requireNamespace("readr", quietly = TRUE)) {
#'   data = readr::read_csv(file, n_max = 3600L)
#'   if (sl_python_modules_installed()) {
#'      feat = sl_features(data)
#'   }
#' }
sl_features = function(data) {

  data = standardize_data(data)

  file = system.file("features.py", package = "sleeper")
  feat_env = new.env()
  reticulate::source_python(file, envir = feat_env)

  res = feat_env$compute_features_out(
    data = data,
    time_interval = 30L)
  names(res) = c("times", "ENMO", "angle_z", "LIDS")
  res
}



#' Estimate Sleep from Wrist-Worn Accelerometry
#'
#' @param data A `data.frame` with columns of `timestamp`, `x`, `y`, `z`
#' @param epoch Time in seconds for the time interval estimate
#' @param model_dir path to the folder with models from
#' \doi{10.5281/zenodo.3752645}
#' @param cores Number of workers to use for model prediction. Any non-zero
#'   integer accepted by Python `joblib` is allowed; `-1` uses all available
#'   workers. Defaults to one worker for CRAN compatibility.
#'
#' @return A `tibble` of times and classification of category.
#' @export
#'
#' @examples
#' \donttest{
#'   if (sl_python_modules_installed()) {
#'     models = sl_example_model()
#'     if (!is.null(models) && requireNamespace("readr", quietly = TRUE)) {
#'       file = system.file("extdata", "example_data.csv.gz", package = "sleeper")
#'       data = readr::read_csv(file, n_max = 3600L)
#'       # Two minutes is sufficient to demonstrate the workflow and avoids
#'       # applying the forest to the full 12-hour example recording.
#'       try({estimate_sleep(data, model_dir = dirname(models$binary[1]))})
#'     }
#'   }
#' }
estimate_sleep = function(
    data,
    epoch = 30L,
    model_dir,
    cores = 1L) {

  assertthat::assert_that(
    assertthat::is.count(epoch)
  )
  assertthat::assert_that(
    is.numeric(cores),
    length(cores) == 1L,
    is.finite(cores),
    cores == trunc(cores),
    cores != 0,
    msg = "cores must be a non-zero integer"
  )
  data = standardize_data(data)

  model_dir = path.expand(model_dir)
  assertthat::assert_that(
    dir.exists(model_dir),
    msg = "model_dir must be an existing directory"
  )
  model_dir = normalizePath(model_dir, winslash = "/", mustWork = TRUE)

  file = system.file("get_sleep_stage.py", package = "sleeper")
  sleep_env = new.env()
  reticulate::source_python(file, envir = sleep_env)

  res = sleep_env$get_sleep_stage(
    data = data,
    time_interval = epoch,
    modeldir = model_dir,
    mode = "binary",
    cores = cores)

  file = system.file("features.py", package = "sleeper")
  feat_env = new.env()
  reticulate::source_python(file, envir = feat_env)
  times = feat_env$get_resampled_time(data, time_interval = epoch)
  times = c(times)
  # times = unique(lubridate::floor_date(data$timestamp, "30 seconds"))

  output = dplyr::tibble(
    time = times,
    classification = res
  )
  output
}

#' Run `estimate_sleep` with Python
#'
#' @param ... arguments to pass to [estimate_sleep]
#' @param pyenv_function function that loads the forest Python package.
#' By default, it uses [sleeper::py_require_sleeper] to import
#' the package. If this function has an args argument, the output of
#' `pyenv_function` will be re-assigned to args.
#' @param show Logical, whether to show the standard output on the
#' screen while the child process is running, passed to [callr::r()]
#'
#' @export
py_estimate_sleep = function(
    ...,
    pyenv_function = function() {
      sleeper::py_require_sleeper()
    },
    show = FALSE) {
  rlang::check_installed("callr")
  steps <- callr::r(
    show = show,
    func = function(..., pyenv_function) {
      args = list(...)
      if ("args" %in% methods::formalArgs(pyenv_function)) {
        args = pyenv_function(args)
      } else {
        pyenv_function()
      }
      res = do.call(sleeper::estimate_sleep, args = args)
    },
    args = list(...,
                pyenv_function = pyenv_function)
  ) # Safely injects data into the process
}

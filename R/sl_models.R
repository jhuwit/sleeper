model_df = function(model_dir = NULL, folds = 1:5) {
  binary = nonwear = NULL
  rm(list = c("binary", "nonwear"))
  if (is.null(folds)) {
    folds = 1:5
  }
  files = data.frame(
    fold = folds,
    binary = paste0("fold", folds, "_binary_balanced_RF.sav"),
    nonwear = paste0("fold", folds, "_nonwear_balanced_RF.sav")
  )
  if (!is.null(model_dir)) {
    model_dir = normalizePath(
      path.expand(model_dir),
      winslash = "/",
      mustWork = FALSE
    )
    files = files |>
      dplyr::mutate(
        binary = file.path(model_dir, binary),
        nonwear = file.path(model_dir, nonwear)
      )
  }
  files
}

#' Check for Downloaded Sleep Models
#'
#' @param model_dir path to the folder with models from
#' \doi{10.5281/zenodo.3752645}
#'
#' @return A logical indicating all folds are downloaded.
#' @export
#' @rdname sl_models
sl_have_models = function(model_dir) {

  check = dir.exists(model_dir)
  files = model_df(model_dir)
  check = check &&
    all(file.exists(files$binary)) &&
    all(file.exists(files$nonwear))
  if (!check) {
    msg = paste0("Some folds are missing. Download the data from: \n",
                 "https://doi.org/10.5281/zenodo.3752645 and unzip the output into ",
                 "a folder.")
    message(msg)
  }
  check
}

#' @rdname sl_models
#' @param quiet argument passed to [curl::curl_download]
#' @param ... additional arguments to pass to [curl::curl_download]
#' @param overwrite logical, if `TRUE` will overwrite existing files
#' @param folds should all model folds be downloaded?  If only some folds,
#' specify that (used almost exclusively for testing).
#' @export
sl_download_models = function(
    model_dir,
    quiet = FALSE,
    ...,
    overwrite = FALSE,
    folds = 1:5) {

  binary = nonwear = NULL
  rm(list = c("binary", "nonwear"))

  files = model_df(model_dir, folds = folds)
  base_url = "https://zenodo.org/records/3752645/files/"
  files = files |>
    dplyr::mutate(
      binary_url = paste0(base_url, basename(binary), "?download=1"),
      nonwear_url = paste0(base_url, basename(nonwear), "?download=1")
    )
  mapply(function(url, destfile) {
    if (!file.exists(destfile) && !overwrite) {
      curl::curl_download(url, destfile, quiet = quiet, ...)
    }
  },
  c(files$binary_url, files$nonwear_url),
  c(files$binary, files$nonwear))
  stopifnot(all(file.exists(c(files$binary, files$nonwear))))
  files
}

#' Download Compact Example Sleep Models
#'
#' Downloads the compact fold-2 models kept in the package's GitHub
#' repository. These models are intended for examples and quick smoke tests;
#' use [sl_download_models()] for the complete model ensemble.
#'
#' @param model_dir Directory in which to save the example models.
#' @param quiet Logical; passed to [curl::curl_download()].
#' @param ... Additional arguments passed to [curl::curl_download()].
#' @param overwrite Logical; overwrite files that are already present.
#'
#' @return The downloaded model paths, or `NULL` when a download fails.
#' @export
sl_download_example_model = function(
    model_dir = file.path(tempdir(), "sleeper-example-models"),
    quiet = FALSE,
    ...,
    overwrite = FALSE) {

  files = model_df(model_dir, folds = 2)
  dir.create(model_dir, recursive = TRUE, showWarnings = FALSE)
  urls = paste0(
    "https://raw.githubusercontent.com/jhuwit/sleeper/main/data-raw/",
    basename(c(files$binary, files$nonwear))
  )
  destinations = c(files$binary, files$nonwear)

  for (i in seq_along(urls)) {
    if (file.exists(destinations[i]) && !overwrite) {
      next
    }
    downloaded = tryCatch(
      {
        curl::curl_download(urls[i], destinations[i], quiet = quiet, ...)
        TRUE
      },
      error = function(error) {
        message(
          "Could not download the compact example model from GitHub: ",
          conditionMessage(error)
        )
        FALSE
      }
    )
    if (!downloaded) {
      return(invisible(NULL))
    }
  }

  sizes = file.info(destinations)$size
  if (any(!file.exists(destinations)) || any(is.na(sizes)) || any(sizes == 0)) {
    message("The compact example models were not downloaded completely.")
    return(invisible(NULL))
  }
  files
}

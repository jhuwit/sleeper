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
    model_dir = path.expand(model_dir)
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

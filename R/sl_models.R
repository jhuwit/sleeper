#' Sleep Models
#'
#' @param model_dir path to the folder with models from
#' \href{https://doi.org/10.5281/zenodo.3752645}{https://doi.org/10.5281/zenodo.3752645}
#'
#' @return A `tibble` of times and classfication of category.
#' @export
#' @rdname sl_models
sl_have_models = function(model_dir) {
  check = dir.exists(model_dir)
  check = check &&
    length(list.files(model_dir,
                      pattern = ".sav", ignore.case = TRUE)
    ) > 0
  if (!check) {
    msg = paste0("Download the data from: \n",
                 "https://doi.org/10.5281/zenodo.3752645 and unzip the output into ",
                 "a folder.")
    message(msg)
  }
  check
}

#' @rdname sl_models
#' @param zip_file path of zip file to download the models zip file to.
#' Then [utils::unzip] can be run to extract the models to a specific folder
#' @param quiet argument passed to [curl::curl_download]
#' @param ... additional arguments to pass to [curl::curl_download]
#' @export
sl_download_models = function(zip_file, quiet = FALSE, ...) {
  if (file.exists(zip_file)) {
    stop(paste0(zip_file, " exists, not overwriting!"))
  }
  curl::curl_download(
    "https://zenodo.org/api/records/3752645/files-archive",
    destfile = zip_file,
    quiet = quiet,
    ...)
}

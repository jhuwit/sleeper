
#' Command for `py_require` for `sleeper`
#'
#' @param ... arguments to pass to [reticulate::py_require()]
#'
#' @returns A logical value indicating whether the package is available.
#' @export
py_require_sleeper = function(...) {
  reticulate::py_require(
    packages = c("pandas",
                "numpy==1.20",
                "joblib",
                "scipy",
                "scikit-learn==0.22.1"),
    python_version = "3.8",
    ...)
}



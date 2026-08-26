
# Python requirements used by feature extraction.  Keep this separate from
# the classifier requirements: importing scikit-learn is unnecessary when a
# user only wants `sl_features()`.
.sleeper_feature_packages = c(
  "pandas",
  "numpy>=1.20",
  "scipy"
)

# Module names are separate from package requirements: `collections` is part
# of Python's standard library and is imported by `utils.py`, so uv must not
# be asked to install it.
.sleeper_feature_modules = c(
  "pandas",
  "numpy",
  "scipy",
  "collections"
)

.sleeper_model_modules = c(
  "joblib",
  "threadpoolctl",
  "sklearn"
)

#' Command for `py_require` for the full `sleeper` workflow
#'
#' @param ... arguments to pass to [reticulate::py_require()]
#'
#' @returns A logical value indicating whether the package is available.
#' @export
py_require_sleeper = function(...) {
  reticulate::py_require(
    packages = c(
      .sleeper_feature_packages,
      "joblib",
      "threadpoolctl",
      "scikit-learn==0.22.1"
    ),
    python_version = "3.8",
    ...)
}

# Register only the packages imported by `features.py`. This deliberately is
# not exported; `py_require_sleeper()` remains the public full installer.
.py_require_sleeper_features = function(...) {
  reticulate::py_require(
    packages = .sleeper_feature_packages,
    python_version = "3.8",
    ...)
}

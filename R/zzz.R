.onLoad <- function(libname, pkgname) {
  # Declare the default, feature-extraction environment up front, as
  # recommended by reticulate. Model-only packages are added lazily by
  # `estimate_sleep()` before it initializes Python.
  .py_require_sleeper_features()
}

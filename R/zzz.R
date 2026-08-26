.onLoad <- function(libname, pkgname) {
  # scikit-learn 0.22.1 is needed only for model prediction and has no
  # Apple Silicon wheel. Declare the universally needed feature stack here;
  # `estimate_sleep()` adds the legacy model stack before it initializes it.
  .py_require_sleeper_features()
}

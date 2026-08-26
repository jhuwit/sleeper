example_accelerometer_data <- function() {
  file <- system.file("extdata", "example_data.csv.gz", package = "sleeper")
  # A short segment exercises the feature bridge without parsing the entire
  # 12-hour recording for every test run.
  readr::read_csv(file, n_max = 3600L, show_col_types = FALSE)
}

test_that("standardize_data accepts supported timestamp column names", {
  data <- data.frame(
    Time = 1:2,
    X = 3:4,
    Y = 5:6,
    Z = 7:8,
    extra = 9:10
  )
  standardized <- sleeper:::standardize_data(data)
  expect_named(standardized, c("timestamp", "x", "y", "z"))
  expect_equal(standardized$timestamp, 1:2)

  data <- data.frame(header_time_stamp = 1:2, x = 3:4, y = 5:6, z = 7:8)
  expect_equal(sleeper:::standardize_data(data)$timestamp, 1:2)
})

test_that("Python dependency helpers delegate to reticulate", {
  expect_true(with_mocked_bindings(
    sl_python_modules_installed(),
    .python_modules_available = function(modules) {
      expect_equal(
        modules,
        c("pandas", "numpy", "scipy", "collections",
          "joblib", "threadpoolctl", "sklearn")
      )
      TRUE
    },
    .package = "sleeper"
  ))
  expect_false(with_mocked_bindings(
    sl_python_modules_installed("features"),
    .python_modules_available = function(modules) {
      expect_equal(modules, c("pandas", "numpy", "scipy", "collections"))
      FALSE
    },
    .package = "sleeper"
  ))

  expect_true(with_mocked_bindings(
    py_require_sleeper(),
    py_require = function(packages, python_version, ...) {
      expect_equal(python_version, "3.8")
      expect_true("numpy>=1.20" %in% packages)
      expect_true("threadpoolctl" %in% packages)
      TRUE
    },
    .package = "reticulate"
  ))
})

test_that("the load hook registers feature Python dependencies", {
  expect_true(with_mocked_bindings(
    sleeper:::.onLoad("unused", "sleeper"),
    .py_require_sleeper_features = function(...) TRUE,
    .package = "sleeper"
  ))
})

test_that("feature extraction requests only its Python dependencies", {
  expect_true(with_mocked_bindings(
    sleeper:::.py_require_sleeper_features(),
    py_require = function(packages, python_version, ...) {
      expect_equal(packages, c("pandas", "numpy>=1.20", "scipy"))
      expect_equal(python_version, "3.8")
      TRUE
    },
    .package = "reticulate"
  ))
})

test_that("module availability probe does not import target modules", {
  importlib_util = list(
    find_spec = function(module) if (module == "missing") NULL else list()
  )
  expect_true(with_mocked_bindings(
    sleeper:::.python_modules_available(c("numpy", "pandas")),
    import = function(module, ...) {
      expect_equal(module, "importlib.util")
      importlib_util
    },
    .package = "reticulate"
  ))
  expect_false(with_mocked_bindings(
    sleeper:::.python_modules_available(c("numpy", "missing")),
    import = function(module, ...) importlib_util,
    .package = "reticulate"
  ))
})

test_that("sl_features returns named feature output through the Python bridge", {
  skip_if_not_installed("readr")
  fake_source_python <- function(file, envir) {
    assign(
      "compute_features_out",
      function(data, time_interval) list("time", "enmo", "angle", "lids"),
      envir = envir
    )
  }

  features <- with_mocked_bindings(
    sl_features(example_accelerometer_data()),
    source_python = fake_source_python,
    .package = "reticulate"
  )
  expect_named(features, c("times", "ENMO", "angle_z", "LIDS"))
  expect_equal(unname(unlist(features)), c("time", "enmo", "angle", "lids"))
})

test_that("sl_features returns feature matrices when Python is available", {
  skip_on_cran()
  skip_if_not_installed("readr")
  if (!sl_python_modules_installed("features")) {
    if (identical(Sys.getenv("CI"), "true")) {
      fail("Required Python modules could not be provisioned")
    }
    skip("Required Python modules are not available")
  }

  features <- tryCatch(sl_features(example_accelerometer_data()), error = identity)
  if (inherits(features, "error")) {
    if (identical(Sys.getenv("CI"), "true")) {
      fail(conditionMessage(features))
    }
    skip(paste("Python feature extraction is unavailable:", conditionMessage(features)))
  }

  expect_named(features, c("times", "ENMO", "angle_z", "LIDS"))
  expect_true(length(features$times) > 0)
  expect_equal(length(features$times), nrow(features$ENMO))
})

test_that("estimate_sleep combines Python predictions with resampled times", {
  model_dir <- tempfile("sleeper-models-")
  dir.create(model_dir)
  fake_source_python <- function(file, envir) {
    if (basename(file) == "get_sleep_stage.py") {
      assign(
        "get_sleep_stage",
        function(data, time_interval, modeldir, mode, cores) {
          expect_equal(cores, -1L)
          c("Wake", "Sleep")
        },
        envir = envir
      )
    } else {
      assign(
        "get_resampled_time",
        function(data, time_interval) c("first", "second"),
        envir = envir
      )
    }
  }

  output <- with_mocked_bindings(
    estimate_sleep(
      data.frame(timestamp = 1:2, x = 0, y = 0, z = 1),
      epoch = 30L,
      model_dir = model_dir,
      cores = -1L
    ),
    source_python = fake_source_python,
    .package = "reticulate"
  )
  expect_equal(output$time, c("first", "second"))
  expect_equal(output$classification, c("Wake", "Sleep"))
})

test_that("estimate_sleep validates epoch and model directory before Python work", {
  data <- data.frame(timestamp = 1, x = 0, y = 0, z = 1)

  expect_error(estimate_sleep(data, epoch = 0L, model_dir = tempdir()))
  expect_error(
    estimate_sleep(data, model_dir = tempdir(), cores = 0L),
    "cores must be a non-zero integer"
  )
  expect_error(
    estimate_sleep(data, epoch = 30L, model_dir = file.path(tempdir(), "missing-models")),
    "model_dir must be an existing directory"
  )
})

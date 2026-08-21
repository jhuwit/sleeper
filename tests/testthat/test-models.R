test_that("model_df constructs expected model paths", {
  expected_names <- c(
    "fold2_binary_balanced_RF.sav",
    "fold2_nonwear_balanced_RF.sav"
  )

  models <- sleeper:::model_df(folds = 2)
  expect_equal(models$fold, 2)
  expect_equal(unname(unlist(models[1, c("binary", "nonwear")])), expected_names)

  model_dir <- file.path(tempdir(), "sleeper model directory")
  models <- sleeper:::model_df(model_dir, folds = 2:3)
  expect_equal(models$fold, 2:3)
  expect_true(all(dirname(models$binary) ==
                    normalizePath(
                      path.expand(model_dir),
                      winslash = "/",
                      mustWork = FALSE
                    )))
  expect_equal(nrow(sleeper:::model_df(folds = NULL)), 5)
})

test_that("sl_have_models reports missing and complete model directories", {
  model_dir <- tempfile("sleeper-models-")

  expect_message(expect_false(sl_have_models(model_dir)), "Some folds are missing")

  dir.create(model_dir)
  model_files <- sleeper:::model_df(model_dir)
  file.create(c(model_files$binary, model_files$nonwear))
  expect_true(sl_have_models(model_dir))
})

test_that("sl_download_models reuses existing requested model files", {
  model_dir <- tempfile("sleeper-models-")
  dir.create(model_dir)
  expected <- sleeper:::model_df(model_dir, folds = 2)
  file.create(expected$binary, expected$nonwear)

  downloaded <- sl_download_models(model_dir, folds = 2, quiet = TRUE)
  expect_equal(downloaded[c("fold", "binary", "nonwear")], expected)
})

test_that("sl_download_example_model handles unavailable downloads", {
  model_dir <- tempfile("sleeper-example-models-")
  result <- NULL
  expect_message(
    result <- with_mocked_bindings(
      sl_download_example_model(model_dir, quiet = TRUE),
      curl_download = function(...) stop("network unavailable"),
      .package = "curl"
    ),
    "Could not download the compact example model"
  )

  expect_null(result)
  expect_true(dir.exists(model_dir))
  example_files <- unlist(
    sleeper:::model_df(model_dir, folds = 2)[c("binary", "nonwear")]
  )
  expect_false(any(file.exists(example_files)))
})

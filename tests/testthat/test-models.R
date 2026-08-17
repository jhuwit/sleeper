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
  expect_true(all(dirname(models$binary) == path.expand(model_dir)))
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

test_that("sl_download_models can download fold 2", {
  model_dir <- tempfile("sleeper-fold-2-")
  dir.create(model_dir)

  downloaded <- tryCatch(
    sl_download_models(
      model_dir,
      folds = 2,
      quiet = TRUE,
      handle = curl::new_handle(timeout = 120)
    ),
    error = identity
  )
  if (inherits(downloaded, "error")) {
    skip(paste("Fold 2 models could not be downloaded:", conditionMessage(downloaded)))
  }

  expect_equal(downloaded$fold, 2)
  expect_true(all(file.exists(c(downloaded$binary, downloaded$nonwear))))
  expect_true(all(file.info(c(downloaded$binary, downloaded$nonwear))$size > 0))
})

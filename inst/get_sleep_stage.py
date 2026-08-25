import sys, os
import numpy as np
import pandas as pd
import joblib
from threadpoolctl import threadpool_limits

from features import compute_features
from collections import Counter

def limit_model_workers(model, cores):
  """Set the number of workers for search wrappers and their forests."""
  if hasattr(model, 'n_jobs'):
    model.n_jobs = cores
  if hasattr(model, 'estimator') and hasattr(model.estimator, 'n_jobs'):
    model.estimator.n_jobs = cores
  if hasattr(model, 'best_estimator_') and hasattr(model.best_estimator_, 'n_jobs'):
    model.best_estimator_.n_jobs = cores

def get_sleep_stage(data, time_interval, modeldir, mode, cores=1):
  if isinstance(cores, bool) or not isinstance(cores, (int, np.integer)) or cores == 0:
    raise ValueError('cores must be a non-zero integer')
  # Keep CRAN's shared check machines single-core by default.
  # Forest workers may be parallel, but each worker gets one BLAS/OpenMP thread.
  with threadpool_limits(limits=1):
    return _get_sleep_stage(data, time_interval, modeldir, mode, cores)

def _get_sleep_stage(data, time_interval, modeldir, mode, cores):
  if mode == 'binary':
    states = ['Wake', 'Sleep']
  else: # multiclass
    states = ['Wake', 'NREM 1', 'NREM 2', 'NREM 3', 'REM']

  df = pd.DataFrame(data, columns=['timestamp','x','y','z'])
  df['timestamp'] = pd.to_datetime(df['timestamp'], unit='s')

  # Compute features
  feat = compute_features(df, time_interval)
  N = feat.shape[0]

  # Load nonwear models from given path and make predictions
  model_files = os.listdir(modeldir)
  nonwear_files = [fname for fname in model_files if 'nonwear' in fname]
  nfolds = len(nonwear_files)

  nw_pred = None
  for fold,fname in enumerate(nonwear_files):
    print('Predicting nonwear with model ' + str(fold+1))
    scaler, cv_clf = joblib.load(os.path.join(modeldir, fname))
    limit_model_workers(cv_clf, cores)
    feat_sc = scaler.transform(feat)
    fold_nw_pred = cv_clf.predict_proba(feat_sc)
    if fold == 0:
      nw_pred = fold_nw_pred
    else:
      nw_pred = nw_pred + fold_nw_pred
  nw_pred = nw_pred/float(nfolds)
  nw_pred = np.argmax(nw_pred, axis=1)

  # Load models from given path and make predictions for given mode
  model_files = [fname for fname in model_files if mode in fname]
  nfolds = len(model_files)

  y_pred = None
  for fold,fname in enumerate(model_files):
    print('Predicting sleep states with model ' + str(fold+1))
    scaler, cv_clf = joblib.load(os.path.join(modeldir, fname))
    limit_model_workers(cv_clf, cores)
    feat_sc = scaler.transform(feat)
    fold_y_pred = cv_clf.predict_proba(feat_sc)
    if fold == 0:
      y_pred = fold_y_pred
    else:
      y_pred = y_pred + fold_y_pred
  y_pred = y_pred/float(nfolds)
  y_pred = np.argmax(y_pred, axis=1)
  y_pred = np.array([states[i] for i in y_pred])

  # Merge results of nonwear and sleep classification
  results = np.array(['Nonwear']*N)
  results[nw_pred == 0] = y_pred[nw_pred == 0]
  results = list(results)

  #sys.stdout.flush()

  return results

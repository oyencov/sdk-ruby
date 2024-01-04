# Changelog

## 0.0.4 (2023-01-04)

1. Puma - Add support for cluster mode. Each worker process will submit their own runtime reports.
2. Change license from MIT to proprietary.

## 0.0.3 (2023-12-05)

1. CLI `oyencov submit` now doesn't require `--files` option.

## 0.0.2 (2023-11-09)

1. Fully rebrand everything in codebase from OyenOnsen to OyenCov.
2. Make it run in test mode even when API key is not set.
3. Put `OyenCov::VERSION` in its own file, have everywhere else refer to it.

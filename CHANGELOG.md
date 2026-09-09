# Changelog

## 0.7.1 - 2026-09-09

### Fixed

- `query_gql/1` no longer expands to an unreachable `raise` after a document
  loaded with `load_gql_file/1` or `load_gql_string/1`. Elixir 1.20's type
  checker reported it as "the right-hand side of || will never be executed" at
  every call site, which failed suites run with `--warnings-as-errors`. The
  fallback is now chosen when the macro expands; the `query:` option and the
  `:missing_declaration` error behave as before.

### Changed

- Added a GitHub Actions matrix for Elixir 1.18.4/OTP 27 and Elixir 1.20.4/OTP 29.
- Updated credo so `mix credo --strict` works on Elixir 1.20.

## 0.7.0 - 2026-03-10

### Added

- `query:` option on `query_gql/1` to run an inline document without
  `load_gql_file/1` or `load_gql_string/1`.

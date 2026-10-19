# Engineering Tasks

## Initial review
- [ ] Inspect authentication and first-run administrator setup.
- [ ] Trace database backup, restore, and migration paths.
- [ ] Run `flutter pub get`, `flutter analyze`, and `flutter test` in a compatible Flutter environment.
- [ ] Review `.github/workflows/build.yml`, especially dependency upgrades, permissions, and generated-file changes.
- [ ] Confirm platform support claims against actual build jobs.

## Acceptance criteria
- No shared default administrator credential is usable in production.
- Dependency changes are deliberate and reproducible.
- Analyzer and test results are visible on pull requests.
- CI builds do not introduce unintended tracked changes.
- Environment limitations are reported instead of treated as passing tests.

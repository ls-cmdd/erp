# Engineering Roadmap

## P0 — Security and release reliability
- [ ] Review administrator authentication and secure first-run setup.
- [ ] Review database backup/restore and failure handling.
- [ ] Make dependency resolution reproducible; avoid unreviewed upgrades during every build.
- [ ] Verify the Windows installer workflow does not modify tracked source files unexpectedly.

## P1 — Automated quality checks
- [ ] Run `flutter analyze` in CI.
- [ ] Add deterministic tests for critical financial and inventory operations.
- [ ] Require passing checks before merging pull requests.

## P2 — Platform and maintenance
- [ ] Verify Linux/macOS support with platform builds or narrow the README claim.
- [ ] Document backup, restore, data migration, and release procedures.
- [ ] Review dependency updates in isolated pull requests.

Start with credential handling and release reproducibility before broad refactors.

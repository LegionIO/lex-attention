# Changelog

## [0.1.1] - 2026-03-18

### Fixed
- Enforce `MINIMUM_THRESHOLD` (0.05) as a pre-filter — signals with intrinsic salience below 0.05 are dropped before scoring, preventing noise from building habituation records or consuming scoring cycles

## [0.1.0] - 2026-03-13

### Added
- Initial release: selective attention filter with Miller's Law capacity (7 +/- 2)
- Habituation tracking with novelty reset, goal-directed amplification, manual focus control
- Four-tier signal classification (spotlight, peripheral, background, filtered)
- Standalone Client

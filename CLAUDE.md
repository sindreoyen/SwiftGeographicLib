# CLAUDE.md

Swift wrapper over GeographicLib C geodesic routines. SwiftPM library, Swift 6 tools.

## Layout

- `Sources/geographiclib/` — vendored C lib. `geodesic.c` + `Include/geodesic.h`. Do not modify unless syncing upstream.
- `Sources/SwiftGeographicLib/Calculations/` — public Swift API (`Geodesic`, `GeodesicLine`, `GeodesicPolygon`).
- `Sources/SwiftGeographicLib/Model/` — `GeodGeodesic` (ellipsoid params), `GeodesicMask`, `GeodesicFlags` (OptionSet bitmasks mirroring C).
- `Tests/SwiftGeographicLibTests/` — uses Swift Testing (not XCTest).

## API surface

- `Geodesic` — enum, static `direct` / `generalDirect` / `inverse` / `generalInverse`.
- `GeodesicLine` — class, step along geodesic. Two inits: `from:azimuth:caps:` and `directFrom:azimuth:distance:caps:`.
- `GeodesicPolygon` — class, accumulate vertices/edges. Static `area(of:)` one-liner.
- All APIs default ellipsoid `GeodGeodesic.WGS84`. Coordinates are `(lat:lon:)` tuples of `CLLocationDegrees`.

## C bridging pattern

Each Swift call creates local `var g = geod_geodesic()`, calls `geod_init(&g, a, f)`, then invokes C func with inout pointers. Output vars declared `0.0` then returned as tuple. Match this pattern when adding wrappers.

## Build / test

```bash
swift build
swift test
```

## Conventions

- Public API uses Swift naming (`distance:`, `azimuth:`), not C names (`s12`, `azi1`). Keep C names only as internal var labels matching GeographicLib docs.
- New wrappers: add to `Calculations/`, add tests under `Tests/SwiftGeographicLibTests/Geodesic/` (one file per C func family).
- Bitmask values in `GeodesicMask` / `GeodesicFlags` must match `geodesic.h` constants exactly.
- Doc comments triple-slash, match style in existing files.

## Skills available

Repo has SDD skills loaded (`/spec`, `/build`, `/check`, `/backprop`). No `SPEC.md` exists yet — use `/spec` to create one if invariants need recording.

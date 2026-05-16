# SwiftGeographicLib

A Swift wrapper around the geodesic routines from the renowned [GeographicLib](https://geographiclib.sourceforge.io/) — accurate distance, bearing, destination, and area calculations on the WGS-84 ellipsoid.

Under the hood it calls the original C library. On top it ships **two layers**:

- **Simple API** — `CLLocationCoordinate2D` extensions. One line per question. Use this 90% of the time.
- **Complete API** — full access to every GeographicLib routine, including incremental geodesic lines, polygons, custom ellipsoids, and the `geod_gen*` extended outputs.

Both layers are always available. Start simple, drop down when you need more.

---

## Installation

Swift Package Manager. In `Package.swift`:

```swift
dependencies: [
  .package(
    url: "https://github.com/sindreoyen/SwiftGeographicLib.git",
    .upToNextMinor(from: "1.0.4")
  )
]
```

Then import:

```swift
import SwiftGeographicLib
import CoreLocation
```

Requires Swift 6.0+.

---

## Quick start (Simple API)

Everything you need for typical geographic work lives directly on `CLLocationCoordinate2D`. Type a dot, autocomplete shows the options.

```swift
let jfk = CLLocationCoordinate2D(latitude: 40.6413, longitude: -73.7781)
let lhr = CLLocationCoordinate2D(latitude: 51.4700, longitude: -0.4543)

// How far apart? (metres)
let metres = jfk.distance(to: lhr)             // ≈ 5_551_000

// Which way to fly?
let bearing = jfk.initialBearing(to: lhr)      // degrees from north

// Where do I end up flying 1000 km at bearing 51° from JFK?
let waypoint = jfk.destination(bearing: 51, distance: 1_000_000)
```

### Polygon area & perimeter

```swift
let manhattan: [CLLocationCoordinate2D] = [
    .init(latitude: 40.7000, longitude: -74.0200),
    .init(latitude: 40.7000, longitude: -73.9300),
    .init(latitude: 40.8800, longitude: -73.9300),
    .init(latitude: 40.8800, longitude: -74.0200),
]

let areaM2     = Geodesic.area(of: manhattan)
let perimeterM = Geodesic.perimeter(of: manhattan)
```

### Simple API reference

| Call | Returns |
|---|---|
| `coord.distance(to: other)` | metres |
| `coord.initialBearing(to: other)` | degrees (azimuth at `coord`) |
| `coord.finalBearing(to: other)` | degrees (azimuth at `other`) |
| `coord.destination(bearing:distance:)` | `CLLocationCoordinate2D` |
| `Geodesic.area(of: coords)` | m² |
| `Geodesic.perimeter(of: coords)` | metres |

Every call takes an optional `on: GeodGeodesic = .WGS84` for a custom ellipsoid.

---

## Complete API

When you need extended outputs (reduced length, geodesic scales, area along a path), arc-mode, custom flags, or incremental stepping along a geodesic — use the underlying types directly.

### `Geodesic` — direct and inverse

```swift
let start = (lat: 40.64, lon: -73.78)

// Direct: where do I end up?
let dest = Geodesic.direct(from: start, distance: 10_000_000, azimuth: 45.0)

// Inverse: distance + both azimuths
let (s12, azi1, azi2) = Geodesic.inverse(
    between: start,
    and: (lat: 1.36, lon: 103.99)
)

// Extended outputs (m12, M12, M21, S12, a12 …)
let result = Geodesic.generalDirect(
    from: start,
    azimuth: 45,
    flags: .all,
    s12_a12: 10e6
)
```

### `GeodesicLine` — walk a geodesic

Use when you need many points along the same geodesic — cheaper than repeated `direct` calls.

```swift
let line = GeodesicLine(
    from: (lat: 40.64, lon: -73.78),
    azimuth: 45.0,
    caps: [.distanceIn, .longitude, .latitude]
)

let point = line.position(distance: 1_000_000)

// Or pin the endpoint up front:
let line2 = GeodesicLine(
    directFrom: (lat: 40.64, lon: -73.78),
    azimuth: 45.0,
    distance: 10_000_000,
    caps: .all
)
```

### `GeodesicPolygon` — incremental area / perimeter

Useful when vertices arrive one at a time, or when you want to peek at the area before committing a vertex.

```swift
let poly = GeodesicPolygon(polyline: false)
poly.addPoint((lat: 0.0, lon: 0.0))
poly.addEdge(azimuth: 90, distance: 111_000)
let (vertexCount, area, perimeter) = poly.compute()

// Peek without mutating state:
let (_, provisionalArea, _) = poly.testPoint((lat: 1, lon: 0))
```

### Custom ellipsoid

WGS-84 is the default. Override anywhere:

```swift
let grs80 = GeodGeodesic(a: 6_378_137.0, f: 1.0 / 298.257222101)
let d = jfk.distance(to: lhr, on: grs80)
```

### Masks & flags

`GeodesicMask` and `GeodesicFlags` are `OptionSet`s mirroring the C bitmasks. They control which extended outputs the C library computes.

```swift
let caps: GeodesicMask = [.distanceIn, .longitude, .area]
let line = GeodesicLine(from: start, azimuth: 0, caps: caps)

let (lat2, lon2, _, _, _, _, _, _, a12) =
    line.genPosition(flags: .arcMode, s12_a12: 4.5)
```

Available masks: `.latitude`, `.longitude`, `.azimuth`, `.distance`, `.distanceIn`, `.reducedLength`, `.scale`, `.area`, `.all`.
Available flags: `.arcMode`, `.unrollLong`, `.none`.

---

## Choosing a layer

| Need | Use |
|---|---|
| Distance / bearing / destination / area | Simple API |
| Custom ellipsoid only | Simple API + `on:` parameter |
| Many points along one geodesic | `GeodesicLine` |
| Incremental polygon construction | `GeodesicPolygon` |
| Reduced length, geodesic scales, signed area | `Geodesic.generalDirect` / `generalInverse` |
| Arc-mode (degrees instead of metres) | `genPosition(flags: .arcMode, …)` |

---

## Accuracy

Identical numerics to upstream GeographicLib — sub-millimetre at any distance on Earth. The Swift layer adds no rounding.

---

## Contributing

Issues, PRs, and feature requests welcome.

- Public Swift API lives in `Sources/SwiftGeographicLib/`.
- Vendored C library lives in `Sources/geographiclib/` — do not modify unless syncing upstream.
- Tests use [Swift Testing](https://developer.apple.com/documentation/testing); add new tests under `Tests/SwiftGeographicLibTests/`.

```bash
swift build
swift test
```

---

## License

MIT. See [LICENSE](LICENSE). GeographicLib itself is also MIT-licensed.

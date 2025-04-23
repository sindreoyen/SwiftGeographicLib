# 1 SwiftGeographicLib

Ready-to-use Swift wrapper for the geodesic routines from the renowned [GeographicLib](https://geographiclib.sourceforge.io/).  
Under the hood it calls the C library, but exposes a Swifty, type-safe API.

## 1.1 Installation

Use the Swift Package Manager. In your `Package.swift`:

```swift
dependencies: [
  .package(
    url: "https://github.com/sindreoyen/SwiftGeographicLib.git",
    .upToNextMinor(from: "1.0.1")
  )
]
```

## 1.2 Masks & Flags

SwiftGeographicLib provides two `OptionSet` types to mirror the C bitmasks:

```swift
/// geod_mask values
public struct GeodesicMask: OptionSet {
  public let rawValue: UInt32
  public init(rawValue: UInt32) { self.rawValue = rawValue }

  public static let none          = GeodesicMask([])
  public static let latitude      = GeodesicMask(rawValue: 1<<7)
  public static let longitude     = GeodesicMask(rawValue: (1<<8)|(1<<3))
  public static let azimuth       = GeodesicMask(rawValue: 1<<9)
  public static let distance      = GeodesicMask(rawValue: (1<<10)|(1<<0))
  public static let distanceIn    = GeodesicMask(rawValue: (1<<11)|(1<<0)|(1<<1))
  public static let reducedLength = GeodesicMask(rawValue: (1<<12)|(1<<0)|(1<<2))
  public static let scale         = GeodesicMask(rawValue: (1<<13)|(1<<0)|(1<<2))
  public static let area          = GeodesicMask(rawValue: (1<<14)|(1<<4))
  public static let all: GeodesicMask = [
    .latitude, .longitude, .azimuth,
    .distance, .distanceIn, .reducedLength,
    .scale, .area
  ]
}

/// geod_flags values
public struct GeodesicFlags: OptionSet {
  public let rawValue: UInt32
  public init(rawValue: UInt32) { self.rawValue = rawValue }

  public static let none       = GeodesicFlags([])
  public static let arcMode    = GeodesicFlags(rawValue: 1<<0)
  public static let unrollLong = GeodesicFlags(rawValue: 1<<15)
}
```

Place those in `Sources/SwiftGeographicLib/Masks.swift` (or similar).

---

# 2 SwiftGeographicLib Usage Guide

This library gives you three main APIs to solve geodesic problems on an ellipsoid:

1. **`Geodesic`** – static direct/inverse calls  
2. **`GeodesicLine`** – incremental “walk a geodesic” API  
3. **`GeodesicPolygon`** – accumulate points/edges to get perimeter & area  

---

## 2.1 Geodesic

### `direct(from:distance:azimuth:geodesic:)`

```swift
let start = (lat: 40.64, lon: -73.78)   // JFK
let dest  = Geodesic.direct(
  from: start,
  distance: 10_000_000,                // 10 000 km
  azimuth: 45.0                        // north-east
)
// dest.latitude, dest.longitude
```

### `generalDirect(from:azimuth:flags:s12_a12:geodesic:)`

```swift
let (lat2, lon2, azi2,
     s12, m12, M12, M21, S12,
     a12) = Geodesic.generalDirect(
  from: start,
  azimuth: 45,
  flags: .all,      // all outputs
  s12_a12: 10e6
)
```

### `inverse(between:and:geodesic:)`

```swift
let a = (lat: 40.64, lon: -73.78)
let b = (lat: 1.36,  lon: 103.99)
let (distance, fwd, rev) = Geodesic.inverse(between: a, and: b)
```

### `generalInverse(between:and:geodesic:)`

```swift
let (a12, s12, azi1, azi2, m12, M12, M21, S12) =
  Geodesic.generalInverse(between: a, and: b)
```

---

## 2.2 GeodesicLine

Use this when you want to step along a geodesic:

### Initialize

```swift
import SwiftGeographicLib

// 1) Basic init (no endpoint pinned)
let caps: GeodesicMask = [.distanceIn, .longitude]
let line = GeodesicLine(
  from: (lat: 40.64, lon: -73.78),
  azimuth: 45.0,
  caps: caps
)

// 2) Direct init (endpoint fixed)
let line2 = GeodesicLine(
  directFrom: (lat: 40.64, lon: -73.78),
  azimuth: 45.0,
  distance: 10_000_000,
  caps: .all
)
```

### Query positions

```swift
// Simple: by distance
let pt1 = line.position(distance: 1_000_000)

// Full: all outputs
let (lat, lon, azi2, s12, m12, M12, M21, S12, a12) =
  line.genPosition(flags: .arcMode, s12_a12: 100.0)
```

### Adjust “third point”

```swift
line.setDistance(500_000)
line.genSetDistance(flags: .arcMode, s13_a13: 4.5)
```

---

## 2.3 GeodesicPolygon

Accumulate vertices or edges to get perimeter & area:

```swift
let poly = GeodesicPolygon(polyline: false)
poly.addPoint((lat: 0.0, lon: 0.0))
poly.addEdge(azimuth: 90, distance: 111_000)
let (count, area, perimeter) = poly.compute(reverse: false, signed: true)
```

### “Test” methods

```swift
let (_, testArea, testPerim) =
  poly.testPoint((lat: 1.5, lon: 0.5))
let (_, testArea2, testPerim2) =
  poly.testEdge(azimuth: 180, distance: 50_000)
// none of these mutate `poly`—a fresh compute() still returns the original.
```

### Quick one-liner

```swift
let coords = [(lat:0, lon:0), (lat:0, lon:1), (lat:1, lon:1), (lat:1, lon:0)]
let (area, peri) = GeodesicPolygon.area(of: coords)
```

> **Tip:** All APIs default to WGS-84 unless you supply another `GeodGeodesic` model.

---

# 3 Contributing

Feel free to open issues, suggest features, or submit pull requests.  
All methods live in `Sources/SwiftGeographicLib` and tests in `Tests/SwiftGeographicLibTests`.  
Thank you for your contributions!

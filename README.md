# 1 SwiftGeographicLib
Ready-to-use Swift wrapper for geodesic methods from the renowned library GeographicLib. The Swift wrapper is built on top of the C version of the library.
 
## 1.1 Installation
You can install the library using Swift Package Manager. Add the following line to your `Package.swift` dependencies array:

```swift
.package(url: "https://github.com/sindreoyen/SwiftGeographicLib.git", branch: "main")
```

# 2 SwiftGeographicLib Usage Guide

This library provides Swift-friendly wrappers around the C geodesic routines from GeographicLib. It lets you compute accurate distances, bearings, and areas on an ellipsoidal model of the Earth (default WGS-84) via three main APIs:

1. **`Geodesic`** – one-off static functions for direct/inverse problems  
2. **`GeodesicLine`** – incremental “line” API for stepping along a geodesic  
3. **`GeodesicPolygon`** – accumulate points or edges to compute perimeter & area  

---

## 2.1 Geodesic

### `direct(from:distance:azimuth:geodesic:)`

Solve the **direct problem** (point + azimuth + distance ⇒ endpoint):

```swift
let start = (lat: 40.64, lon: -73.78)               // JFK Airport
let d = 10_000_000.0                              // 10 000 km
let azi = 45.0                                    // north-east
let dest = Geodesic.direct(from: start,
                           distance: d,
                           azimuth: azi)
// dest.latitude, dest.longitude hold the endpoint coordinates
```

### `generalDirect(from:azimuth:flags:s12_a12:geodesic:)`

Solve the **general direct problem**, returning extra quantities:

```swift
let (lat2, lon2, azi2,
     s12, m12, M12, M21, S12,
     a12) = Geodesic.generalDirect(
        from: start,
        azimuth: azi,
        flags: GEOD_ALL,           // request all outputs
        s12_a12: d
     )

// • lat2, lon2, azi2: endpoint lat/lon/bearing  
// • s12             : distance (m)  
// • m12             : reduced length (m)  
// • M12, M21        : geodesic scales (dimensionless)  
// • S12             : area under the geodesic (m²)  
// • a12             : arc length (°)
```

---

### `inverse(between:and:geodesic:)`

Solve the **inverse problem** (two points ⇒ distance & azimuths):

```swift
let a = (lat: 40.64, lon: -73.78)    // JFK
let b = (lat: 1.36,  lon: 103.99)    // Singapore Changi
let (s, fwd, rev) = Geodesic.inverse(between: a, and: b)
// s   = distance in meters
// fwd = forward azimuth at A (°)
// rev = forward azimuth at B (°)
```

### `generalInverse(between:and:geodesic:)`

Get extended inverse outputs:

```swift
let (a12, s12, azi1, azi2, m12, M12, M21, S12) =
    Geodesic.generalInverse(between: a, and: b)
// same fields as generalDirect but for the inverse problem
```

---

## 2.2 GeodesicLine

Use `GeodesicLine` when you want to **walk** along a geodesic:

### Initialize

- **Basic** (no endpoint known yet):

  ```swift
  let caps: UInt32 = GEOD_DISTANCE_IN  // allow distance as input
                | GEOD_LONGITUDE      // allow computing longitude
  let line = GeodesicLine(
      from: (lat: 40.64, lon: -73.78),
      azimuth: 45.0,
      caps: caps
  )
  ```

- **Direct** (endpoint fixed at construction):

  ```swift
  let line2 = GeodesicLine(
      directFrom: (lat: 40.64, lon: -73.78),
      azimuth: 45.0,
      distance: 10_000_000,
      caps: GEOD_ALL
  )
  ```

### Query Points

- **Position by distance**  
  (requires `GEOD_DISTANCE_IN` + `GEOD_LONGITUDE` in `caps`)

  ```swift
  let pt = line.position(distance: 1_000_000)
  // pt.latitude, pt.longitude
  ```

- **General position**  
  to retrieve all requested quantities for a given distance or arc:

  ```swift
  let (lat, lon, azi2, s12, m12, M12, M21, S12, a12) =
      line.genPosition(
         flags: GEOD_ARCMODE,   // or GEOD_NOFLAGS
         s12_a12: 100.0         // meters or degrees
      )
  ```

### Change the “third point”

After a basic init (without endpoint):

- **Set by distance**:
  ```swift
  line.setDistance(500_000)
  ```
- **Set by arc or distance**:
  ```swift
  line.genSetDistance(flags: GEOD_ARCMODE,
                      s13_a13: 4.5)  // arc-length in degrees
  ```

---

## 2.3 GeodesicPolygon

Compute **perimeter** & **area** by streaming in vertices or edges.

### Initialize

```swift
// polygon: area + perimeter
let poly = GeodesicPolygon(polyline: false)

// or a polyline: only perimeter
let pl = GeodesicPolygon(polyline: true)
```

### Add by point

```swift
poly.addPoint((lat: 0.0, lon: 0.0))
poly.addPoint((lat: 0.0, lon: 1.0))
poly.addPoint((lat: 1.0, lon: 1.0))
```

### Add by edge

```swift
// from the last point, go 90° for 111 km
poly.addEdge(azimuth: 90.0, distance: 111_000)
```

### Compute results

```swift
let (count, area, perimeter) = poly.compute(
    reverse: false,
    signed: true
)
// • count     : #points/edges processed
// • area      : area in m² (0 for polyline)
// • perimeter : length in m
```

### “Test” methods

Compute what _would_ happen if you added one more point or edge, **without** modifying the internal state:

```swift
let (n, testArea, testPerim) =
    poly.testPoint((lat: 1.5, lon: 0.5))

let (m, testArea2, testPerim2) =
    poly.testEdge(azimuth: 180.0, distance: 50_000)
```

Internal state remains unchanged, so a subsequent `poly.compute()` returns the same original `(area, perimeter)`.

---

### One-Line Polygon Area

For quick closed‐polygon area/perimeter in one call:

```swift
let coords = [
  (lat: 0.0, lon: 0.0),
  (lat: 0.0, lon: 1.0),
  (lat: 1.0, lon: 1.0),
  (lat: 1.0, lon: 0.0)
]
let (area, perimeter) = GeodesicPolygon.area(of: coords)
```

---

> **Tip:** All routines default to WGS-84 unless you pass a custom `GeodGeoDesic` model when calling.
 
# 3 Contributing
If you encounter any bugs or want to suggest new features, please submit a pull request. You can also report any issues, and I will address them when I have the opportunity. All contributions are welcome! Please note that all implemented methods should be organized in the appropriate folder locations and tested using the latest testing framework, `Swift Testing`.

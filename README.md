# SwiftGeographicLib
Ready-to-use Swift wrapper for geodesic methods from the renowned library GeographicLib. The Swift wrapper is built on top of the C version of the library.
 
## Installation
You can install the library using Swift Package Manager. Add the following line to your `Package.swift` dependencies array:

```swift
.package(url: "https://github.com/sindreoyen/SwiftGeographicLib.git", branch: "main")
```

## Current Methods
The library currently supports the following methods:
- `Direct`: Calculate the destination point given a starting coordinate, azimuth, and distance. Supports the use of custom ellipsoids via the `GeoDesic` struct and defaults to WGS84.
 
## Contributing
If you would like to contribute to this project to add support for more method, please fork the repository and submit a pull request. You can also submit an issue and I will look into it. All contributions are welcome!

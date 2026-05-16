//
//  CLLocationCoordinate2D+Geodesic.swift
//  SwiftGeographicLib
//
//  Simpler, discoverable API surface for common geodesic operations.
//  Wraps the existing `Geodesic` static calls with named result types
//  and Apple-native `CLLocationCoordinate2D` inputs.
//

import CoreLocation

extension CLLocationCoordinate2D {

    // MARK: - Destination

    /// Returns the destination coordinate reached by travelling `distance` metres
    /// along the given initial `bearing` (degrees clockwise from north) on the
    /// chosen ellipsoid.
    ///
    /// - Parameters:
    ///   - bearing: Initial bearing in degrees (0 = north, 90 = east).
    ///   - distance: Distance in metres.
    ///   - geodesic: Ellipsoid model. Defaults to WGS-84.
    public func destination(
        bearing: Double,
        distance: Double,
        on geodesic: GeodGeodesic = .WGS84
    ) -> CLLocationCoordinate2D {
        Geodesic.direct(
            from: (lat: latitude, lon: longitude),
            distance: distance,
            azimuth: bearing,
            geodesic: geodesic
        )
    }

    // MARK: - Distance

    /// Returns the shortest geodesic distance in metres between `self` and `other`.
    ///
    /// - Parameters:
    ///   - other: Destination coordinate.
    ///   - geodesic: Ellipsoid model. Defaults to WGS-84.
    public func distance(
        to other: CLLocationCoordinate2D,
        on geodesic: GeodGeodesic = .WGS84
    ) -> Double {
        Geodesic.inverse(
            between: (lat: latitude, lon: longitude),
            and: (lat: other.latitude, lon: other.longitude),
            geodesic: geodesic
        ).s12
    }

    // MARK: - Bearing

    /// Returns the initial bearing in degrees from `self` to `other` (azimuth at
    /// the start of the geodesic).
    public func initialBearing(
        to other: CLLocationCoordinate2D,
        on geodesic: GeodGeodesic = .WGS84
    ) -> Double {
        Geodesic.inverse(
            between: (lat: latitude, lon: longitude),
            and: (lat: other.latitude, lon: other.longitude),
            geodesic: geodesic
        ).azi1
    }

    /// Returns the final bearing in degrees at `other`, i.e. the forward azimuth
    /// of the geodesic at its endpoint.
    public func finalBearing(
        to other: CLLocationCoordinate2D,
        on geodesic: GeodGeodesic = .WGS84
    ) -> Double {
        Geodesic.inverse(
            between: (lat: latitude, lon: longitude),
            and: (lat: other.latitude, lon: other.longitude),
            geodesic: geodesic
        ).azi2
    }
}

// MARK: - Polygon helpers

extension Geodesic {

    /// Geodesic polygon area in square metres for an ordered ring of coordinates.
    public static func area(
        of coordinates: [CLLocationCoordinate2D],
        on geodesic: GeodGeodesic = .WGS84
    ) -> Double {
        GeodesicPolygon.area(
            of: coordinates.map { (lat: $0.latitude, lon: $0.longitude) },
            model: geodesic
        ).area
    }

    /// Geodesic polygon perimeter in metres for an ordered ring of coordinates.
    public static func perimeter(
        of coordinates: [CLLocationCoordinate2D],
        on geodesic: GeodGeodesic = .WGS84
    ) -> Double {
        GeodesicPolygon.area(
            of: coordinates.map { (lat: $0.latitude, lon: $0.longitude) },
            model: geodesic
        ).perimeter
    }
}

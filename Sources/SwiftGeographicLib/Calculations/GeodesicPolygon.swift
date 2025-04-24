//
//  GeodesicPolygon.swift
//  SwiftGeographicLib
//
//  Created by Sindre on 23/04/2025.
//

import geographiclib
import CoreLocation

/// A Swift wrapper for constructing and measuring geodesic polygons (or polylines) on an ellipsoid.
///
/// You can add vertices or edges incrementally, compute the accumulated perimeter
/// and area, and even test a tentative final point or edge without modifying the state.
public class GeodesicPolygon {
    // MARK: - Attributes
    
    /// The underlying C struct for polygon state.
    var poly = geod_polygon()

    // MARK: - Init
    
    /// Creates a new polygon (or polyline) accumulator.
    ///
    /// - Parameter polyline: Pass `true` for a polyline (only perimeter), `false` for a closed polygon (area + perimeter).
    public init(polyline: Bool = false) {
        geod_polygon_init(&poly, polyline ? 1 : 0)
    }

    // MARK: - Methods
    
    // MARK: Clear
    /// Clears all accumulated vertices and resets the polygon/polyline.
    public func clear() {
        geod_polygon_clear(&poly)
    }

    // MARK: Add points and edges
    /// Adds a vertex to the polygon or polyline by geographic coordinate.
    ///
    /// - Parameters:
    ///   - coordinate: The latitude and longitude of the new point (degrees).
    ///   - model: The ellipsoidal model to use (defaults to WGS-84).
    public func addPoint(
        _ coordinate: (lat: CLLocationDegrees, lon: CLLocationDegrees),
        model: GeodGeodesic = .WGS84
    ) {
        var g = geod_geodesic()
        geod_init(&g, model.semiMajorAxis, model.flattening)
        geod_polygon_addpoint(&g, &poly, coordinate.lat, coordinate.lon)
    }

    /// Adds an edge from the current vertex to a new vertex specified by azimuth and distance.
    ///
    /// - Parameters:
    ///   - azimuth: The forward azimuth from the current vertex (degrees).
    ///   - distance: The distance from the current vertex to the new vertex (meters).
    ///   - model: The ellipsoidal model to use (defaults to WGS-84).
    public func addEdge(
        azimuth azi: Double,
        distance s: Double,
        model: GeodGeodesic = .WGS84
    ) {
        var g = geod_geodesic()
        geod_init(&g, model.semiMajorAxis, model.flattening)
        geod_polygon_addedge(&g, &poly, azi, s)
    }

    // MARK: Compute area and perimeter
    /// Computes the accumulated perimeter (and area if polygon) so far.
    ///
    /// - Parameters:
    ///   - reverse: If `true`, clockwise traversal counts as positive area.
    ///   - signed: If `true`, returns a signed area if traversed in the opposite sense; otherwise returns area of complement.
    /// - Returns: A tuple containing
    ///   - `n`: Number of vertices processed,
    ///   - `area`: Polygon area in m² (0 if polyline),
    ///   - `perimeter`: Perimeter or polyline length in meters.
    @discardableResult
    public func compute(
        reverse: Bool = false,
        signed: Bool = true
    ) -> (n: UInt32, area: Double, perimeter: Double) {
        var g = geod_geodesic()
        geod_init(&g, GeodGeodesic.WGS84.semiMajorAxis, GeodGeodesic.WGS84.flattening)
        var A = 0.0, P = 0.0
        let n = geod_polygon_compute(&g, &poly, reverse ? 1 : 0, signed ? 1 : 0, &A, &P)
        return (n, A, P)
    }

    // MARK: Test point and edge
    /// Tests the effect of adding a final point without modifying the state.
    ///
    /// - Parameters:
    ///   - coordinate: The test point's latitude and longitude (degrees).
    ///   - reverse: If `true`, clockwise traversal counts as positive area.
    ///   - signed: If `true`, returns a signed area if opposite sense.
    /// - Returns: A tuple `(n, area, perimeter)` as in `compute()`, but provisional.
    @discardableResult
    public func testPoint(
        _ coordinate: (lat: CLLocationDegrees, lon: CLLocationDegrees),
        reverse: Bool = false,
        signed: Bool = true
    ) -> (n: UInt32, area: Double, perimeter: Double) {
        var g = geod_geodesic()
        geod_init(&g, GeodGeodesic.WGS84.semiMajorAxis, GeodGeodesic.WGS84.flattening)
        var A = 0.0, P = 0.0
        let n = geod_polygon_testpoint(&g, &poly, coordinate.lat, coordinate.lon, reverse ? 1 : 0, signed ? 1 : 0, &A, &P)
        return (n, A, P)
    }

    /// Tests the effect of adding a final edge without modifying the state.
    ///
    /// - Parameters:
    ///   - azimuth: The azimuth from the current vertex (degrees).
    ///   - distance: The distance to the test endpoint (meters).
    ///   - reverse: If `true`, clockwise traversal counts as positive area.
    ///   - signed: If `true`, returns a signed area if opposite sense.
    /// - Returns: A tuple `(n, area, perimeter)` as in `compute()`, but provisional.
    @discardableResult
    public func testEdge(
        azimuth azi: Double,
        distance s: Double,
        reverse: Bool = false,
        signed: Bool = true
    ) -> (n: UInt32, area: Double, perimeter: Double) {
        var g = geod_geodesic()
        geod_init(&g, GeodGeodesic.WGS84.semiMajorAxis, GeodGeodesic.WGS84.flattening)
        var A = 0.0, P = 0.0
        let n = geod_polygon_testedge(&g, &poly, azi, s, reverse ? 1 : 0, signed ? 1 : 0, &A, &P)
        return (n, A, P)
    }

    // MARK: Static area and perimeter
    /// Computes the area and perimeter of a closed polygon in one call.
    ///
    /// - Parameters:
    ///   - coordinates: An array of (lat, lon) tuples defining the polygon vertices (degrees).
    ///   - model: The ellipsoidal model to use (defaults to WGS-84).
    /// - Returns: A tuple `(area, perimeter)` in (m², m).
    public static func area(
        of coordinates: [(lat: Double, lon: Double)],
        model: GeodGeodesic = .WGS84
    ) -> (area: Double, perimeter: Double) {
        var g = geod_geodesic()
        geod_init(&g, model.semiMajorAxis, model.flattening)
        let n = coordinates.count
        var lats = coordinates.map { $0.lat }
        var lons = coordinates.map { $0.lon }
        var A = 0.0, P = 0.0
        geod_polygonarea(&g, &lats, &lons, Int32(n), &A, &P)
        return (A, P)
    }
}

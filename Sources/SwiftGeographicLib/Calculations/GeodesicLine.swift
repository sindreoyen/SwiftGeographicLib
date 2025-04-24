//
//  GeodesicLine.swift
//  SwiftGeographicLib
//
//  Created by Sindre on 23/04/2025.
//

import geographiclib
import CoreLocation

/// A Swift wrapper around a single geodesic line on an ellipsoid.
///
/// This class lets you incrementally solve points along a geodesic,
/// either by initializing a line and stepping along it, or by constructing
/// it to a fixed endpoint and querying positions along the arc or distance.
public class GeodesicLine {
    // MARK: - Attributes
    
    /// The underlying C struct for geodesic line state.
    var line = geod_geodesicline()

    // MARK: - Init
    
    /// Initializes a geodesic line from a start point and azimuth.
    ///
    /// Use this when you want fine-grained control over stepping along the line.
    ///
    /// - Parameters:
    ///   - coordinate: The starting point's latitude and longitude (degrees).
    ///   - azi1: The initial azimuth from the start point (degrees).
    ///   - caps: A bitmask of `geod_mask` flags indicating which quantities may be returned or used as input.
    ///   - model: The ellipsoidal model to use (defaults to WGS-84).
    public init(
        from coordinate: (lat: CLLocationDegrees, lon: CLLocationDegrees),
        azimuth azi1: Double,
        caps: GeodesicMask,
        geodesic model: GeodGeodesic = .WGS84
    ) {
        var g = geod_geodesic()
        geod_init(&g, model.semiMajorAxis, model.flattening)
        geod_lineinit(&line, &g, coordinate.lat, coordinate.lon, azi1, caps.rawValue)
    }

    /// Initializes a geodesic line by directly solving the direct problem.
    ///
    /// This sets point 3 of the line to the endpoint of a direct geodesic.
    ///
    /// - Parameters:
    ///   - coordinate: The starting point's latitude and longitude (degrees).
    ///   - azi1: The initial azimuth from the start point (degrees).
    ///   - distance: The distance along the geodesic from the start to the endpoint (meters).
    ///   - caps: A bitmask of `geod_mask` flags indicating which quantities may be returned.
    ///   - model: The ellipsoidal model to use (defaults to WGS-84).
    public convenience init(
        directFrom coordinate: (lat: CLLocationDegrees, lon: CLLocationDegrees),
        azimuth azi1: Double,
        distance s12: Double,
        caps: GeodesicMask,
        geodesic model: GeodGeodesic = .WGS84
    ) {
        self.init(from: coordinate, azimuth: azi1, caps: caps, geodesic: model)
        var g = geod_geodesic()
        geod_init(&g, model.semiMajorAxis, model.flattening)
        geod_directline(&line, &g, coordinate.lat, coordinate.lon, azi1, s12, caps.rawValue)
    }

    // MARK: - Methods
    
    // MARK: Position
    /// Computes the position at a given distance along the line.
    ///
    /// - Parameter distance: The distance from the start point (meters).
    /// - Returns: The latitude and longitude of the computed point.
    public func position(distance s12: Double) -> CLLocationCoordinate2D {
        var lat2 = 0.0, lon2 = 0.0, azi2 = 0.0
        geod_position(&line, s12, &lat2, &lon2, &azi2)
        return CLLocationCoordinate2D(latitude: lat2, longitude: lon2)
    }
    
    // MARK: General Position
    /// Computes the general position along the line, returning all requested geodesic quantities.
    ///
    /// - Parameters:
    ///   - flags: Bitmask of `geod_flags` controlling arc-mode vs. distance and longitude unrolling.
    ///   - s12_a12: Distance (meters) or arc length (degrees) depending on flags.
    /// - Returns: A tuple containing:
    ///   - `lat2`,`lon2`: Destination coordinates (degrees).
    ///   - `azi2`: Forward azimuth at destination (degrees).
    ///   - `s12`: Distance from start to destination (meters).
    ///   - `m12`: Reduced length of geodesic (meters).
    ///   - `M12`,`M21`: Geodesic scales (dimensionless).
    ///   - `S12`: Area under the geodesic (m²).
    ///   - `a12`: Arc length from start to destination (degrees).
    @discardableResult
    public func genPosition(
        flags: GeodesicFlags,
        s12_a12: Double
    ) -> (
        lat2: Double,
        lon2: Double,
        azi2: Double,
        s12: Double,
        m12: Double,
        M12: Double,
        M21: Double,
        S12: Double,
        a12: Double
    ) {
        var lat2 = 0.0, lon2 = 0.0, azi2 = 0.0
        var s12 = 0.0, m12 = 0.0, M12 = 0.0, M21 = 0.0, S12 = 0.0
        let a12 = geod_genposition(&line,
                                   flags.rawValue,
                                    s12_a12,
                                    &lat2,
                                    &lon2,
                                    &azi2,
                                    &s12,
                                    &m12,
                                    &M12,
                                    &M21,
                                    &S12)
        return (lat2, lon2, azi2, s12, m12, M12, M21, S12, a12)
    }

    // MARK: Set Distance
    /// Sets the internal "third point" distance for future calls to `position`.
    ///
    /// - Parameter s13: Distance from the start point to the internal reference point (meters).
    public func setDistance(_ s13: Double) {
        geod_setdistance(&line, s13)
    }

    // MARK: Set Distance with Flags
    /// Sets the internal "third point" by distance or arc length.
    ///
    /// - Parameters:
    ///   - flags: Either `.none` or `.arcMode` to select distance vs. arc mode.
    ///   - s13_a13: Distance (meters) or arc length (degrees) for the reference point.
    public func genSetDistance(flags: GeodesicFlags, s13_a13: Double) {
        geod_gensetdistance(&line, flags.rawValue, s13_a13)
    }
}

//
//  Geodesic.swift
//  SwiftGeographicLib
//
//  Created by Sindre on 23/04/2025.
//

import geographiclib
import CoreLocation

/// Swift wrappers for the C geodesic routines from GeographicLib.
/// Provides methods to solve direct and inverse geodesic problems using a specified geodesic model (e.g., WGS84).
/// `Geodesic` is implemented as a static enum to provide a clean interface and avoid instantiation.
public enum Geodesic {
    // MARK: - Methods
    
    // MARK: Direct
    /// Solves the direct geodesic problem.
    ///
    /// Calculates the destination point given a starting point, distance, and azimuth.
    ///
    /// - Parameters:
    ///   - coordinate: A tuple representing the starting latitude and longitude in degrees.
    ///   - s12: The distance to the destination point in meters.
    ///   - azi1: The azimuth from the starting point to the destination point in degrees.
    ///   - geodesic: The geodesic model to use for calculations (default is WGS-84).
    /// - Returns: A `CLLocationCoordinate2D` representing the destination point.
    public static func direct(
        from coordinate: (lat: CLLocationDegrees, lon: CLLocationDegrees),
        distance s12: Double,
        azimuth azi1: Double,
        geodesic model: GeodGeodesic = .WGS84
    ) -> CLLocationCoordinate2D {
        var g = geod_geodesic()
        geod_init(&g, model.semiMajorAxis, model.flattening)
        var lat2 = 0.0, lon2 = 0.0, azi2 = 0.0
        geod_direct(&g,
                    coordinate.lat,
                    coordinate.lon,
                    azi1,
                    s12,
                    &lat2,
                    &lon2,
                    &azi2)
        return CLLocationCoordinate2D(latitude: lat2, longitude: lon2)
    }
    
    // MARK: General Direct
    /// Solves the general direct geodesic problem with extended output.
    ///
    /// Allows for calculating additional geodesic quantities along with the destination point.
    ///
    /// - Parameters:
    ///   - coordinate: Starting point as a tuple of latitude and longitude.
    ///   - azi1: Initial azimuth in degrees.
    ///   - flags: Bitmask of which quantities to compute.
    ///   - s12_a12: Distance or arc length, depending on flags.
    ///   - geodesic: Geodesic model to use (defaults to WGS-84).
    /// - Returns: A tuple containing destination coordinates, reverse azimuth, distance, reduced length, geodesic scales, area, and arc length.
    @discardableResult
    public static func generalDirect(
        from coordinate: (lat: CLLocationDegrees, lon: CLLocationDegrees),
        azimuth azi1: Double,
        flags: GeodesicFlags = .none,
        s12_a12: Double,
        geodesic model: GeodGeodesic = .WGS84
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
        var g = geod_geodesic()
        geod_init(&g, model.semiMajorAxis, model.flattening)
        var lat2 = 0.0, lon2 = 0.0, azi2 = 0.0
        var s12 = 0.0, m12 = 0.0, M12 = 0.0, M21 = 0.0, S12 = 0.0
        let a12 = geod_gendirect(&g,
                                 coordinate.lat,
                                 coordinate.lon,
                                 azi1,
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
    
    // MARK: Inverse
    /// Solves the inverse geodesic problem.
    ///
    /// Calculates the shortest distance and azimuths between two geographic points.
    ///
    /// - Parameters:
    ///   - point1: Start coordinate (lat, lon).
    ///   - point2: End coordinate (lat, lon).
    ///   - geodesic: Geodesic model to use (defaults to WGS-84).
    /// - Returns: A tuple with distance in meters and forward/reverse azimuths in degrees.
    public static func inverse(
        between point1: (lat: CLLocationDegrees, lon: CLLocationDegrees),
        and point2: (lat: CLLocationDegrees, lon: CLLocationDegrees),
        geodesic model: GeodGeodesic = .WGS84
    ) -> (s12: Double, azi1: Double, azi2: Double) {
        var g = geod_geodesic()
        geod_init(&g, model.semiMajorAxis, model.flattening)
        var s12 = 0.0, azi1 = 0.0, azi2 = 0.0
        geod_inverse(&g,
                     point1.lat,
                     point1.lon,
                     point2.lat,
                     point2.lon,
                     &s12,
                     &azi1,
                     &azi2)
        return (s12, azi1, azi2)
    }
    
    // MARK: General Inverse
    /// Solves the general inverse geodesic problem with extended output.
    ///
    /// Includes computation of distance, azimuths, geodesic scales, and area between two points.
    ///
    /// - Parameters:
    ///   - point1: Start point (lat, lon).
    ///   - point2: End point (lat, lon).
    ///   - geodesic: Geodesic model to use.
    /// - Returns: A tuple with arc length, distance, azimuths, reduced length, geodesic scales, and area.
    @discardableResult
    public static func generalInverse(
        between point1: (lat: CLLocationDegrees, lon: CLLocationDegrees),
        and point2: (lat: CLLocationDegrees, lon: CLLocationDegrees),
        geodesic model: GeodGeodesic = .WGS84
    ) -> (
        a12: Double,
        s12: Double,
        azi1: Double,
        azi2: Double,
        m12: Double,
        M12: Double,
        M21: Double,
        S12: Double
    ) {
        var g = geod_geodesic()
        geod_init(&g, model.semiMajorAxis, model.flattening)
        var s12 = 0.0, azi1 = 0.0, azi2 = 0.0
        var m12 = 0.0, M12 = 0.0, M21 = 0.0, S12 = 0.0
        let a12 = geod_geninverse(&g,
                                  point1.lat,
                                  point1.lon,
                                  point2.lat,
                                  point2.lon,
                                  &s12,
                                  &azi1,
                                  &azi2,
                                  &m12,
                                  &M12,
                                  &M21,
                                  &S12)
        return (a12, s12, azi1, azi2, m12, M12, M21, S12)
    }
}

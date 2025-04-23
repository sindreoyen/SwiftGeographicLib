//
//  GeodGeoDesic.swift
//  SwiftGeographicLib
//
//  Created by Sindre on 23/04/2025.
//

/// A structure representing a geodesic.
/// This structure is used to define the parameters of a geodesic calculation.
/// It contains the semi-major axis (a) and flattening (f) of the ellipsoid.
public struct GeodGeodesic: Sendable {
    // MARK: - Attributes
    
    // MARK: Known ellipsoids
    public static let WGS84 = GeodGeodesic(a: 6_378_137.0, f: 1.0 / 298.257223563)
    
    // MARK: Struct attributes
    let semiMajorAxis: Double
    let flattening: Double
    
    // MARK: - Init
    
    /// Initializes a new `GeoDesic` instance with the specified semi-major axis and flattening.
    /// - Parameters:
    ///   - semiMajorAxis: The semi-major axis of the ellipsoid in meters. I.e., the equatorial radius.
    ///   - flattening: The flattening of the ellipsoid (f = (a - b) / a).
    init(a semiMajorAxis: Double, f flattening: Double) {
        self.semiMajorAxis = semiMajorAxis
        self.flattening = flattening
    }
}

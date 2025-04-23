//
//  Direct.swift
//  SwiftGeographicLib
//
//  Created by Sindre on 19/04/2025.
//

import geographiclib
import CoreLocation

/// Calculate the destination point given a starting point, distance, and azimuth.
/// Allows for specifying a custom geodesic model but defaults to WGS-84.
/// - Parameters:
///   - coordinate: The starting point's latitude and longitude.
///   - s12: The distance to the destination point in meters.
///   - azi1: The azimuth from the starting point to the destination point in degrees.
///   - geodesic: The geodesic model to use (default is WGS-84).
/// - Returns: The latitude and longitude of the destination point.
public func direct(
    from coordinate: (lat: CLLocationDegrees, lon: CLLocationDegrees),
    distance s12: Double,
    azimuth azi1: Double,
    geodesic swiftGeoDesic: GeoDesic = .WGS_84
) -> CLLocationCoordinate2D {

    // 1) Create the geodesic struct
    var geodesic = geod_geodesic()

    // 2) Initialize the geodesic struct to the specified model
    geod_init(&geodesic,
              swiftGeoDesic.semiMajorAxis,
              swiftGeoDesic.flattening)

    // 3) Prepare storage for results
    var lat2 = 0.0, lon2 = 0.0, azi2 = 0.0

    // 4) Call the direct solver
    geod_direct(&geodesic,
                coordinate.lat,
                coordinate.lon,
                azi1,
                s12,
                &lat2,
                &lon2,
                &azi2)

    return CLLocationCoordinate2D(
        latitude: lat2,
        longitude: lon2
    )
}

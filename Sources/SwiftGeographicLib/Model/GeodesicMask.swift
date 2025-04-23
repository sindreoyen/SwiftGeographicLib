//
//  GeodesicMask.swift
//  SwiftGeographicLib
//
//  Created by Sindre on 23/04/2025.
//

/// A set of bitwise masks specifying which quantities a geodesic‐line
/// object should compute or accept as input.
///
/// These mirror C’s `enum geod_mask` and are used when you initialize
/// a `GeodesicLine` (via `geod_lineinit`, `geod_directline`, etc.).
/// Combine them to request only the data you need, improving performance.
public struct GeodesicMask: OptionSet, Sendable {
    // MARK: - Attributes
    
    /// The raw value of the bitmask.
    public let rawValue: UInt32
    
    // MARK: - Init
    
    /// Creates a new `GeodesicMask` instance with the specified raw value.
    /// - Parameter rawValue: The raw value representing the bitmask.
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    
    /// No capabilities: compute **nothing** (not generally useful).
    public static let none = GeodesicMask([])
    
    /// Compute the **latitude** (lat₂) of the endpoint.
    ///
    /// This is always implied even if you don’t specify it.
    public static let latitude = GeodesicMask(rawValue: 1 << 7)
    
    /// Compute the **longitude** (lon₂) of the endpoint.
    ///
    /// Requires you to include this if you need longitude out of
    /// any `geod_position` or `geod_genposition` call.
    public static let longitude = GeodesicMask(rawValue: (1 << 8) | (1 << 3))
    
    /// Compute the **forward azimuth** (azi₂) at the endpoint.
    ///
    /// This is always implied even if you omit it explicitly.
    public static let azimuth = GeodesicMask(rawValue: 1 << 9)
    
    /// Compute the **distance** (s₁₂) from the start to the endpoint in meters.
    public static let distance = GeodesicMask(rawValue: (1 << 10) | (1 << 0))
    
    /// Allow **distance** (s₁₂ in meters) to be used as an **input**.
    ///
    /// Without this mask you can only specify the endpoint via arc‐length.
    public static let distanceIn = GeodesicMask(rawValue: (1 << 11) | (1 << 0) | (1 << 1))
    
    /// Compute the **reduced length** (m₁₂) of the geodesic in meters.
    public static let reducedLength = GeodesicMask(rawValue: (1 << 12) | (1 << 0) | (1 << 2))
    
    /// Compute the **geodesic scales** M₁₂ and M₂₁ (dimensionless).
    public static let geodesicScale = GeodesicMask(rawValue: (1 << 13) | (1 << 0) | (1 << 2))
    
    /// Compute the **area** (S₁₂) under the geodesic (in m²).
    public static let area = GeodesicMask(rawValue: (1 << 14) | (1 << 4))
    
    /// Request **all** computable quantities.
    ///
    /// Equivalent to:
    /// `[.latitude, .longitude, .azimuth, .distance,
    ///   .distanceIn, .reducedLength, .geodesicScale, .area]`
    public static let all: GeodesicMask = [
        .latitude, .longitude, .azimuth,
        .distance, .distanceIn, .reducedLength,
        .geodesicScale, .area
    ]
}

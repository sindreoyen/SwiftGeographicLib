//
//  GeodesicFlags.swift
//  SwiftGeographicLib
//
//  Created by Sindre on 23/04/2025.
//

/// A set of bitwise flags controlling the behavior of the general‐direct
/// (`geod_gendirect`) and general‐position (`geod_genposition`) routines.
///
/// These mirror C’s `enum geod_flags`.  Use them to:
/// - switch between **distance** and **arc‐length** mode, and
/// - request **longitude unrolling** so that your longitude output
///   accumulates multiple wrap‐arounds.
public struct GeodesicFlags: OptionSet, Sendable {
    // MARK: - Attributes
    
    /// The raw value representing the flags.
    public let rawValue: UInt32
    
    // MARK: - Init
    
    /// Initializes a new `GeodesicFlags` instance with the specified raw value.
    /// - Parameter rawValue: The raw value representing the flags.
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    
    // MARK: - OptionSet
    
    /// No special modes; distances are in meters, longitudes wrap at ±180°.
    public static let none = GeodesicFlags([])
    
    /// Interpret the input `s12_a12` (and return the output `a12`) as
    /// **arc‐length** in degrees rather than distance in meters.
    ///
    /// When set:
    /// - in **general direct**, you pass degrees of arc on the ellipsoid,
    ///   and it returns the corresponding distance in `s12`.
    /// - in **general position**, you advance by degrees of arc,
    ///   not meters.
    public static let arcMode = GeodesicFlags(rawValue: 1 << 0)
    
    /// “Unroll” the longitude so that successive calls accumulate
    /// past ±180°, giving a continuous longitude track.
    ///
    /// Without this flag, longitudes are normalized into the range
    /// [–180°, +180°].  With it, a path that crosses the antimeridian
    /// multiple times will show longitudes like 190°, 370°, etc.
    public static let longUnroll = GeodesicFlags(rawValue: 1 << 15)
    
    /// A convenience property to get all flags combined.
    /// This includes both `arcMode` and `longUnroll`.
    public static let all: GeodesicFlags = [.arcMode, .longUnroll]
}

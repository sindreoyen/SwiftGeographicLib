//
//  SimpleAPITests.swift
//  SwiftGeographicLibTests
//

import Testing
@testable import SwiftGeographicLib
import CoreLocation

@Suite("Simple API (CLLocationCoordinate2D)")
struct SimpleAPITests {

    private let jfk = CLLocationCoordinate2D(latitude: 40.6413, longitude: -73.7781)
    private let lhr = CLLocationCoordinate2D(latitude: 51.4700, longitude: -0.4543)

    @Test("destination(bearing:distance:) matches Geodesic.direct")
    func destinationMatchesDirect() {
        let bearing = 45.0
        let distance = 10_000.0
        let new = jfk.destination(bearing: bearing, distance: distance)
        let ref = Geodesic.direct(
            from: (lat: jfk.latitude, lon: jfk.longitude),
            distance: distance,
            azimuth: bearing
        )
        #expect(abs(new.latitude - ref.latitude) <= 1e-9)
        #expect(abs(new.longitude - ref.longitude) <= 1e-9)
    }

    @Test("distance(to:) is symmetric within tolerance")
    func distanceSymmetric() {
        let a = jfk.distance(to: lhr)
        let b = lhr.distance(to: jfk)
        #expect(abs(a - b) <= 1e-6)
    }

    @Test("distance(to:) JFK→LHR ≈ 5550 km")
    func distanceKnownValue() {
        let metres = jfk.distance(to: lhr)
        #expect(abs(metres - 5_550_000) <= 5_000)
    }

    @Test("destination then distance round-trips")
    func roundTrip() {
        let bearing = 123.0
        let distance = 250_000.0
        let dest = jfk.destination(bearing: bearing, distance: distance)
        let back = jfk.distance(to: dest)
        #expect(abs(back - distance) <= 1e-6)
    }

    @Test("initialBearing(to:) matches Geodesic.inverse azi1")
    func initialBearingMatches() {
        let b = jfk.initialBearing(to: lhr)
        let ref = Geodesic.inverse(
            between: (lat: jfk.latitude, lon: jfk.longitude),
            and: (lat: lhr.latitude, lon: lhr.longitude)
        ).azi1
        #expect(abs(b - ref) <= 1e-9)
    }

    @Test("finalBearing(to:) matches Geodesic.inverse azi2")
    func finalBearingMatches() {
        let b = jfk.finalBearing(to: lhr)
        let ref = Geodesic.inverse(
            between: (lat: jfk.latitude, lon: jfk.longitude),
            and: (lat: lhr.latitude, lon: lhr.longitude)
        ).azi2
        #expect(abs(b - ref) <= 1e-9)
    }

    @Test("Zero distance destination returns same coordinate")
    func zeroDistanceDestination() {
        let same = jfk.destination(bearing: 42.0, distance: 0.0)
        #expect(abs(same.latitude - jfk.latitude) <= 1e-9)
        #expect(abs(same.longitude - jfk.longitude) <= 1e-9)
    }

    @Test("Geodesic.area(of:) matches GeodesicPolygon.area(of:) for 1°×1° square")
    func areaMatchesPolygonStatic() {
        let square: [CLLocationCoordinate2D] = [
            .init(latitude: 0, longitude: 0),
            .init(latitude: 0, longitude: 1),
            .init(latitude: 1, longitude: 1),
            .init(latitude: 1, longitude: 0),
        ]
        let a = Geodesic.area(of: square)
        let ref = GeodesicPolygon.area(of: square.map { (lat: $0.latitude, lon: $0.longitude) }).area
        #expect(abs(a - ref) / ref <= 1e-9)
    }

    @Test("Geodesic.perimeter(of:) matches GeodesicPolygon.area(of:) perimeter")
    func perimeterMatchesPolygonStatic() {
        let square: [CLLocationCoordinate2D] = [
            .init(latitude: 0, longitude: 0),
            .init(latitude: 0, longitude: 1),
            .init(latitude: 1, longitude: 1),
            .init(latitude: 1, longitude: 0),
        ]
        let p = Geodesic.perimeter(of: square)
        let ref = GeodesicPolygon.area(of: square.map { (lat: $0.latitude, lon: $0.longitude) }).perimeter
        #expect(abs(p - ref) / ref <= 1e-9)
    }
}

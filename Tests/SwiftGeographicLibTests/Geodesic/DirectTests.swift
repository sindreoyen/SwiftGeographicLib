// DirectTests.swift
// SwiftGeographicLibTests

import Testing
@testable import SwiftGeographicLib
import CoreLocation

@Suite("Direct Method Tests")
struct DirectTests {

    @Test("Compute destination 1000 meters north from equator")
    func testDirectNorthFromEquator() {
        let start = (lat: 0.0, lon: 0.0)
        let result = Geodesic.direct(from: start, distance: 1000.0, azimuth: 0.0)

        // 1000 meters north should be very close to latitude ~0.009 degrees
        #expect(result.longitude <= 0.000001)
        #expect(abs(result.latitude - 0.008983) <= 0.0001)
    }

    @Test("Compute destination 1000 meters east from equator")
    func testDirectEastFromEquator() {
        let start = (lat: 0.0, lon: 0.0)
        let result = Geodesic.direct(from: start, distance: 1000.0, azimuth: 90.0)

        #expect(result.latitude <= 0.000001)
        #expect(abs(result.longitude - 0.008983) <= 0.0001)
    }

    @Test("Compute destination 10000 meters northeast from Norway")
    func testDirectFromNorway() {
        let start = (lat: 60.0, lon: 10.0)
        let result = Geodesic.direct(from: start, distance: 10000.0, azimuth: 45.0)

        #expect(result.latitude > start.lat)
        #expect(result.longitude > start.lon)
    }

    @Test("Zero distance should return the same point")
    func testDirectZeroDistance() {
        let start = (lat: 45.0, lon: 45.0)
        let result = Geodesic.direct(from: start, distance: 0.0, azimuth: 123.0)

        #expect(abs(result.latitude - start.lat) <= 0.000001)
        #expect(abs(result.longitude - start.lon) <= 0.000001)
    }
}

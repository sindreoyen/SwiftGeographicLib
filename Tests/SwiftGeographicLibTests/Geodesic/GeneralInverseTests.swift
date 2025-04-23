//
//  GeneralInverseTests.swift
//  SwiftGeographicLib
//
//  Created by Sindre on 23/04/2025.
//

import Testing
@testable import SwiftGeographicLib
import CoreLocation

@Suite("General Inverse Method Tests")
struct GeneralInverseTests {
    
    @Test("generalInverse matches inverse for equator 1° apart")
    func testGeneralInverseMatchesInverse() {
        let p1 = (lat: 0.0, lon: 0.0)
        let p2 = (lat: 0.0, lon: 1.0)
        let (s12, azi1, azi2) = Geodesic.inverse(between: p1, and: p2)
        let (_, s12G, azi1G, azi2G, _, _, _, _) = Geodesic.generalInverse(between: p1, and: p2)
        #expect(abs(s12G - s12)   <= 1e-9)
        #expect(abs(azi1G - azi1) <= 1e-9)
        #expect(abs(azi2G - azi2) <= 1e-9)
    }
    
    @Test("generalInverse arc-length matches s12/a × 180/π for equator 1° apart")
    func testGeneralInverseArcLength() {
        let p1 = (lat: 0.0, lon: 0.0)
        let p2 = (lat: 0.0, lon: 1.0)
        // first get the true distance s12
        let (s12, _, _) = Geodesic.inverse(between: p1, and: p2)
        // now get the ellipsoidal arc length
        let (a12, _, _, _, _, _, _, _) = Geodesic.generalInverse(between: p1, and: p2)
        // expected arc degrees on the ellipsoid:
        let expectedArc = s12 / GeodGeodesic.WGS84.semiMajorAxis * (180.0 / .pi)
        #expect(abs(a12 - expectedArc) <= 0.006)
    }
}

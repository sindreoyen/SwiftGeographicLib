//
//  GeneralDirectTests.swift
//  SwiftGeographicLib
//
//  Created by Sindre on 23/04/2025.
//

import Testing
@testable import SwiftGeographicLib
import CoreLocation

@Suite("General Direct Method Tests")
struct GeneralDirectTests {
    
    @Test("generalDirect matches direct for small distance north")
    func testGeneralDirectMatchesDirectNorth() {
        let start = (lat: 0.0, lon: 0.0)
        let s12 = 1000.0
        let azi1 = 0.0
        let (lat2, lon2, _, s12Out, _, _, _, _, _) =
        Geodesic.generalDirect(from: start, azimuth: azi1, s12_a12: s12)
        let directPoint = Geodesic.direct(from: start, distance: s12, azimuth: azi1)
        #expect(abs(lat2 - directPoint.latitude) <= 1e-9)
        #expect(abs(lon2 - directPoint.longitude) <= 1e-9)
        #expect(abs(s12Out - s12) <= 1e-9)
    }
    
    @Test("generalDirect arc mode returns correct a12 for known distance")
    func testGeneralDirectArcMode() {
        let start = (lat: 0.0, lon: 0.0)
        let s12 = 1000.0
        let azi1 = 90.0
        let flags: UInt32 = 1 << 0 // GEOD_ARCMODE
        // In arc-mode s12_a12 is degrees of arc
        let arcDegrees = s12 / 6378137.0 * (180.0 / .pi)
        let (_, _, _, _, _, _, _, _, a12) =
        Geodesic.generalDirect(from: start, azimuth: azi1, flags: flags, s12_a12: arcDegrees)
        #expect(abs(a12 - arcDegrees) <= 1e-12)
    }
}

//
//  GeodesicLineTests.swift
//  SwiftGeographicLib
//
//  Created by Sindre on 23/04/2025.
//

import Testing
@testable import SwiftGeographicLib
import CoreLocation

@Suite("GeodesicLine Tests")
struct GeodesicLineTests {
    
    @Test("directFrom init + position(distance:) matches Geodesic.direct()")
    func testDirectFromPosition() {
        let start = (lat: 30.0, lon: -40.0)
        let azi   =  60.0
        let s12   = 5000.0
        let line  = GeodesicLine(directFrom: start, azimuth: azi, distance: s12, caps: .none)
        let pos   = line.position(distance: s12)
        let direct = Geodesic.direct(from: start, distance: s12, azimuth: azi)
        #expect(abs(pos.latitude  - direct.latitude ) <= 1e-9)
        #expect(abs(pos.longitude - direct.longitude) <= 1e-9)
    }
    
    @Test("genPosition(flags:0) + setDistance(s12) matches direct()")
    func testGenPositionMatchesDirect() {
        let start = (lat: -10.0, lon: 20.0)
        let azi   = 120.0
        let s12   = 2500.0
        
        // include LONGITUDE in caps so genPosition actually writes lon2
        let caps: GeodesicMask = [.distanceIn, .longitude]
        let line = GeodesicLine(from: start, azimuth: azi, caps: caps)
        
        line.setDistance(s12)
        let (lat2, lon2, _, _, _, _, _, _, _) = line.genPosition(flags: .none, s12_a12: s12)
        let direct = Geodesic.direct(from: start, distance: s12, azimuth: azi)
        
        #expect(abs(lat2 - direct.latitude)  <= 1e-5)
        #expect(abs(lon2 - direct.longitude) <= 1e-5)
    }
    
    @Test("genSetDistance(flags:0) == setDistance for position()")
    func testGenSetDistance() {
        let start = (lat: 0.0, lon: 0.0)
        let azi   = 45.0
        let s13   = 1000.0
        
        let line1 = GeodesicLine(from: start, azimuth: azi, caps: .distanceIn)
        line1.setDistance(s13)
        let pos1 = line1.position(distance: s13)
        
        let line2 = GeodesicLine(from: start, azimuth: azi, caps: .distanceIn)
        line2.genSetDistance(flags: .none, s13_a13: s13)
        let pos2 = line2.position(distance: s13)
        
        #expect(abs(pos1.latitude  - pos2.latitude ) <= 1e-9)
        #expect(abs(pos1.longitude - pos2.longitude) <= 1e-9)
    }
}

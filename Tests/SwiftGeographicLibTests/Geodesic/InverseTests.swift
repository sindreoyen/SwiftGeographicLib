//
//  InverseTests.swift
//  SwiftGeographicLib
//
//  Created by Sindre on 23/04/2025.
//

import Testing
@testable import SwiftGeographicLib
import CoreLocation

@Suite("Inverse Method Tests")
struct InverseTests {
    
    @Test("Distance and azimuth between same point is zero")
    func testInverseZeroDistance() {
        let p = (lat: 10.0, lon: 20.0)
        let (s12, azi1, azi2) = Geodesic.inverse(between: p, and: p)
        
        // Distance must be zero
        #expect(s12 == 0)
        
        // Azimuths should be defined (finite) and equal
        #expect(azi1.isFinite)
        #expect(azi2.isFinite)
        #expect(abs(azi1 - azi2) <= 1e-9)
    }
    
    @Test("Distance from (0,0) to (0,1°E) on equator")
    func testInverseEquator1Degree() {
        let p1 = (lat: 0.0, lon: 0.0)
        let p2 = (lat: 0.0, lon: 1.0)
        let (s12, azi1, azi2) = Geodesic.inverse(between: p1, and: p2)
        
        // ~111319.49 m per degree at equator
        #expect(abs(s12 - 111_319.49) <= 1.0)
        
        // Forward azimuth from p1 to p2 should be due east
        #expect(abs(azi1 -  90.0) <= 1e-6)
        
        // Forward azimuth at p2 (continuing along the equator) is also east
        #expect(abs(azi2 -  90.0) <= 1e-6)
    }
}

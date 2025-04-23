//
//  GeodesicPolygonTests.swift
//  SwiftGeographicLib
//
//  Created by Sindre on 23/04/2025.
//

import Testing
@testable import SwiftGeographicLib
import CoreLocation

@Suite("GeodesicPolygon Tests")
struct GeodesicPolygonTests {
    
    @Test("Polyline compute length matches direct distance")
    func testPolylineCompute() {
        let p = GeodesicPolygon(polyline: true)
        let start = (lat: 0.0, lon: 0.0)
        p.addPoint(start)
        let next = Geodesic.direct(from: start, distance: 2000.0, azimuth: 90.0)
        p.addPoint((lat: next.latitude, lon: next.longitude))
        let (_, area, perimeter) = p.compute()
        #expect(area == 0.0)
        #expect(abs(perimeter - 2000.0) <= 1e-6)
    }
    
    @Test("Static area() matches incremental compute() for 1°×1° square at equator")
    func testStaticAreaMatchesInstance() {
        let coords = [
            (lat: 0.0, lon: 0.0),
            (lat: 0.0, lon: 1.0),
            (lat: 1.0, lon: 1.0),
            (lat: 1.0, lon: 0.0)
        ]
        let (areaStatic, periStatic) = GeodesicPolygon.area(of: coords)
        let p = GeodesicPolygon(polyline: false)
        coords.forEach { p.addPoint($0) }
        let (_, areaInst, periInst) = p.compute()
        #expect(abs(areaInst - areaStatic) / areaStatic <= 1e-6)
        #expect(abs(periInst - periStatic) / periStatic <= 1e-6)
    }
    
    @Test("testPoint does not alter polygon state")
    func testTestPointNoStateChange() {
        let p = GeodesicPolygon(polyline: true)
        p.addPoint((lat: 0.0, lon: 0.0))
        p.addEdge(azimuth: 0.0, distance: 1000.0)
        let (_, _, per1) = p.compute()
        
        // call testPoint – we don't care what per2 is, just that state isn't mutated
        _ = p.testPoint((lat: 1.0, lon: 0.0))
        let (_, _, per3) = p.compute()
        
        #expect(per3 == per1)
    }
    
    @Test("testEdge does not alter polygon state")
    func testTestEdgeNoStateChange() {
        let p = GeodesicPolygon(polyline: true)
        p.addPoint((lat: 0.0, lon: 0.0))
        p.addEdge(azimuth: 90.0, distance: 1000.0)
        let (_, _, per1) = p.compute()
        
        // call testEdge – we don't care what per2 is, just that state isn't mutated
        _ = p.testEdge(azimuth: 90.0, distance: 1000.0)
        let (_, _, per3) = p.compute()
        
        #expect(per3 == per1)
    }
}

//
//  CentralManagerTestCase.swift
//  BluesTests
//
//  Created by Michał Kałużny on 12/09/2017.
//  Copyright © 2017 NWTN Berlin. All rights reserved.
//

import XCTest
import CoreBluetooth

@testable import Blues

class CentralManagerTestCase: XCTestCase {
    
    func testCanStartScanning() {
        let mock = CBCentralManagerMock()
        let central = CentralManager(core: mock)
        
        central.startScanningForPeripherals()
        
        let expectation = XCTestExpectation()
        DispatchQueue.main.async {
            XCTAssertTrue(mock.isScanning)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1)
    }
    
    func testCanStopScanning() {
        let mock = CBCentralManagerMock()
        let central = CentralManager(core: mock)
        
        mock.isScanning = true
        central.stopScanningForPeripherals()
        
        let expectation = XCTestExpectation()
        DispatchQueue.main.async {
            XCTAssertFalse(mock.isScanning)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1)
    }
    
    func testCanStartScanningWithTimeout() {
        let mock = CBCentralManagerMock()
        let central = CentralManager(core: mock)
        
        central.startScanningForPeripherals(advertisingWithServices: nil, options: nil, timeout: 1)
        
        let turnOnExpectation = XCTestExpectation()
        DispatchQueue.main.async {
            XCTAssertTrue(mock.isScanning)
            turnOnExpectation.fulfill()
        }
        
        let turnOffExpectation = XCTestExpectation()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            XCTAssertFalse(mock.isScanning)
            turnOffExpectation.fulfill()
        }
        
        self.wait(for: [turnOnExpectation, turnOffExpectation], timeout: 2)
    }
}

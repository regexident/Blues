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
        
        onNextRunLoop {
            XCTAssertTrue(mock.isScanning)
        }
    }
    
    func testCanStopScanning() {
        let mock = CBCentralManagerMock()
        let central = CentralManager(core: mock)
        
        mock.isScanning = true
        central.stopScanningForPeripherals()
        
        onNextRunLoop {
            XCTAssertFalse(mock.isScanning)
        }
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
    
    func testRetrievePeripheralsByPeripheralUUIDs() {
        let mock = CBCentralManagerMock()
        let central = CentralManager(core: mock)
        let corePeripheral = CBPeripheralMock()
        let peripheral = Peripheral(core: corePeripheral, queue: central.queue)
        let retrievableIdentifier = Identifier(uuid: corePeripheral.identifier)

        mock.genericDelegate = central
        mock.discover(corePeripheral, advertisement: [:])
    
        onNextRunLoop {
            let retrived = central.retrievePeripherals(withIdentifiers: [retrievableIdentifier])
            XCTAssertTrue(retrived.contains(peripheral))
        }
    }
    
    func testRetrievePeripheralsByServiceUUIDs() {
        let mock = CBCentralManagerMock()
        let central = CentralManager(core: mock)
        let corePeripheral = CBPeripheralMock()
        
        let peripheral = Peripheral(core: corePeripheral, queue: central.queue)
        let service = CBServiceMock(peripheral: corePeripheral)
        let retrievableIdentifier = Identifier(uuid: service.uuid)
        corePeripheral.genericServices = [service]
        
        mock.genericDelegate = central
        mock.discover(corePeripheral, advertisement: [:])
        
        onNextRunLoop {
            let retrived = central.retrieveConnectedPeripherals(withServices: [retrievableIdentifier])
            XCTAssertTrue(retrived.contains(peripheral))
        }
    }
    
    func onNextRunLoop(_ block: @escaping () -> Void) {
        let expectation = XCTestExpectation()
        DispatchQueue.main.async {
            block()
            expectation.fulfill()
        }
        self.wait(for: [expectation], timeout: 5)
    }
}

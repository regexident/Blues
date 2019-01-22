// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import XCTest
import CoreBluetooth

@testable import Blues

class PeripheralStateDelegateCatcher: PeripheralStateDelegate {
    var readClosure: ((Result<Float, Error>) -> Void)? = nil
    var modifyClosure: (([Service]) -> Void)? = nil
    var updateClosure: ((String?) -> Void)? = nil

    func didModify(services: [Service], of peripheral: Peripheral) {
        modifyClosure?(services)
    }
    
    func didUpdate(name: String?, of peripheral: Peripheral) {
        updateClosure?(name)
    }
    
    func didRead(rssi: Result<Float, Error>, of peripheral: Peripheral) {
        readClosure?(rssi)
    }
}

class PeripheralTests: XCTestCase {
    func testPeripheralIdentifier() {
        let centralManagerMock = CBCentralManagerMock()
        let centralManager = DefaultCentralManager(core: centralManagerMock)
        
        let peripheralMock = CBPeripheralMock()
        peripheralMock.identifier = UUID()
        
        let peripheral = Peripheral(
            core: peripheralMock,
            centralManager: centralManager
        )
        
        XCTAssertEqual(peripheralMock.identifier.uuidString, peripheral.identifier.string)
    }
    
    func testPeripheralName() {
        let centralManagerMock = CBCentralManagerMock()
        let centralManager = DefaultCentralManager(core: centralManagerMock)
        
        let peripheralMock = CBPeripheralMock()
        peripheralMock.name = UUID().uuidString
        
        let peripheral = Peripheral(
            core: peripheralMock,
            centralManager: centralManager
        )
        
        XCTAssertEqual(peripheralMock.name, peripheral.name)
    }
    
    func testPeripheralState() {
        let centralManagerMock = CBCentralManagerMock()
        let centralManager = DefaultCentralManager(core: centralManagerMock)
        
        let peripheralMock = CBPeripheralMock()
        peripheralMock.state = .connected
        
        let peripheral = Peripheral(
            core: peripheralMock,
            centralManager: centralManager
        )
        
        XCTAssertEqual(peripheralMock.state, peripheral.state.inner)
    }
    
    func testIsValid() {
        let centralManagerMock = CBCentralManagerMock()
        let centralManager = DefaultCentralManager(core: centralManagerMock)
        
        let peripheralMock = CBPeripheralMock()
        
        peripheralMock.identifier = UUID()
        
        let peripheral = Peripheral(
            core: peripheralMock,
            centralManager: centralManager
        )
        
        XCTAssertTrue(peripheral.isValid(core: peripheralMock))
        
        let otherCore = CBPeripheralMock()
        otherCore.identifier = UUID()
        
        XCTAssertFalse(peripheral.isValid(core: otherCore))
    }
    
    func testServiceDisoveryAllServicesRequested() {
        let centralManagerMock = CBCentralManagerMock()
        let centralManager = DefaultCentralManager(core: centralManagerMock)
        
        let peripheralMock = CBPeripheralMock()
        
        peripheralMock.identifier = UUID()
        peripheralMock.state = .connected
        
        let peripheral = Peripheral(
            core: peripheralMock,
            centralManager: centralManager
        )
        
        peripheralMock.genericDelegate = peripheral
        
        let serviceUUIDs = [UUID()]
        let serviceIdentifiers = serviceUUIDs.map(Identifier.init)
        let servicesThatShouldBeDiscovered = serviceIdentifiers.map {
            return Service(identifier: $0, peripheral: peripheral)
        }
        
        peripheralMock.discoverableServices = serviceIdentifiers.map { $0.core }
        
        peripheral.discover(services: serviceIdentifiers)
        
        onNextRunLoop {
            XCTAssertEqual(peripheral.services ?? [], servicesThatShouldBeDiscovered)
        }
    }
    
    func testServiceDisoverySomeServicesRequested() {
        let centralManagerMock = CBCentralManagerMock()
        let centralManager = DefaultCentralManager(core: centralManagerMock)
        
        let peripheralMock = CBPeripheralMock()
        
        peripheralMock.identifier = UUID()
        peripheralMock.state = .connected
        
        let peripheral = Peripheral(
            core: peripheralMock,
            centralManager: centralManager
        )
        
        peripheralMock.genericDelegate = peripheral
        
        let availableServices = [UUID(), UUID()]
        let availableServicesIdentifiers = availableServices.map(Identifier.init)
        let requestedServiceIdentifiers = availableServicesIdentifiers.prefix(1)
        
        let servicesThatShouldBeDiscovered = requestedServiceIdentifiers.map {
            return Service(identifier: $0, peripheral: peripheral)
        }
        
        peripheralMock.discoverableServices = availableServicesIdentifiers.map { $0.core }
        
        peripheral.discover(services: Array(requestedServiceIdentifiers))
        
        onNextRunLoop {
            XCTAssertEqual(peripheral.services ?? [], servicesThatShouldBeDiscovered)
        }
    }
    
    func testServiceDisoveryNoServicesRequested() {
        let centralManagerMock = CBCentralManagerMock()
        let centralManager = DefaultCentralManager(core: centralManagerMock)
        
        let peripheralMock = CBPeripheralMock()
        
        peripheralMock.identifier = UUID()
        peripheralMock.state = .connected
        
        let peripheral = Peripheral(
            core: peripheralMock,
            centralManager: centralManager
        )
        
        peripheralMock.genericDelegate = peripheral
        
        let serviceUUIDs: [UUID] = []
        let serviceIdentifiers = serviceUUIDs.map(Identifier.init)
        
        peripheralMock.discoverableServices = serviceIdentifiers.map { $0.core }
        
        peripheral.discover(services: serviceIdentifiers)
        
        onNextRunLoop {
            XCTAssertFalse(peripheralMock.discoverServicesWasCalled)
        }
    }
    
    func testServiceDisoveryNilServicesRequested() {
        let centralManagerMock = CBCentralManagerMock()
        let centralManager = DefaultCentralManager(core: centralManagerMock)
        
        let peripheralMock = CBPeripheralMock()
        
        peripheralMock.identifier = UUID()
        peripheralMock.state = .connected
        
        let peripheral = Peripheral(
            core: peripheralMock,
            centralManager: centralManager
        )
        
        peripheralMock.genericDelegate = peripheral
        
        let serviceUUIDs = [UUID()]
        let serviceIdentifiers = serviceUUIDs.map(Identifier.init)
        let servicesThatShouldBeDiscovered = serviceIdentifiers.map {
            return Service(identifier: $0, peripheral: peripheral)
        }
        
        peripheralMock.discoverableServices = serviceIdentifiers.map { $0.core }
        
        peripheral.discover(services: nil)
        
        onNextRunLoop {
            XCTAssertEqual(peripheral.services ?? [], servicesThatShouldBeDiscovered)
        }
    }
    
    func testModifiedServices() {
        let centralManagerMock = CBCentralManagerMock()
        let centralManager = DefaultCentralManager(core: centralManagerMock)
        
        let peripheralMock = CBPeripheralMock()
        
        peripheralMock.identifier = UUID()
        peripheralMock.state = .connected
        
        let catcher = PeripheralStateDelegateCatcher()
        
        let peripheral = DefaultPeripheral(
            core: peripheralMock,
            centralManager: centralManager
        )
        
        peripheral.delegate = catcher
        peripheralMock.genericDelegate = peripheral
        
        let serviceUUID = CBUUID()
        peripheralMock.discoverableServices = [serviceUUID]
        
        peripheral.discover(services: nil)
        
        let expectation = XCTestExpectation()
        catcher.modifyClosure = { services in
            XCTAssertTrue(services.map {$0.identifier.core }.contains(serviceUUID))
            expectation.fulfill()
        }
        
        onNextRunLoop {
            peripheralMock.modify(service: serviceUUID)
        }
        
        wait(for: [expectation], timeout: 1)
    }
    
    func testValidRSSIReading() {
        let centralManagerMock = CBCentralManagerMock()
        let centralManager = DefaultCentralManager(core: centralManagerMock)
        
        let peripheralMock = CBPeripheralMock()
        
        peripheralMock.identifier = UUID()
        peripheralMock.state = .connected
        peripheralMock.rssi = 100
        
        let peripheral = DefaultPeripheral(
            core: peripheralMock,
            centralManager: centralManager
        )
        
        let catcher = PeripheralStateDelegateCatcher()
        
        peripheral.delegate = catcher
        peripheralMock.genericDelegate = peripheral

        let expectation = XCTestExpectation()
        catcher.readClosure = { result in
            XCTAssertEqual(result.expect("in tests"), 100)
            expectation.fulfill()
        }

        peripheral.readRSSI()
        
        wait(for: [expectation], timeout: 1)
    }
    
    func testInvalidRSSIReading() {
        let centralManagerMock = CBCentralManagerMock()
        let centralManager = DefaultCentralManager(core: centralManagerMock)
        
        let peripheralMock = CBPeripheralMock()
        
        peripheralMock.identifier = UUID()
        peripheralMock.state = .connected
        peripheralMock.rssi = nil
        
        let peripheral = DefaultPeripheral(
            core: peripheralMock,
            centralManager: centralManager
        )
        
        let catcher = PeripheralStateDelegateCatcher()
        
        peripheral.delegate = catcher
        peripheralMock.genericDelegate = peripheral
        peripheralMock.shouldFailReadingRSSI = true
        
        let expectation = XCTestExpectation()
        catcher.readClosure = { result in
            XCTAssertTrue(result.isErr)
            expectation.fulfill()
        }
        
        peripheral.readRSSI()
        
        wait(for: [expectation], timeout: 1)
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

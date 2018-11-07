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

class PeripheralTestCase: XCTestCase {
    func testPeripheralIdentifier() {
        let core = CBPeripheralMock()
        core.identifier = UUID()
        let peripheral = Peripheral(core: core, queue: .main)
        
        XCTAssertEqual(core.identifier.uuidString, peripheral.identifier.string)
    }
    
    func testPeripheralName() {
        let core = CBPeripheralMock()
        core.name = UUID().uuidString
        
        let peripheral = Peripheral(core: core, queue: .main)
        
        XCTAssertEqual(core.name, peripheral.name)
    }
    
    func testPeripheralState() {
        let core = CBPeripheralMock()
        core.state = .connected
        
        let peripheral = Peripheral(core: core, queue: .main)
        
        XCTAssertEqual(core.state, peripheral.state.inner)
    }
    
    func testIsValid() {
        let core = CBPeripheralMock()
        core.identifier = UUID()
        let peripheral = Peripheral(core: core, queue: .main)
        
        XCTAssertTrue(peripheral.isValid(core: core))
        
        let otherCore = CBPeripheralMock()
        otherCore.identifier = UUID()
        
        XCTAssertFalse(peripheral.isValid(core: otherCore))
    }
    
    func testServiceDisoveryAllServicesRequested() {
        let core = CBPeripheralMock()
        core.identifier = UUID()
        core.state = .connected
        
        let peripheral = Peripheral(core: core, queue: .main)
        core.genericDelegate = peripheral
        
        let serviceUUIDs = [UUID()]
        let serviceIdentifiers = serviceUUIDs.map(Identifier.init)
        let servicesThatShouldBeDiscovered = serviceIdentifiers.map {
            return Service(identifier: $0, peripheral: peripheral)
        }
        
        core.discoverableServices = serviceIdentifiers.map { $0.core }
        
        peripheral.discover(services: serviceIdentifiers)
        
        onNextRunLoop {
            XCTAssertEqual(peripheral.services ?? [], servicesThatShouldBeDiscovered)
        }
    }
    
    func testServiceDisoverySomeServicesRequested() {
        let core = CBPeripheralMock()
        core.identifier = UUID()
        core.state = .connected
        
        let peripheral = Peripheral(core: core, queue: .main)
        core.genericDelegate = peripheral
        
        let availableServices = [UUID(), UUID()]
        let availableServicesIdentifiers = availableServices.map(Identifier.init)
        let requestedServiceIdentifiers = availableServicesIdentifiers.prefix(1)
        
        let servicesThatShouldBeDiscovered = requestedServiceIdentifiers.map {
            return Service(identifier: $0, peripheral: peripheral)
        }
        
        core.discoverableServices = availableServicesIdentifiers.map { $0.core }
        
        peripheral.discover(services: Array(requestedServiceIdentifiers))
        
        onNextRunLoop {
            XCTAssertEqual(peripheral.services ?? [], servicesThatShouldBeDiscovered)
        }
    }
    
    func testServiceDisoveryNoServicesRequested() {
        let core = CBPeripheralMock()
        core.identifier = UUID()
        core.state = .connected
        
        let peripheral = Peripheral(core: core, queue: .main)
        core.genericDelegate = peripheral
        
        let serviceUUIDs: [UUID] = []
        let serviceIdentifiers = serviceUUIDs.map(Identifier.init)
        
        core.discoverableServices = serviceIdentifiers.map { $0.core }
        
        peripheral.discover(services: serviceIdentifiers)
        
        onNextRunLoop {
            XCTAssertFalse(core.discoverServicesWasCalled)
        }
    }
    
    func testServiceDisoveryNilServicesRequested() {
        let core = CBPeripheralMock()
        core.identifier = UUID()
        core.state = .connected
        
        let peripheral = Peripheral(core: core, queue: .main)
        core.genericDelegate = peripheral
        
        let serviceUUIDs = [UUID()]
        let serviceIdentifiers = serviceUUIDs.map(Identifier.init)
        let servicesThatShouldBeDiscovered = serviceIdentifiers.map {
            return Service(identifier: $0, peripheral: peripheral)
        }
        
        core.discoverableServices = serviceIdentifiers.map { $0.core }
        
        peripheral.discover(services: nil)
        
        onNextRunLoop {
            XCTAssertEqual(peripheral.services ?? [], servicesThatShouldBeDiscovered)
        }
    }
    
    func testModifiedServices() {
        let core = CBPeripheralMock()
        core.identifier = UUID()
        core.state = .connected
        
        let catcher = PeripheralStateDelegateCatcher()
        
        let peripheral = DefaultPeripheral(core: core, queue: .main)
        peripheral.delegate = catcher
        core.genericDelegate = peripheral
        
        let serviceUUID = CBUUID()
        core.discoverableServices = [serviceUUID]
        
        peripheral.discover(services: nil)
        
        let expectation = XCTestExpectation()
        catcher.modifyClosure = { services in
            XCTAssertTrue(services.map {$0.identifier.core }.contains(serviceUUID))
            expectation.fulfill()
        }
        
        onNextRunLoop {
            core.modify(service: serviceUUID)
        }
        
        wait(for: [expectation], timeout: 1)
    }
    
    func testValidRSSIReading() {
        let core = CBPeripheralMock()
        core.identifier = UUID()
        core.state = .connected
        core.rssi = 100
        
        let catcher = PeripheralStateDelegateCatcher()
        let peripheral = DefaultPeripheral(core: core, queue: .main)
        
        peripheral.delegate = catcher
        core.genericDelegate = peripheral

        let expectation = XCTestExpectation()
        catcher.readClosure = { result in
            XCTAssertEqual(result.expect("in tests"), 100)
            expectation.fulfill()
        }

        peripheral.readRSSI()
        
        wait(for: [expectation], timeout: 1)
    }
    
    func testInvalidRSSIReading() {
        let core = CBPeripheralMock()
        core.identifier = UUID()
        core.state = .connected
        core.rssi = nil
        
        let catcher = PeripheralStateDelegateCatcher()
        let peripheral = DefaultPeripheral(core: core, queue: .main)
        
        peripheral.delegate = catcher
        core.genericDelegate = peripheral
        core.shouldFailReadingRSSI = true
        
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

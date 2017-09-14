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

private class FooPeripheral: Peripheral {
    
}

private class CentralManagerStateDelegateCatcher: CentralManagerStateDelegate {
    var closure: (() -> Void)? = nil

    func didUpdateState(of manager: CentralManager) {
        closure?()
    }
}

private class CentralManagerRestorationDelegateCatcher: CentralManagerRestorationDelegate {
    var closure: (() -> Void)? = nil
    
    func willRestore(state: CentralManagerRestoreState, of manager: CentralManager) {
        closure?()
    }
}

private class SelfManagingCentralManager: CentralManager, CentralManagerStateDelegate, CentralManagerDataSource {
    var catcher = CentralManagerStateDelegateCatcher()
    var dataSource = FooPeripheralDataSource()
    
    func didUpdateState(of manager: CentralManager) {
        catcher.closure?()
    }
    
    convenience init(core: CoreCentralProtocol) {
        self.init(core: core)
    }
    
    required convenience init(options: CentralManagerOptions?, queue: DispatchQueue) {
        fatalError("init(options:queue:) has not been implemented")
    }
    
    func peripheral(with identifier: Identifier, advertisement: Advertisement?, for manager: CentralManager) -> Peripheral {
        return dataSource.peripheral(with: identifier, advertisement: advertisement, for: manager)
    }
}

private class FooPeripheralDataSource: CentralManagerDataSource {
    func peripheral(with identifier: Identifier, advertisement: Advertisement?, for manager: CentralManager) -> Peripheral {
        return FooPeripheral(identifier: identifier, centralManager: manager)
    }
}

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
    
    func testConnectingToPeripheral() {
        let mock = CBCentralManagerMock()
        let central = DefaultCentralManager(core: mock)
        let corePeripheral = CBPeripheralMock()
        let delegateCatcher = CentralManagerConnectionDelegateCatcher()
        let expectation = XCTestExpectation()
        let peripheral = Peripheral(core: corePeripheral, queue: central.queue)
        
        central.delegate = delegateCatcher
        mock.genericDelegate = central
        delegateCatcher.didConnectClosure = { peripheral, manager in
            expectation.fulfill()
        }
        
        mock.discover(corePeripheral, advertisement: [:])
        onNextRunLoop {
            central.connect(peripheral: peripheral)
        }
        
        wait(for: [expectation], timeout: 1)
    }
    
    func testConnectingToPeripheralShouldFail() {
        let mock = CBCentralManagerMock()
        let central = DefaultCentralManager(core: mock)
        let corePeripheral = CBPeripheralMock()
        let delegateCatcher = CentralManagerConnectionDelegateCatcher()
        let expectation = XCTestExpectation()
        let peripheral = Peripheral(core: corePeripheral, queue: central.queue)
        
        central.delegate = delegateCatcher
        mock.genericDelegate = central
        mock.shouldFailOnConnect = true
        
        delegateCatcher.didFailToConnectClosure = { peripheral, error, manager in
            expectation.fulfill()
        }
        
        mock.discover(corePeripheral, advertisement: [:])
        onNextRunLoop {
            central.connect(peripheral: peripheral)
        }
        
        wait(for: [expectation], timeout: 1)
    }
    
    func testDisconnectPeripheral() {
        let mock = CBCentralManagerMock()
        let central = DefaultCentralManager(core: mock)
        let corePeripheral = CBPeripheralMock()
        let delegateCatcher = CentralManagerConnectionDelegateCatcher()
        let expectation = XCTestExpectation()
        let peripheral = Peripheral(core: corePeripheral, queue: central.queue)
        
        central.delegate = delegateCatcher
        mock.genericDelegate = central
        mock.shouldFailOnConnect = true
        
        delegateCatcher.didDisconnectClosure = { _ in
            expectation.fulfill()
        }
        
        mock.discover(corePeripheral, advertisement: [:])
        onNextRunLoop {
            central.connect(peripheral: peripheral)
            corePeripheral.state = .connected
        }
        
        onNextRunLoop {
            central.disconnect(peripheral: peripheral)
        }
        
        onNextRunLoop {
            XCTAssertEqual(mock.peripherals.count, 0)
        }
        
        wait(for: [expectation], timeout: 1)
    }
    
    func testDisconnectAllPeripheral() {
        let mock = CBCentralManagerMock()
        let central = DefaultCentralManager(core: mock)
        let corePeripheral = CBPeripheralMock()
        let delegateCatcher = CentralManagerConnectionDelegateCatcher()
        let peripheral = Peripheral(core: corePeripheral, queue: central.queue)
        
        central.delegate = delegateCatcher
        mock.genericDelegate = central
        mock.shouldFailOnConnect = true
        
        let peripheralDisconnectedExpectation = XCTestExpectation()
        delegateCatcher.didDisconnectClosure = { _ in
            peripheralDisconnectedExpectation.fulfill()
        }
        
        mock.discover(corePeripheral, advertisement: [:])
        onNextRunLoop {
            central.connect(peripheral: peripheral)
            corePeripheral.state = .connected
        }
        
        let allPeripheralsDisconnectedExpectation = XCTestExpectation()
        onNextRunLoop {
            central.disconnectAll()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                XCTAssertEqual(mock.peripherals.count, 0)
                allPeripheralsDisconnectedExpectation.fulfill()
            }
        }
        
        wait(for: [allPeripheralsDisconnectedExpectation], timeout: 1)
    }
    
    func testCustomPeripheralWrapping() {
        let mock = CBCentralManagerMock()
        let central = DefaultCentralManager(core: mock)
        let corePeripheral = CBPeripheralMock()
        let dataSource = FooPeripheralDataSource()
        let service = CBServiceMock(peripheral: corePeripheral)
        let retrievableIdentifier = Identifier(uuid: service.uuid)
        corePeripheral.genericServices = [service]
        
        mock.genericDelegate = central
        central.dataSource = dataSource
        mock.discover(corePeripheral, advertisement: [:])
        
        onNextRunLoop {
            let retrived = central.retrieveConnectedPeripherals(withServices: [retrievableIdentifier])
            XCTAssert(retrived.first is FooPeripheral)
        }
    }
    
    func testSelfDelegatingManager() {
        let mock = CBCentralManagerMock()
        let central = SelfManagingCentralManager(core: mock)
        
        let expectation = XCTestExpectation()
        central.catcher.closure = {
            expectation.fulfill()
        }
        
        mock.genericDelegate = central
        mock.state = .unknown
        
        wait(for: [expectation], timeout: 1)
    }
    
    func testSelfDataSourcingManager() {
        let mock = CBCentralManagerMock()
        let central = DefaultCentralManager(core: mock)
        let corePeripheral = CBPeripheralMock()
        let service = CBServiceMock(peripheral: corePeripheral)
        let retrievableIdentifier = Identifier(uuid: service.uuid)
        corePeripheral.genericServices = [service]
        
        mock.genericDelegate = central
        mock.discover(corePeripheral, advertisement: [:])
        
        onNextRunLoop {
            let retrived = central.retrieveConnectedPeripherals(withServices: [retrievableIdentifier])
            XCTAssert(retrived.first is DefaultPeripheral)
        }
    }
    
    func testDelegatedMananger() {
        let mock = CBCentralManagerMock()
        let central = DefaultCentralManager(core: mock)
        let catcher = CentralManagerStateDelegateCatcher()
        
        central.delegate = catcher
        mock.genericDelegate = central
        
        let expectation = XCTestExpectation()
        catcher.closure = {
            expectation.fulfill()
        }
        
        mock.state = .unknown
        
        wait(for: [expectation], timeout: 1)
    }
    
    func testDataSourcedManager() {
        let mock = CBCentralManagerMock()
        let central = DefaultCentralManager(core: mock)
        let corePeripheral = CBPeripheralMock()
        let service = CBServiceMock(peripheral: corePeripheral)
        let retrievableIdentifier = Identifier(uuid: service.uuid)
        corePeripheral.genericServices = [service]
        
        mock.genericDelegate = central
        mock.discover(corePeripheral, advertisement: [:])
        
        onNextRunLoop {
            let retrived = central.retrieveConnectedPeripherals(withServices: [retrievableIdentifier])
            XCTAssert(retrived.first is DefaultPeripheral)
        }
    }
    
    func testStateRestoration() {
        let serviceIdentifiers = [UUID()]
        let peripheralIdentifiers = [UUID()]
        let dictionary = CentralManagerRestoreStateTestCase.validInputDictionary(services: serviceIdentifiers, peripherals: peripheralIdentifiers)
        
        let services = serviceIdentifiers.map(Identifier.init)
        let peripherals = peripheralIdentifiers.map { (uuid) -> Peripheral in
            let core = CBPeripheralMock()
            core.identifier = uuid
            return Peripheral(core: core, queue: .main)
        }
        
        let restorationState = CentralManagerRestoreState(dictionary: dictionary) { core in
            return Peripheral(core: core, queue: .main)
        }
        
        let mock = CBCentralManagerMock()
        let central = DefaultCentralManager(core: mock)
        mock.genericDelegate = central
        let catcher = CentralManagerRestorationDelegateCatcher()
        central.delegate = catcher
        
        let expectation = XCTestExpectation()
        catcher.closure = {
            expectation.fulfill()
        }
        
        peripherals.forEach { central.connect(peripheral: $0) }
        
        onNextRunLoop {
            mock.restore(state: dictionary)
        }
        
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

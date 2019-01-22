// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import XCTest
import CoreBluetooth

@testable import Blues

private class FooPeripheral: Peripheral {
    
}

private class CentralManagerStateDelegateCatcher: CentralManagerStateDelegate {
    var closure: (() -> Void)? = nil

    func didUpdateState(of manager: CentralManager) {
        self.closure?()
    }
}

private class CentralManagerRestorationDelegateCatcher: CentralManagerRestorationDelegate {
    var closure: (() -> Void)? = nil
    
    func willRestore(state: CentralManagerRestoreState, of manager: CentralManager) {
        self.closure?()
    }
}

private class SelfManagingCentralManager: CentralManager, CentralManagerStateDelegate, CentralManagerDataSource {
    var catcher = CentralManagerStateDelegateCatcher()
    var dataSource = FooPeripheralDataSource()
    
    func didUpdateState(of manager: CentralManager) {
        self.catcher.closure?()
    }
        
    required convenience init(options: CentralManagerOptions?, queue: DispatchQueue) {
        fatalError("init(options:queue:) has not been implemented")
    }
    
    func peripheral(with identifier: Identifier, advertisement: Advertisement?, for manager: CentralManager) -> Peripheral {
        return self.dataSource.peripheral(with: identifier, advertisement: advertisement, for: manager)
    }
}

private class FooPeripheralDataSource: CentralManagerDataSource {
    func peripheral(with identifier: Identifier, advertisement: Advertisement?, for manager: CentralManager) -> Peripheral {
        return FooPeripheral(identifier: identifier, centralManager: manager)
    }
}

class CentralManagerTests: XCTestCase {
    private enum Key {
        static let allowDuplicatesKey: String = CBCentralManagerScanOptionAllowDuplicatesKey
        static let solicitedServiceUUIDsKey: String = CBCentralManagerScanOptionSolicitedServiceUUIDsKey
        
        static let restoredStateScanOptionsKey: String = CBCentralManagerRestoredStateScanOptionsKey
        static let restoredStatePeripheralsKey: String = CBCentralManagerRestoredStatePeripheralsKey
        static let restoredStateScanServicesKey: String = CBCentralManagerRestoredStateScanServicesKey
    }
    
    private enum Stub {
        static let solicitedServiceIdentifiers = [CBUUID(), CBUUID()]
        static let allowDuplicates = true
        
        static let scanDictionary: [String: Any] = [
            Key.allowDuplicatesKey: Stub.allowDuplicates,
            Key.solicitedServiceUUIDsKey: Stub.solicitedServiceIdentifiers
        ]
        
        static let restoreDictionary: [String: Any] = [
            Key.restoredStateScanOptionsKey: false,
            Key.restoredStatePeripheralsKey: false,
            Key.restoredStateScanServicesKey: false
        ]
    }
        
    func testCanStartScanning() {
        let centralManagerMock = CBCentralManagerMock()
        let centralManager = CentralManager(core: centralManagerMock)
        
        centralManager.startScanningForPeripherals()
        
        onNextRunLoop {
            XCTAssertTrue(centralManagerMock.isScanning)
        }
    }
    
    func testCanStopScanning() {
        let centralManagerMock = CBCentralManagerMock()
        let centralManager = CentralManager(core: centralManagerMock)
        
        centralManagerMock.isScanning = true
        
        centralManager.stopScanningForPeripherals()
        
        onNextRunLoop {
            XCTAssertFalse(centralManagerMock.isScanning)
        }
    }
    
    func testCanStartScanningWithTimeout() {
        let centralManagerMock = CBCentralManagerMock()
        let centralManager = CentralManager(core: centralManagerMock)
        
        centralManager.startScanningForPeripherals(
            advertisingWithServices: nil,
            options: nil,
            timeout: 1
        )
        
        let turnOnExpectation = XCTestExpectation()
        DispatchQueue.main.async {
            XCTAssertTrue(centralManagerMock.isScanning)
            turnOnExpectation.fulfill()
        }
    
        let turnOffExpectation = XCTestExpectation()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            XCTAssertFalse(centralManagerMock.isScanning)
            turnOffExpectation.fulfill()
        }
        
        self.wait(for: [turnOnExpectation, turnOffExpectation], timeout: 2)
    }
    
    func testRetrievePeripheralsByPeripheralUUIDs() {
        let centralManagerMock = CBCentralManagerMock()
        let centralManager = CentralManager(core: centralManagerMock)
        
        let peripheralMock = CBPeripheralMock()
        let peripheral = Peripheral(
            core: peripheralMock,
            centralManager: centralManager
        )
        
        let retrievableIdentifier = Identifier(uuid: peripheral.core.identifier)

        centralManagerMock.genericDelegate = centralManager
        centralManagerMock.discover(peripheralMock, advertisement: [:])
    
        onNextRunLoop {
            let retrived = centralManager.retrievePeripherals(
                withIdentifiers: [retrievableIdentifier]
            )
            XCTAssertTrue(retrived.contains(peripheral))
        }
    }
    
    func testRetrievePeripheralsByServiceUUIDs() {
        let centralManagerMock = CBCentralManagerMock()
        let centralManager = CentralManager(core: centralManagerMock)
        
        let peripheralMock = CBPeripheralMock()
        let peripheral = Peripheral(
            core: peripheralMock,
            centralManager: centralManager
        )
        
        let service = CBServiceMock(peripheral: peripheralMock)
        let retrievableIdentifier = Identifier(uuid: service.uuid)
        peripheralMock.genericServices = [service]
        
        centralManagerMock.genericDelegate = centralManager
        centralManagerMock.discover(peripheralMock, advertisement: [:])
        
        onNextRunLoop {
            let retrived = centralManager.retrieveConnectedPeripherals(
                withServices: [retrievableIdentifier]
            )
            XCTAssertTrue(retrived.contains(peripheral))
        }
    }
    
    func testConnectingToPeripheral() {
        let centralManagerMock = CBCentralManagerMock()
        let centralManager = DefaultCentralManager(core: centralManagerMock)
        
        let peripheralMock = CBPeripheralMock()
        let peripheral = Peripheral(
            core: peripheralMock,
            centralManager: centralManager
        )
        
        let delegateCatcher = CentralManagerConnectionDelegateCatcher()
        let expectation = XCTestExpectation()
        
        centralManager.delegate = delegateCatcher
        centralManagerMock.genericDelegate = centralManager
        delegateCatcher.didConnectClosure = { peripheral, manager in
            expectation.fulfill()
        }
        
        centralManagerMock.discover(peripheralMock, advertisement: [:])
        onNextRunLoop {
            centralManager.connect(peripheral: peripheral)
        }
        
        wait(for: [expectation], timeout: 1)
    }
    
    func testConnectingToPeripheralShouldFail() {
        let centralManagerMock = CBCentralManagerMock()
        let centralManager = DefaultCentralManager(core: centralManagerMock)
        
        let peripheralMock = CBPeripheralMock()
        let peripheral = Peripheral(
            core: peripheralMock,
            centralManager: centralManager
        )
        
        let delegateCatcher = CentralManagerConnectionDelegateCatcher()
        let expectation = XCTestExpectation()
        
        centralManager.delegate = delegateCatcher
        centralManagerMock.genericDelegate = centralManager
        centralManagerMock.shouldFailOnConnect = true
        
        delegateCatcher.didFailToConnectClosure = { peripheral, error, manager in
            expectation.fulfill()
        }
        
        centralManagerMock.discover(peripheralMock, advertisement: [:])
        onNextRunLoop {
            centralManager.connect(peripheral: peripheral)
        }
        
        wait(for: [expectation], timeout: 1)
    }
    
    func testDisconnectPeripheral() {
        let centralManagerMock = CBCentralManagerMock()
        let centralManager = DefaultCentralManager(core: centralManagerMock)
        
        let peripheralMock = CBPeripheralMock()
        let peripheral = Peripheral(
            core: peripheralMock,
            centralManager: centralManager
        )
        
        let delegateCatcher = CentralManagerConnectionDelegateCatcher()
        let expectation = XCTestExpectation()
        
        centralManager.delegate = delegateCatcher
        centralManagerMock.genericDelegate = centralManager
        centralManagerMock.shouldFailOnConnect = true
        
        delegateCatcher.didDisconnectClosure = { _, _, _ in
            expectation.fulfill()
        }
        
        centralManagerMock.discover(peripheralMock, advertisement: [:])
        onNextRunLoop {
            centralManager.connect(peripheral: peripheral)
            peripheralMock.state = .connected
        }
        
        onNextRunLoop {
            centralManager.disconnect(peripheral: peripheral)
        }
        
        onNextRunLoop {
            XCTAssertEqual(centralManagerMock.peripherals.count, 0)
        }
        
        wait(for: [expectation], timeout: 1)
    }
    
    func testDisconnectAllPeripheral() {
        let centralManagerMock = CBCentralManagerMock()
        let centralManager = DefaultCentralManager(core: centralManagerMock)
        
        let peripheralMock = CBPeripheralMock()
        let peripheral = Peripheral(
            core: peripheralMock,
            centralManager: centralManager
        )
        
        let delegateCatcher = CentralManagerConnectionDelegateCatcher()
        
        centralManager.delegate = delegateCatcher
        centralManagerMock.genericDelegate = centralManager
        centralManagerMock.shouldFailOnConnect = true
        
        let peripheralDisconnectedExpectation = XCTestExpectation()
        delegateCatcher.didDisconnectClosure = { _, _, _ in
            peripheralDisconnectedExpectation.fulfill()
        }
        
        centralManagerMock.discover(peripheralMock, advertisement: [:])
        onNextRunLoop {
            centralManager.connect(peripheral: peripheral)
            peripheralMock.state = .connected
        }
        
        let allPeripheralsDisconnectedExpectation = XCTestExpectation()
        onNextRunLoop {
            centralManager.disconnectAll()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                XCTAssertEqual(centralManagerMock.peripherals.count, 0)
                allPeripheralsDisconnectedExpectation.fulfill()
            }
        }
        
        wait(for: [allPeripheralsDisconnectedExpectation], timeout: 1)
    }
    
    func testCustomPeripheralWrapping() {
        let centralManagerMock = CBCentralManagerMock()
        let centralManager = DefaultCentralManager(core: centralManagerMock)
        
        let peripheralMock = CBPeripheralMock()
        
        let dataSource = FooPeripheralDataSource()
        let service = CBServiceMock(peripheral: peripheralMock)
        let retrievableIdentifier = Identifier(uuid: service.uuid)
        peripheralMock.genericServices = [service]
        
        centralManagerMock.genericDelegate = centralManager
        centralManager.dataSource = dataSource
        centralManagerMock.discover(peripheralMock, advertisement: [:])
        
        onNextRunLoop {
            let retrived = centralManager.retrieveConnectedPeripherals(
                withServices: [retrievableIdentifier]
            )
            XCTAssert(retrived.first is FooPeripheral)
        }
    }
    
    func testSelfDelegatingManager() {
        let centralManagerMock = CBCentralManagerMock()
        let centralManager = SelfManagingCentralManager(core: centralManagerMock)
        
        let expectation = XCTestExpectation()
        centralManager.catcher.closure = {
            expectation.fulfill()
        }
        
        centralManagerMock.genericDelegate = centralManager
        centralManagerMock.state = .unknown
        
        wait(for: [expectation], timeout: 1)
    }
    
    func testSelfDataSourcingManager() {
        let centralManagerMock = CBCentralManagerMock()
        let centralManager = DefaultCentralManager(core: centralManagerMock)
        
        let peripheralMock = CBPeripheralMock()
        
        let service = CBServiceMock(peripheral: peripheralMock)
        let retrievableIdentifier = Identifier(uuid: service.uuid)
        peripheralMock.genericServices = [service]
        
        centralManagerMock.genericDelegate = centralManager
        centralManagerMock.discover(peripheralMock, advertisement: [:])
        
        onNextRunLoop {
            let retrived = centralManager.retrieveConnectedPeripherals(
                withServices: [retrievableIdentifier]
            )
            XCTAssert(retrived.first is DefaultPeripheral)
        }
    }
    
    func testDelegatedMananger() {
        let centralManagerMock = CBCentralManagerMock()
        let centralManager = DefaultCentralManager(core: centralManagerMock)
        
        let catcher = CentralManagerStateDelegateCatcher()
        
        centralManager.delegate = catcher
        centralManagerMock.genericDelegate = centralManager
        
        let expectation = XCTestExpectation()
        catcher.closure = {
            expectation.fulfill()
        }
        
        centralManagerMock.state = .unknown
        
        wait(for: [expectation], timeout: 1)
    }
    
    func testDataSourcedManager() {
        let centralManagerMock = CBCentralManagerMock()
        let centralManager = DefaultCentralManager(core: centralManagerMock)
        
        let peripheralMock = CBPeripheralMock()

        let service = CBServiceMock(peripheral: peripheralMock)
        let retrievableIdentifier = Identifier(uuid: service.uuid)
        peripheralMock.genericServices = [service]
        
        centralManagerMock.genericDelegate = centralManager
        centralManagerMock.discover(peripheralMock, advertisement: [:])
        
        onNextRunLoop {
            let retrived = centralManager.retrieveConnectedPeripherals(
                withServices: [retrievableIdentifier]
            )
            XCTAssert(retrived.first is DefaultPeripheral)
        }
    }
    
    func testStateRestoration() {
        let centralManagerMock = CBCentralManagerMock()
        let centralManager = DefaultCentralManager(core: centralManagerMock)
        
        let serviceIdentifiers = [UUID()]
        let peripheralIdentifiers = [UUID()]
        let dictionary = type(of: self).validInputDictionary(
            services: serviceIdentifiers,
            peripherals: peripheralIdentifiers
        )
        
        let peripherals = peripheralIdentifiers.map { (uuid) -> Peripheral in
            let peripheralMock = CBPeripheralMock()
            peripheralMock.identifier = uuid
            return Peripheral(core: peripheralMock, centralManager: centralManager)
        }
        
        centralManagerMock.genericDelegate = centralManager
        let catcher = CentralManagerRestorationDelegateCatcher()
        centralManager.delegate = catcher
        
        let expectation = XCTestExpectation()
        catcher.closure = {
            expectation.fulfill()
        }
        
        peripherals.forEach { centralManager.connect(peripheral: $0) }
        
        onNextRunLoop {
            centralManagerMock.restore(state: dictionary)
        }
        
        wait(for: [expectation], timeout: 1)
    }
    
    static func validInputDictionary(services: [UUID] = [], peripherals: [UUID] = []) -> [String: Any] {
        var dictionary = Stub.restoreDictionary
        let serviceIdentifiers = services.map(CBUUID.init)
        let corePeripherals = peripherals.map { uuid -> CBPeripheralProtocol in
            let mock = CBPeripheralMock()
            mock.identifier = uuid
            return mock
        }
        
        dictionary[Key.restoredStateScanOptionsKey] = Stub.scanDictionary
        dictionary[Key.restoredStatePeripheralsKey] = corePeripherals
        dictionary[Key.restoredStateScanServicesKey] = serviceIdentifiers
        
        return dictionary
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

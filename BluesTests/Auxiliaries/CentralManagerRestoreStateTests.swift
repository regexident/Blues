// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import XCTest
import CoreBluetooth

@testable import Blues

class CentralManagerRestoreStateTests: XCTestCase {
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
    
    func testRestoreationWithDictionary() {
        let serviceIdentifiers = [UUID()]
        let peripheralIdentifiers = [UUID()]
        let dictionary = CentralManagerRestoreStateTests.validInputDictionary(services: serviceIdentifiers, peripherals: peripheralIdentifiers)
        
        let services = serviceIdentifiers.map(Identifier.init)
        let peripherals = peripheralIdentifiers.map { (uuid) -> Peripheral in
            let centralManager = CentralManager()
            let peripheralMock = CBPeripheralMock()
            
            peripheralMock.identifier = uuid
            
            return Peripheral(
                core: peripheralMock,
                centralManager: centralManager
            )
        }
        
        let restorationState = CentralManagerRestoreState(dictionary: dictionary) { core in
            let centralManager = CentralManager()
            
            return Peripheral(
                core: core,
                centralManager: centralManager
            )
        }
        
        guard let restoredServices = restorationState?.scanServices else {
            return XCTFail()
        }
        
        guard let restoredPeripherals = restorationState?.peripherals else {
            return XCTFail()
        }
        
        guard let restoredScanOptions = restorationState?.scanOptions else {
            return XCTFail()
        }
        
        guard let scanOptions = CentralManagerScanningOptions(
            dictionary: Stub.scanDictionary
        ) else {
            return XCTFail()
        }
        
        XCTAssertEqual(restoredScanOptions, scanOptions)
        XCTAssertEqual(restoredServices, services)
        XCTAssertEqual(restoredPeripherals, peripherals)
    }
    
    func testRestoreationWithInvalidDictionary() {
        var dictionary = type(of: self).validInputDictionary()
        
        dictionary[Key.restoredStateScanOptionsKey] = nil
        
        let restorationState = CentralManagerRestoreState(dictionary: dictionary) { core in
            let centralManager = CentralManager()
            
            return Peripheral(
                core: core,
                centralManager: centralManager
            )
        }

        XCTAssertNil(restorationState)
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
}

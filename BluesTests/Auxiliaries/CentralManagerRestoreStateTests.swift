// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import XCTest
import CoreBluetooth

@testable import Blues

class CentralManagerRestoreStateTests: XCTestCase {
    static let baseDictionary: [String: Any] = [
        CBCentralManagerRestoredStateScanOptionsKey: false,
        CBCentralManagerRestoredStatePeripheralsKey: false,
        CBCentralManagerRestoredStateScanServicesKey: false
    ]
    
    func testRestoreationWithDictionary() {
        let serviceIdentifiers = [UUID()]
        let peripheralIdentifiers = [UUID()]
        let dictionary = CentralManagerRestoreStateTests.validInputDictionary(services: serviceIdentifiers, peripherals: peripheralIdentifiers)
        
        let services = serviceIdentifiers.map(Identifier.init)
        let peripherals = peripheralIdentifiers.map { (uuid) -> Peripheral in
            let core = CBPeripheralMock()
            core.identifier = uuid
            return Peripheral(core: core, queue: .main)
        }
        
        let restorationState = CentralManagerRestoreState(dictionary: dictionary) { core in
            return Peripheral(core: core, queue: .main)
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
        
        guard let scanOptions = CentralManagerScanningOptions(dictionary: CentralManagerScanningOptionsTests.dictionary) else {
            return XCTFail()
        }
        
        XCTAssertEqual(restoredScanOptions, scanOptions)
        XCTAssertEqual(restoredServices, services)
        XCTAssertEqual(restoredPeripherals, peripherals)
    }
    
    func testRestoreationWithInvalidDictionary() {
        var dictionary = CentralManagerRestoreStateTests.validInputDictionary()
        
        dictionary[CBCentralManagerRestoredStateScanOptionsKey] = nil
        
        let restorationState = CentralManagerRestoreState(dictionary: dictionary) { core in
            return Peripheral(core: core, queue: .main)
        }

        XCTAssertNil(restorationState)
    }
    
    static func validInputDictionary(services: [UUID] = [], peripherals: [UUID] = []) -> [String: Any] {
        var dictionary = baseDictionary
        let serviceIdentifiers = services.map(CBUUID.init)
        let corePeripherals = peripherals.map { uuid -> CBPeripheralProtocol in
            let mock = CBPeripheralMock()
            mock.identifier = uuid
            return mock
        }
        
        dictionary[CBCentralManagerRestoredStateScanOptionsKey] = CentralManagerScanningOptionsTests.dictionary
        dictionary[CBCentralManagerRestoredStatePeripheralsKey] = corePeripherals
        dictionary[CBCentralManagerRestoredStateScanServicesKey] = serviceIdentifiers
        
        return dictionary
    }
}

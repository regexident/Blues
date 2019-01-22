// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import XCTest
import CoreBluetooth

@testable import Blues

private class MutableServiceMock: MutableService {
    init() {
        let randomIdentifier = Identifier(uuid: UUID())
        let core = CBMutableService(type: randomIdentifier.core, primary: true)
        super.init(core: core)
    }
}

class PeripheralManagerTests: XCTestCase {
    func testIsAdvertisingProperty() {
        let core = CBPeripheralManagerMock.default
        let peripheralManager = PeripheralManager(core: core)
        
        peripheralManager.startAdvertising(nil)
        
        XCTAssertEqual(core.isAdvertising, true)
        XCTAssertEqual(peripheralManager.isAdvertising, true)
        
        peripheralManager.stopAdvertising()
        XCTAssertEqual(core.isAdvertising, false)
        XCTAssertEqual(peripheralManager.isAdvertising, false)
    }
    
    func testDesiredConnectionLatency() {
        let core = CBPeripheralManagerMock.default
        let peripheralManager = PeripheralManager(core: core)
        
        let central: Central = {
            let core = CBCentralMock(identifier: UUID(), maximumUpdateValueLength: 0)
            
            return Central(
                core: core,
                peripheralManager: peripheralManager
            )
        }()
        
        let desiredLatency = PeripheralManagerConnectionLatency.high
        peripheralManager.setDesiredConnectionLatency(desiredLatency, for: central)
        
        XCTAssertEqual(core.desiredConnectionLatencyStore, desiredLatency.core)
    }
    
    func testServiceAdding() {
        let core = CBPeripheralManagerMock.default
        let manager = PeripheralManager(core: core)
        let service = MutableServiceMock()
        
        manager.add(service)
        XCTAssertTrue(core.serviceStore.contains(where: { (knownService) -> Bool in
            return service.core.uuid == knownService.uuid
        }))
    }
    
    func testServiceRemoving() {
        let core = CBPeripheralManagerMock.default
        let manager = PeripheralManager(core: core)
        let service = MutableServiceMock()
        
        manager.add(service)
        manager.remove(service)
        
        XCTAssertFalse(core.serviceStore.contains(where: { (knownService) -> Bool in
            return service.core.uuid == knownService.uuid
        }))
        XCTAssertEqual(core.serviceStore.count, 0)
    }
}

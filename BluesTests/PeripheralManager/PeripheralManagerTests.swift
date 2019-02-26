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
        let manager = PeripheralManager(core: core)
        
        manager.startAdvertising(nil)
        
        XCTAssertEqual(core.isAdvertising, true)
        XCTAssertEqual(manager.isAdvertising, true)
        
        manager.stopAdvertising()
        XCTAssertEqual(core.isAdvertising, false)
        XCTAssertEqual(manager.isAdvertising, false)
    }
    
    func testDesiredConnectionLatency() {
        let core = CBPeripheralManagerMock.default
        let manager = PeripheralManager(core: core)
        let central = Central(core: CBCentralMock(identifier: UUID(), maximumUpdateValueLength: 0))
        let desiredLatency = PeripheralManagerConnectionLatency.high
        manager.setDesiredConnectionLatency(desiredLatency, for: central)
        
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

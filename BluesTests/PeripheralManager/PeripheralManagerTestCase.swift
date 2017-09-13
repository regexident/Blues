//
//  PeripheralManagerTestCase.swift
//  BluesTests
//
//  Created by Michał Kałużny on 12/09/2017.
//  Copyright © 2017 NWTN Berlin. All rights reserved.
//

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

class PeripheralManagerTestCase: XCTestCase {
    func testIsAdvertisingProperty() {
        let core = CorePeripheralManagerMock.default
        let manager = PeripheralManager(core: core)
        
        manager.startAdvertising(nil)
        
        XCTAssertEqual(core.isAdvertising, true)
        XCTAssertEqual(manager.isAdvertising, true)
        
        manager.stopAdvertising()
        XCTAssertEqual(core.isAdvertising, false)
        XCTAssertEqual(manager.isAdvertising, false)
    }
    
    func testDesiredConnectionLatency() {
        let core = CorePeripheralManagerMock.default
        let manager = PeripheralManager(core: core)
        let central = Central(core: CoreCentralMock(identifier: UUID(), maximumUpdateValueLength: 0))
        let desiredLatency = PeripheralManagerConnectionLatency.high
        manager.setDesiredConnectionLatency(desiredLatency, for: central)
        
        XCTAssertEqual(core.desiredConnectionLatencyStore, desiredLatency.core)
    }
    
    func testServiceAdding() {
        let core = CorePeripheralManagerMock.default
        let manager = PeripheralManager(core: core)
        let service = MutableServiceMock()
        
        manager.add(service)
        XCTAssertTrue(core.serviceStore.contains(service.core))
    }
    
    func testServiceRemoving() {
        let core = CorePeripheralManagerMock.default
        let manager = PeripheralManager(core: core)
        let service = MutableServiceMock()
        
        manager.add(service)
        manager.remove(service)
        
        XCTAssertFalse(core.serviceStore.contains(service.core))
        XCTAssertEqual(core.serviceStore.count, 0)
    }
}

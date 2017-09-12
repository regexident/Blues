//
//  CentralTestCase.swift
//  BluesTests
//
//  Created by Michał Kałużny on 12/09/2017.
//  Copyright © 2017 NWTN Berlin. All rights reserved.
//

import XCTest
import CoreBluetooth

@testable import Blues

struct CoreCentralMock: CoreCentralProtocol {
    var identifier: UUID
    var maximumUpdateValueLength: Int
}

class CentralTestCase: XCTestCase {
    
    func testCentralMaximumUpdateValueLength() {
        let maxminumUpdateValueLength = 20
        let coreCentral = CoreCentralMock(identifier: UUID(), maximumUpdateValueLength: maxminumUpdateValueLength)
        let central = Central(core: coreCentral)
        
        XCTAssertEqual(maxminumUpdateValueLength, central.maximumUpdateValueLength)
    }
}

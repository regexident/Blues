// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import XCTest
import CoreBluetooth

@testable import Blues

class CBCentralMock: CBCentralProtocol {
    var identifier: UUID
    var maximumUpdateValueLength: Int
    
    init(identifier: UUID, maximumUpdateValueLength: Int) {
        self.identifier = identifier
        self.maximumUpdateValueLength = maximumUpdateValueLength
    }
}

class CentralTests: XCTestCase {
    
    func testCentralMaximumUpdateValueLength() {
        let maxminumUpdateValueLength = 20
        let coreCentral = CBCentralMock(identifier: UUID(), maximumUpdateValueLength: maxminumUpdateValueLength)
        let central = Central(core: coreCentral)
        
        XCTAssertEqual(maxminumUpdateValueLength, central.maximumUpdateValueLength)
    }
}

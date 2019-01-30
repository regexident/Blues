// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import XCTest
import CoreBluetooth

@testable import Blues

private struct CBCentralMock: CBCentralProtocol {
    var identifier: UUID
    var maximumUpdateValueLength: Int
}

class CentralTests: XCTestCase {
    func test_centralMaximumUpdateValueLength() {
        let maximumUpdateValueLength = 20
        
        let centralMock = CBCentralMock(
            identifier: UUID(),
            maximumUpdateValueLength: maximumUpdateValueLength
        )
        
        let peripheralManager = PeripheralManager()
        
        let central = Central(
            core: centralMock,
            peripheralManager: peripheralManager
        )
        
        XCTAssertEqual(central.maximumUpdateValueLength, maximumUpdateValueLength)
    }
}

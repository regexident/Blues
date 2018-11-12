// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import CoreBluetooth

@testable import Blues

class CBServiceMock: CBServiceProtocol {
    unowned(unsafe) var genericPeripheral: CBPeripheralProtocol
    
    var isPrimary: Bool = true
    var includedServices: [CBService]? = nil
    var characteristics: [CBCharacteristic]? = nil
    var uuid: CBUUID
    
    init(peripheral: CBPeripheralProtocol, uuid: CBUUID = CBUUID()) {
        self.genericPeripheral = peripheral
        self.uuid = uuid
    }
}

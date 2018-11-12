// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import CoreBluetooth

internal protocol CBServiceProtocol: CBAttributeProtocol {
    var genericPeripheral: CBPeripheralProtocol { get }
    var isPrimary: Bool { get }
    var includedServices: [CBService]? { get }
    var characteristics: [CBCharacteristic]? { get }
}

extension CBService: CBServiceProtocol {
    var genericPeripheral: CBPeripheralProtocol {
        return self.peripheral
    }
}

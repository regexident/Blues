// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import CoreBluetooth

internal protocol CBMutableServiceProtocol: CBServiceProtocol {
    var genericIncludedServices: [CBServiceProtocol]? { get set }
    var genericCharacteristics: [CBCharacteristicsProtocol]? { get set }
}

extension CBMutableService: CBMutableServiceProtocol {
    var genericIncludedServices: [CBServiceProtocol]? {
        get {
            return self.includedServices
        }
        set {
            self.includedServices = newValue as? [CBService]
        }
    }
    
    var genericCharacteristics: [CBCharacteristicsProtocol]? {
        get {
            return self.characteristics
        }
        set {
            self.characteristics = newValue as? [CBCharacteristic]
        }
    }
}

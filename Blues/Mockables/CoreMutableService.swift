// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import CoreBluetooth

internal protocol CoreMutableServiceProtocol: CoreServiceProtocol {
    var genericIncludedServices: [CoreServiceProtocol]? { get set }
    var genericCharacteristics: [CoreCharacteristicsProtocol]? { get set }
}

extension CBMutableService: CoreMutableServiceProtocol {
    var genericIncludedServices: [CoreServiceProtocol]? {
        get {
            return self.includedServices
        }
        set {
            self.includedServices = newValue as? [CBService]
        }
    }
    
    var genericCharacteristics: [CoreCharacteristicsProtocol]? {
        get {
            return self.characteristics
        }
        set {
            self.characteristics = newValue as? [CBCharacteristic]
        }
    }
}

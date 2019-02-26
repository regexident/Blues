// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import CoreBluetooth

internal protocol CBPeerProtocol: class {
    @available(OSX 10.13, *)
    var identifier: UUID { get }
}

internal protocol CBAttributeProtocol: class {
    var uuid: CBUUID { get }
}

internal protocol CBCharacteristicsProtocol: class {
    var service: CBService { get }
    var properties: CBCharacteristicProperties { get }
    var value: Data? { get }
    var descriptors: [CBDescriptor]? { get }
   
    @available(OSX, introduced: 10.9, deprecated: 10.13)
    var isBroadcasted: Bool { get }
    
    var isNotifying: Bool { get }
}

internal protocol CBCentralProtocol: CBPeerProtocol {
    var maximumUpdateValueLength: Int { get }
}

internal protocol CBManagerProtocol: class {
    var state: CBManagerState { get }
}

protocol CBATTRequestProtocol {
    var central: CBCentral { get }
    var characteristic: CBCharacteristic { get }
    var offset: Int { get }
    var value: Data? { get }
}

extension CBPeer: CBPeerProtocol {}
extension CBAttribute: CBAttributeProtocol {}
extension CBCentral: CBCentralProtocol {}
extension CBManager: CBManagerProtocol {}
extension CBCharacteristic: CBCharacteristicsProtocol {}
extension CBATTRequest: CBATTRequestProtocol {}

internal func protocolCast<T, U>(_ generic: T, to: U.Type) -> U? {
    guard let concrete = generic as? U else {
        Log.shared.error("Failed to cast generic value of type \(T.self) to concrete type \(U.self)")
        return nil
    }
    return concrete
}

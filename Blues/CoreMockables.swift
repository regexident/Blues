//
//  CoreCentral.swift
//  Blues
//
//  Created by Michał Kałużny on 11/09/2017.
//  Copyright © 2017 NWTN Berlin. All rights reserved.
//

import Foundation
import CoreBluetooth

internal protocol CorePeerProtocol {
    @available(OSX 10.13, *)
    var identifier: UUID { get }
}


internal protocol CoreAttributeProtocol {
    var uuid: CBUUID { get }
}

internal protocol CoreCharacteristicsProtocol: class {
    var service: CBService { get }
    var properties: CBCharacteristicProperties { get }
    var value: Data? { get }
    var descriptors: [CBDescriptor]? { get }
   
    @available(OSX, introduced: 10.9, deprecated: 10.13)
    var isBroadcasted: Bool { get }
    
    var isNotifying: Bool { get }
}

internal protocol CoreCentralProtocol: CorePeerProtocol {
    var maximumUpdateValueLength: Int { get }
}



internal protocol CoreManagerProtocol {
    var state: CBManagerState { get }
}



protocol CoreATTRequestProtocol {
    var central: CBCentral { get }
    var characteristic: CBCharacteristic { get }
    var offset: Int { get }
    var value: Data? { get }
}

extension CBPeer: CorePeerProtocol {}
extension CBAttribute: CoreAttributeProtocol {}
extension CBCentral: CoreCentralProtocol {}
extension CBManager: CoreManagerProtocol {}
extension CBCharacteristic: CoreCharacteristicsProtocol {}
extension CBATTRequest: CoreATTRequestProtocol {}

internal func protocolCast<T, U>(_ generic: T, to: U.Type) -> U? {
    guard let concrete = generic as? U else {
        Log.shared.error("Failed to cast generic value of type \(T.self) to concrete type \(U.self)")
        return nil
    }
    return concrete
}

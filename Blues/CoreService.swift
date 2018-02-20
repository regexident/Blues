//
//  CoreService.swift
//  Blues
//
//  Created by Michał Kałużny on 14/09/2017.
//  Copyright © 2017 NWTN Berlin. All rights reserved.
//

import CoreBluetooth

internal protocol CoreServiceProtocol: CoreAttributeProtocol {
    unowned(unsafe) var genericPeripheral: CorePeripheralProtocol { get }
    var isPrimary: Bool { get }
    var includedServices: [CBService]? { get }
    var characteristics: [CBCharacteristic]? { get }
}

extension CBService: CoreServiceProtocol {
    var genericPeripheral: CorePeripheralProtocol {
        return self.peripheral
    }
}

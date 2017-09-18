//
//  CBServiceMock.swift
//  BluesTests
//
//  Created by Michał Kałużny on 13/09/2017.
//  Copyright © 2017 NWTN Berlin. All rights reserved.
//

import CoreBluetooth

@testable import Blues

class CBServiceMock: CoreServiceProtocol {
    unowned(unsafe) var genericPeripheral: CorePeripheralProtocol
    
    var isPrimary: Bool = true
    var includedServices: [CBService]? = nil
    var characteristics: [CBCharacteristic]? = nil
    var uuid: CBUUID
    
    init(peripheral: CorePeripheralProtocol, uuid: CBUUID = CBUUID()) {
        self.genericPeripheral = peripheral
        self.uuid = uuid
    }
}

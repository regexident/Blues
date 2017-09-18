//
//  CoreMutableService.swift
//  Blues
//
//  Created by Michał Kałużny on 14/09/2017.
//  Copyright © 2017 NWTN Berlin. All rights reserved.
//

import CoreBluetooth

internal protocol CoreMutableServiceProtocol: CoreServiceProtocol {
    var genericIncludedServices: [CoreServiceProtocol]? { get set }
    var genericCharacteristics: [CoreCharacteristicsProtocol]? { get set }
}

extension CBMutableService: CoreMutableServiceProtocol {
    var genericIncludedServices: [CoreServiceProtocol]? {
        get {
            return includedServices
        }
        set {
            includedServices = newValue as? [CBService]
        }
    }
    
    var genericCharacteristics: [CoreCharacteristicsProtocol]? {
        get {
            return characteristics
        }
        set {
            characteristics = newValue as? [CBCharacteristic]
        }
    }
}

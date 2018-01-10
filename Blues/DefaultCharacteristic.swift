//
//  DefaultCharacteristic.swift
//  Blues
//
//  Created by Vincent Esche on 10.05.17.
//  Copyright © 2017 NWTN Berlin. All rights reserved.
//

import Foundation

/// Default implementation of `Characteristic` protocol.
open class DefaultCharacteristic:
    Characteristic, DelegatedCharacteristicProtocol, DataSourcedCharacteristicProtocol {
    public weak var delegate: CharacteristicDelegate?
    public weak var dataSource: CharacteristicDataSource?
}

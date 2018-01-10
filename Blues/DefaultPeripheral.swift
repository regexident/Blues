//
//  DefaultPeripheral.swift
//  Blues
//
//  Created by Vincent Esche on 10.05.17.
//  Copyright © 2017 NWTN Berlin. All rights reserved.
//

import Foundation

/// Default implementation of `Peripheral` protocol.
open class DefaultPeripheral:
    Peripheral, DelegatedPeripheralProtocol, DataSourcedPeripheralProtocol {
    public weak var delegate: PeripheralDelegate?
    public weak var dataSource: PeripheralDataSource?
}

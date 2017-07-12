//
//  DefaultPeripheral.swift
//  Blues
//
//  Created by Vincent Esche on 10.05.17.
//  Copyright © 2017 NWTN Berlin. All rights reserved.
//

import Foundation

import Result

/// Default implementation of `Peripheral` protocol.
open class DefaultPeripheral:
    Peripheral, DelegatedPeripheralProtocol, DataSourcedPeripheralProtocol {
    public weak var delegate: PeripheralDelegate?
    public weak var dataSource: PeripheralDataSource?
}

// MARK: - PeripheralDataSource
extension DefaultPeripheral: PeripheralDataSource {
    public func service(with identifier: Identifier, for peripheral: Peripheral) -> Service {
        if let dataSource = self.dataSource {
            return dataSource.service(with: identifier, for: peripheral)
        } else {
            return DefaultService(identifier: identifier, peripheral: peripheral)
        }
    }
}

// MARK: - PeripheralDelegate
extension DefaultPeripheral: PeripheralDelegate {
    public func didUpdate(name: String?, of peripheral: Peripheral) {
        self.delegate?.didUpdate(name: name, of: peripheral)
    }

    public func didModify(services: [Service], of peripheral: Peripheral) {
        self.delegate?.didModify(services: services, of: peripheral)
    }

    public func didRead(rssi: Result<Int, Error>, of peripheral: Peripheral) {
        self.delegate?.didRead(rssi: rssi, of: peripheral)
    }

    public func didDiscover(services: Result<[Service], Error>, for peripheral: Peripheral) {
        self.delegate?.didDiscover(services: services, for: peripheral)
    }
}

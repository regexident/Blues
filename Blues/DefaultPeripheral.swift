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
open class DefaultPeripheral: Peripheral {
    public weak var delegate: PeripheralDelegate?
    public weak var dataSource: PeripheralDataSource?
}

extension DefaultPeripheral: PeripheralDataSource {
    public func service(with identifier: Identifier, for peripheral: Peripheral) -> Service {
        if let dataSource = self.dataSource {
            return dataSource.service(with: identifier, for: peripheral)
        } else {
            return DefaultService(identifier: identifier, peripheral: peripheral)
        }
    }
}

extension DefaultPeripheral: PeripheralDelegate {
    public func willConnect(to peripheral: Peripheral) {
        self.delegate?.willConnect(to: peripheral)
    }

    public func didConnect(to peripheral: Peripheral) {
        self.delegate?.didConnect(to: peripheral)
    }

    public func willDisconnect(from peripheral: Peripheral) {
        self.delegate?.willDisconnect(from: peripheral)
    }

    public func didDisconnect(from peripheral: Peripheral, error: Swift.Error?) {
        self.delegate?.didDisconnect(from: peripheral, error: error)
    }

    public func didFailToConnect(to peripheral: Peripheral, error: Swift.Error?) {
        self.delegate?.didFailToConnect(to: peripheral, error: error)
    }

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

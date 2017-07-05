//
//  DefaultCentralManager.swift
//  Blues
//
//  Created by Vincent Esche on 7/5/17.
//  Copyright © 2017 NWTN Berlin. All rights reserved.
//

import Foundation

open class DefaultCentralManager: CentralManager {
    public static let `default`: DefaultCentralManager = .init()

    public weak var delegate: CentralManagerDelegate?
    public weak var dataSource: CentralManagerDataSource?

    public init(
        delegate: CentralManagerDelegate? = nil,
        dataSource: CentralManagerDataSource? = nil,
        options: CentralManagerOptions? = nil,
        queue: DispatchQueue = .global()
    ) {
        self.delegate = delegate
        self.dataSource = dataSource
        super.init(options: options, queue: queue)
    }
}

extension DefaultCentralManager: CentralManagerDataSource {
    public func peripheral(
        with identifier: Identifier,
        advertisement: Advertisement?,
        for manager: CentralManager
    ) -> Peripheral {
        guard let dataSource = self.dataSource else {
            return DefaultPeripheral(identifier: identifier, centralManager: manager)
        }
        return dataSource.peripheral(with: identifier, advertisement: advertisement, for: manager)
    }
}

extension DefaultCentralManager: CentralManagerDelegate {
    public func willRestore(state: CentralManagerRestoreState, of manager: CentralManager) {
        self.delegate?.willRestore(state: state, of: manager)
    }

    public func didUpdateState(of manager: CentralManager) {
        self.delegate?.didUpdateState(of: manager)
    }

    public func didDiscover(peripheral: Peripheral, rssi: Int, with manager: CentralManager) {
        self.delegate?.didDiscover(peripheral: peripheral, rssi: rssi, with: manager)
    }

    public func didRestore(peripheral: Peripheral, with manager: CentralManager) {
        self.delegate?.didRestore(peripheral: peripheral, with: manager)
    }

    public func didRetrieve(peripherals: [Peripheral], from manager: CentralManager) {
        self.delegate?.didRetrieve(peripherals: peripherals, from: manager)
    }

    public func didRetrieve(connectedPeripherals: [Peripheral], from manager: CentralManager) {
        self.delegate?.didRetrieve(connectedPeripherals: connectedPeripherals, from: manager)
    }
}

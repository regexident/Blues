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

    public weak var stateDelegate: CentralManagerStateDelegate?
    public weak var retrievalDelegate: CentralManagerRetrievalDelegate?
    public weak var restorationDelegate: CentralManagerRestorationDelegate?
    public weak var connectionDelegate: CentralManagerConnectionDelegate?

    public weak var dataSource: CentralManagerDataSource?

    public required init(
        options: CentralManagerOptions? = nil,
        queue: DispatchQueue = .global()
    ) {
        super.init(options: options, queue: queue)
    }
}

// MARK: - CentralManagerDataSource
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

// MARK: - CentralManagerStateDelegate
extension DefaultCentralManager: CentralManagerStateDelegate {
    public func didUpdateState(of manager: CentralManager) {
        self.stateDelegate?.didUpdateState(of: manager)
    }
}

// MARK: - CentralManagerRetrievalDelegate
extension DefaultCentralManager: CentralManagerRetrievalDelegate {
    public func didDiscover(peripheral: Peripheral, rssi: Int, with manager: CentralManager) {
        self.retrievalDelegate?.didDiscover(peripheral: peripheral, rssi: rssi, with: manager)
    }

    public func didRetrieve(peripherals: [Peripheral], from manager: CentralManager) {
        self.retrievalDelegate?.didRetrieve(peripherals: peripherals, from: manager)
    }

    public func didRetrieve(connectedPeripherals: [Peripheral], from manager: CentralManager) {
        self.retrievalDelegate?.didRetrieve(connectedPeripherals: connectedPeripherals, from: manager)
    }
}

// MARK: - CentralManagerRestorationDelegate
extension DefaultCentralManager: CentralManagerRestorationDelegate {
    public func willRestore(state: CentralManagerRestoreState, of manager: CentralManager) {
        self.restorationDelegate?.willRestore(state: state, of: manager)
    }

    public func didRestore(peripheral: Peripheral, with manager: CentralManager) {
        self.restorationDelegate?.didRestore(peripheral: peripheral, with: manager)
    }
}

// MARK: - CentralManagerConnectionDelegate
extension DefaultCentralManager: CentralManagerConnectionDelegate {
    public func willConnect(to peripheral: Peripheral, on manager: CentralManager) {
        self.connectionDelegate?.willConnect(to: peripheral, on: manager)
    }

    public func didConnect(to peripheral: Peripheral, on manager: CentralManager) {
        self.connectionDelegate?.didConnect(to: peripheral, on: manager)
    }

    public func willDisconnect(from peripheral: Peripheral, on manager: CentralManager) {
        self.connectionDelegate?.willDisconnect(from: peripheral, on: manager)
    }

    public func didDisconnect(from peripheral: Peripheral, error: Swift.Error?, on manager: CentralManager) {
        self.connectionDelegate?.didDisconnect(from: peripheral, error: error, on: manager)
    }

    public func didFailToConnect(to peripheral: Peripheral, error: Swift.Error?, on manager: CentralManager) {
        self.connectionDelegate?.didFailToConnect(to: peripheral, error: error, on: manager)
    }
}

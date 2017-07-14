//
//  DefaultCentralManager.swift
//  Blues
//
//  Created by Vincent Esche on 7/5/17.
//  Copyright © 2017 NWTN Berlin. All rights reserved.
//

import Foundation

open class DefaultCentralManager:
    CentralManager, DelegatedCentralManagerProtocol, DataSourcedCentralManagerProtocol
{
    public static let `default`: DefaultCentralManager = .init()

    public weak var delegate: CentralManagerDelegate?
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
        if let delegate = self.delegate as? CentralManagerStateDelegate {
            delegate.didUpdateState(of: manager)
        }
    }
}

// MARK: - CentralManagerDiscoveryDelegate
extension DefaultCentralManager: CentralManagerDiscoveryDelegate {
    public func didStartScanningForPeripherals(with manager: CentralManager) {
        if let delegate = self.delegate as? CentralManagerDiscoveryDelegate {
            delegate.didStartScanningForPeripherals(with: manager)
        }
    }

    public func didStopScanningForPeripherals(with manager: CentralManager) {
        if let delegate = self.delegate as? CentralManagerDiscoveryDelegate {
            delegate.didStopScanningForPeripherals(with: manager)
        }
    }

    public func didDiscover(peripheral: Peripheral, rssi: Int, with manager: CentralManager) {
        if let delegate = self.delegate as? CentralManagerDiscoveryDelegate {
            delegate.didDiscover(peripheral: peripheral, rssi: rssi, with: manager)
        }
    }
}

// MARK: - CentralManagerRetrievalDelegate
extension DefaultCentralManager: CentralManagerRetrievalDelegate {
    public func didRetrieve(peripherals: [Peripheral], from manager: CentralManager) {
        if let delegate = self.delegate as? CentralManagerRetrievalDelegate {
            delegate.didRetrieve(peripherals: peripherals, from: manager)
        }
    }

    public func didRetrieve(connectedPeripherals: [Peripheral], from manager: CentralManager) {
        if let delegate = self.delegate as? CentralManagerRetrievalDelegate {
            delegate.didRetrieve(connectedPeripherals: connectedPeripherals, from: manager)
        }
    }
}

// MARK: - CentralManagerRestorationDelegate
extension DefaultCentralManager: CentralManagerRestorationDelegate {
    public func willRestore(state: CentralManagerRestoreState, of manager: CentralManager) {
        if let delegate = self.delegate as? CentralManagerRestorationDelegate {
            delegate.willRestore(state: state, of: manager)
        }
    }

    public func didRestore(peripheral: Peripheral, with manager: CentralManager) {
        if let delegate = self.delegate as? CentralManagerRestorationDelegate {
            delegate.didRestore(peripheral: peripheral, with: manager)
        }
    }
}

// MARK: - CentralManagerConnectionDelegate
extension DefaultCentralManager: CentralManagerConnectionDelegate {
    public func willConnect(to peripheral: Peripheral, on manager: CentralManager) {
        if let delegate = self.delegate as? CentralManagerConnectionDelegate {
            delegate.willConnect(to: peripheral, on: manager)
        }
    }

    public func didConnect(to peripheral: Peripheral, on manager: CentralManager) {
        if let delegate = self.delegate as? CentralManagerConnectionDelegate {
            delegate.didConnect(to: peripheral, on: manager)
        }
    }

    public func willDisconnect(from peripheral: Peripheral, on manager: CentralManager) {
        if let delegate = self.delegate as? CentralManagerConnectionDelegate {
            delegate.willDisconnect(from: peripheral, on: manager)
        }
    }

    public func didDisconnect(from peripheral: Peripheral, error: Swift.Error?, on manager: CentralManager) {
        if let delegate = self.delegate as? CentralManagerConnectionDelegate {
            delegate.didDisconnect(from: peripheral, error: error, on: manager)
        }
    }

    public func didFailToConnect(to peripheral: Peripheral, error: Swift.Error?, on manager: CentralManager) {
        if let delegate = self.delegate as? CentralManagerConnectionDelegate {
            delegate.didFailToConnect(to: peripheral, error: error, on: manager)
        }
    }
}

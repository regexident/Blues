//
//  Peripheral.swift
//  Blues
//
//  Created by Vincent Esche on 26/10/2016.
//  Copyright © 2016 NWTN Berlin. All rights reserved.
//

import Foundation
import CoreBluetooth

public class DefaultPeripheral: Peripheral, DelegatedPeripheral {
    public let shadow: ShadowPeripheral
    public weak var delegate: PeripheralDelegate?

    public required init(shadow: ShadowPeripheral, advertisement: Advertisement) {
        self.shadow = shadow
    }

    public func makeService(shadow: ShadowService) -> Service {
        return DefaultService(shadow: shadow)
    }
}

extension DefaultPeripheral {

    public func willRestore(peripheral: Peripheral) {
        self.delegate?.willRestore(peripheral: peripheral)
    }

    public func didRestore(peripheral: Peripheral) {
        self.delegate?.didRestore(peripheral: peripheral)
    }

    public func willConnect(peripheral: Peripheral) {
        self.delegate?.willConnect(peripheral: peripheral)
    }

    public func didConnect(peripheral: Peripheral) {
        self.delegate?.didConnect(peripheral: peripheral)
    }

    public func didDisconnect(peripheral: Peripheral, error: Swift.Error?) {
        self.delegate?.didDisconnect(peripheral: peripheral, error: error)
    }

    public func didFailToConnect(peripheral: Peripheral, error: Swift.Error?) {
        self.delegate?.didFailToConnect(peripheral: peripheral, error: error)
    }

    public func didUpdate(name: String?, ofPeripheral peripheral: Peripheral) {
        self.delegate?.didUpdate(name: name, ofPeripheral: peripheral)
    }

    public func didModify(services: [Service], ofPeripheral peripheral: Peripheral) {
        self.delegate?.didModify(services: services, ofPeripheral: peripheral)
    }

    public func didRead(rssi: Result<Int, Error>, ofPeripheral peripheral: Peripheral) {
        self.delegate?.didRead(rssi: rssi, ofPeripheral: peripheral)
    }

    public func didDiscover(services: Result<[Service], Error>, forPeripheral peripheral: Peripheral) {
        self.delegate?.didDiscover(services: services, forPeripheral: peripheral)
    }
}

extension DefaultPeripheral: CustomStringConvertible {
    public var description: String {
        let attributes = [
            "uuid = \(self.shadow.uuid)",
            "name = \(self.name ?? "<nil>")",
            "state = \(self.state)",
        ].joined(separator: ", ")
        return "<DefaultPeripheral \(attributes)>"
    }
}

public protocol Peripheral: class, PeripheralDelegate {
    var name: String? { get }
    var shadow: ShadowPeripheral { get }

    init(shadow: ShadowPeripheral, advertisement: Advertisement)

    func makeService(shadow: ShadowService) -> Service

    func discover(services: [Identifier]?) -> Result<(), PeripheralError>
}

extension Peripheral {
    public var uuid: Identifier {
        return self.shadow.uuid
    }

    /// The name of the peripheral
    public var name: String? {
        return self.core.name
    }

    /// The state of the peripheral
    public var state: PeripheralState {
        return PeripheralState(state: self.core.state)
    }

    public var services: [Identifier: Service]? {
        return self.shadow.services
    }

    public var connectionOptions: Result<ConnectionOptions, PeripheralError> {
        guard let connectionOptions = self.shadow.connectionOptions else {
            return .err(.unreachable)
        }
        return .ok(connectionOptions)
    }

    var nextResponder: Responder? {
        return .some((self.shadow as! Responder))
    }

    public func connect(options: ConnectionOptions? = nil) -> Result<(), PeripheralError> {
        return (self as! Responder).tryToHandle(ConnectPeripheralMessage(
            peripheral: self,
            options: options
        )) ?? .err(.unhandled)
    }

    public func disconnect() -> Result<(), PeripheralError> {
        return (self as! Responder).tryToHandle(DisconnectPeripheralMessage(
            peripheral: self
        )) ?? .err(.unhandled)
    }

    public func discover(services: [Identifier]?) -> Result<(), PeripheralError> {
        return (self as! Responder).tryToHandle(DiscoverServicesMessage(
            uuids: services
        )) ?? .err(.unhandled)
    }

    public func readRSSI() {
        let _ = (self as! Responder).tryToHandle(ReadRSSIMessage())
    }

    var core: CBPeripheral {
        return self.shadow.core
    }
}

public protocol DelegatedPeripheral: Peripheral {
    weak var delegate: PeripheralDelegate? { get set }
}

public protocol PeripheralDelegate: class {
    /// Invoked when the central manager is about to restore a peripheral's state.
    ///
    /// - parameter peripheral: The peripheral that will be restored.
    func willRestore(peripheral: Peripheral)

    /// Invoked when the central manager has restored a peripheral's state.
    ///
    /// - parameter peripheral: The peripheral that has been restored.
    func didRestore(peripheral: Peripheral)

    /// Invoked when a connection is about to be created with a peripheral.
    ///
    /// - parameter peripheral: The peripheral that will be connected to the system.
    func willConnect(peripheral: Peripheral)

    /// Invoked when a connection is successfully created with a peripheral.
    ///
    /// - parameter peripheral: The peripheral that has been connected to the system.
    func didConnect(peripheral: Peripheral)

    /// Invoked when an existing connection with a peripheral is torn down.
    ///
    /// - parameter peripheral: The peripheral that has been disconnected.
    /// - parameter error:      The cause of the failure.
    func didDisconnect(peripheral: Peripheral, error: Swift.Error?)

    /// Invoked when the central manager fails to create a connection with a peripheral.
    ///
    /// - parameter peripheral: The peripheral that failed to connect.
    /// - parameter error:      The cause of the failure.
    func didFailToConnect(peripheral: Peripheral, error: Swift.Error?)

    func didUpdate(name: String?, ofPeripheral peripheral: Peripheral)
    func didModify(services: [Service], ofPeripheral peripheral: Peripheral)
    func didRead(rssi: Result<Int, Error>, ofPeripheral peripheral: Peripheral)
    func didDiscover(services: Result<[Service], Error>, forPeripheral peripheral: Peripheral)
}

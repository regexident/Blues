//
//  Peripheral.swift
//  Blues
//
//  Created by Vincent Esche on 26/10/2016.
//  Copyright © 2016 NWTN Berlin. All rights reserved.
//

import Foundation
import CoreBluetooth

import Result

/// Default implementation of `Peripheral` protocol.
public class DefaultPeripheral: DelegatedPeripheral, DataSourcedPeripheral {

    public let shadow: ShadowPeripheral

    public weak var delegate: PeripheralDelegate?
    public weak var dataSource: PeripheralDataSource?

    public required init(shadow: ShadowPeripheral) {
        self.shadow = shadow
    }
}

public protocol Peripheral:
    class, PeripheralDataSource, PeripheralDelegate, CustomStringConvertible {

    /// The peripheral's name.
    ///
    /// - Note:
    ///   Default implementation returns `nil`
    var name: String? { get }

    /// The supporting "shadow" peripheral that does the heavy lifting.
    var shadow: ShadowPeripheral { get }

    /// Whether the peripheral should discover services automatically
    ///
    /// - Note:
    ///   Default implementation returns `true`
    var shouldDiscoverServicesAutomatically: Bool { get }

    /// Initializes a `Peripheral` as a shim for a provided shadow service.
    ///
    /// - Parameters:
    ///   - shadow: The peripheral's "shadow" peripheral
    init(shadow: ShadowPeripheral)
}

extension Peripheral {

    /// The Bluetooth-specific identifier of the peripheral.
    public var uuid: Identifier {
        return self.shadow.uuid
    }

    public var name: String? {
        return self.core.name
    }

    public var shouldDiscoverServicesAutomatically: Bool {
        return true
    }

    /// The state of the peripheral
    public var state: PeripheralState {
        return PeripheralState(state: self.core.state)
    }

    /// A list of services on the peripheral that have been discovered.
    ///
    /// - Note:
    ///   This dictionary contains `Service` objects that represent a
    ///   peripheral’s services. If you have yet to call the `discover(services:)`
    ///   method to discover the services of the peripheral, or if there was
    ///   an error in doing so, the value of this property is nil.
    public var services: [Identifier: Service]? {
        return self.shadow.services
    }

    /// `.ok(connectionOptions) with options customizing the behavior of the
    /// connection iff successful, `.err(error)` otherwise.
    public var connectionOptions: Result<ConnectionOptions, PeripheralError> {
        guard let connectionOptions = self.shadow.connectionOptions else {
            return .err(.unreachable)
        }
        return .ok(connectionOptions)
    }

    var core: CBPeripheral {
        return self.shadow.core
    }

    /// Establishes a local connection to a peripheral.
    ///
    /// - Note:
    ///   If a local connection to a peripheral is about to establish it
    ///   calls the `didConnect(peripheral:)` method of its delegate object.
    ///
    ///   If a local connection to a peripheral has been successfully established,
    ///   it calls the `didConnect(peripheral:)` method of its delegate object.
    ///
    ///   If the connection attempt fails, it calls the `didFailToConnect(peripheral:error:)`
    ///   method of its delegate object instead.
    ///
    /// - Important:
    ///   Attempts to connect to a peripheral do not time out.
    ///   To explicitly cancel a pending connection to a peripheral, call the
    ///   `disconnect()` method. The disconnect() method is implicitly called
    ///   when a peripheral is deallocated.
    ///
    /// - Parameters:
    ///   - options: Options customizing the behavior of the connection
    ///
    /// - Returns: `.ok(())` iff successful, `.err(error)` otherwise.
    public func connect(options: ConnectionOptions? = nil) -> Result<(), PeripheralError> {
        return self.shadow.tryToHandle(ConnectPeripheralMessage(
            peripheral: self,
            options: options
        )) ?? .err(.unhandled)
    }

    /// Cancels an active or pending local connection to a peripheral.
    ///
    /// - Note:
    ///   This method is nonblocking, and any Peripheral class commands that are
    ///   still pending to peripheral may or may not complete.
    ///
    /// - Important:
    ///   Because other apps may still have a connection to the peripheral,
    ///   canceling a local connection does not guarantee that the underlying
    ///   physical link is immediately disconnected. From the app’s perspective,
    ///   however, the peripheral is considered disconnected, and it calls the
    ///   `didDisconnect(peripheral:error:)` method of its delegate object.
    ///
    /// - Returns: `.ok(())` iff successful, `.err(error)` otherwise.
    public func disconnect() -> Result<(), PeripheralError> {
        return self.shadow.tryToHandle(DisconnectPeripheralMessage(
            peripheral: self
        )) ?? .err(.unhandled)
    }

    /// Discovers the specified services of the peripheral.
    ///
    /// - Note:
    ///   You can provide an array of `Identifier` objects—representing service
    ///   identifiers—in the `services` parameter. When you do, the peripheral
    ///   returns only the services of the peripheral that your app is interested
    ///   in (recommended).
    ///
    /// - Important:
    ///   If the `services` parameter is `nil`, all the available services of
    ///   the peripheral are returned; setting the parameter to `nil` is
    ///   considerably slower and is not recommended. When the peripheral discovers
    ///   one or more services, it calls the `didDiscover(services:forPeripheral:)`
    ///   method of its delegate object.
    ///
    /// - Parameters:
    ///   - services: An array of `Identifier` objects that you are interested in.
    ///     Here, each `Identifier` identifies the type of service you want to discover.
    ///
    /// - Returns: `.ok(())` iff successful, `.err(error)` otherwise.
    public func discover(services: [Identifier]?) -> Result<(), PeripheralError> {
        return self.shadow.tryToHandle(DiscoverServicesMessage(
            uuids: services
        )) ?? .err(.unhandled)
    }

    /// Retrieves the current RSSI value for the peripheral
    /// while it is connected to the central manager.
    ///
    /// - Note:
    ///   In iOS and tvOS, when you call this method to retrieve the RSSI of the
    ///   peripheral while it is currently connected to the central manager,
    ///   the peripheral calls the `didRead(rssi:ofPeripheral:)` method of its
    ///   delegate object, which includes the RSSI value as a parameter.
    public func readRSSI() -> Result<(), PeripheralError> {
        return self.shadow.tryToHandle(ReadRSSIMessage(
            // no arguments
        )) ?? .err(.unhandled)
    }

    public var description: String {
        let attributes = [
            "uuid = \(self.shadow.uuid)",
            "name = \(self.name ?? "<nil>")",
            "state = \(self.state)",
        ].joined(separator: ", ")
        return "<DefaultPeripheral \(attributes)>"
    }
}

extension Peripheral {

    func service(shadow: ShadowService, forPeripheral peripheral: Peripheral) -> Service {
        return DefaultService(shadow: shadow)
    }
}

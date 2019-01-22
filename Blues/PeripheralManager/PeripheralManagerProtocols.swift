// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import CoreBluetooth

#if os(iOS) || os(OSX)

public protocol PeripheralManagerProtocol: class {
    @available(iOS 10.0, *)
    @available(iOSApplicationExtension 10.0, *)
    var state: ManagerState { get }
    
    var delegate: PeripheralManagerDelegate? { get set }

    var isAdvertising: Bool { get }

    static func authorizationStatus() -> PeripheralManagerAuthorizationStatus

    init(queue: DispatchQueue, options: [String : Any]?)

    func startAdvertising(_ advertisement: Advertisement?)
    func stopAdvertising()

    func setDesiredConnectionLatency(
        _ latency: PeripheralManagerConnectionLatency,
        for central: Central
    )

    func add(_ service: MutableService)
    func remove(_ service: MutableService)
    func removeAllServices()

    func respond(to request: ATTRequest, withResult result: CBATTError.Code)

    func update(
        data: Data,
        for characteristic: MutableCharacteristic,
        onSubscribedCentrals centrals: [Central]?
    ) -> Bool
}

public protocol DelegatedPeripheralManagerProtocol: PeripheralManagerProtocol {
    var delegate: PeripheralManagerDelegate? { get set }
}

@available(iOS 11.0, watchOS 4.0, macOS 10.13, tvOS 11.0, *)
public protocol L2CAPPeripheralManagerProtocol: PeripheralManagerProtocol {
    func publishL2CAPChannel(withEncryption encryptionRequired: Bool)

    func unpublishL2CAPChannel(_ psm: L2CAPPSM)
}

/// The delegate of a `PeripheralManager` object must adopt the `PeripheralManagerDelegate`
/// protocol. The single required method indicates the availability of the peripheral manager,
/// while the optional methods provide information about centrals, which can connect and access
/// the local database.
public protocol PeripheralManagerDelegate: class {}

public protocol PeripheralManagerStateDelegate: PeripheralManagerDelegate {
    /// Invoked whenever the peripheral manager's state has been updated. Commands should only be
    /// issued when the state is `poweredOn`. A state below `poweredOn` implies that advertisement
    /// has paused and any connected centrals have been disconnected. If the state moves below
    /// `poweredOff`, advertisement is stopped and must be explicitly restarted, and the
    /// local database is cleared and all services must be re-added.
    ///
    /// - Parameters:
    ///   - manager: The peripheral manager whose state has changed.
    func peripheralManagerDidUpdateState(_ manager: PeripheralManager)
}

public protocol PeripheralManagerRestorationDelegate: PeripheralManagerDelegate {
    /// For apps that opt-in to state preservation and restoration, this is the first method invoked
    /// when your app is relaunched into the background to complete some Bluetooth-related task.
    /// Use this method to synchronize your app's state with the state of the Bluetooth system.
    ///
    /// - Parameters:
    ///   - manager: The peripheral manager providing this information.
    ///   - dict: A dictionary containing information about _peripheral_ that
    ///     was preserved by the system at the time the app was terminated.
    func peripheralManager(
        _ manager: PeripheralManager,
        willRestoreState state: PeripheralManagerRestoreState
    )
}

public protocol PeripheralManagerAdvertisingDelegate: PeripheralManagerDelegate {
    /// This method returns the result of a `startAdvertising:` call. If advertisement could not
    /// be started, the cause will be detailed in the _error_ parameter.
    ///
    /// - Parameters:
    ///   - manager: The peripheral manager providing this information.
    ///   - error: If an error occurred, the cause of the failure.
    func peripheralManagerDidStartAdvertising(_ manager: PeripheralManager, error: Error?)
}

public protocol PeripheralManagerServiceAdditionDelegate: PeripheralManagerDelegate {
    /// This method returns the result of an @link addService: @/link call. If the service could
    /// not be published to the local database, the cause will be detailed in the _error_ parameter.
    ///
    /// - Parameters:
    ///   - manager: The peripheral manager providing this information.
    ///   - service: The service that was added to the local database.
    ///   - error: If an error occurred, the cause of the failure.
    func peripheralManager(_ manager: PeripheralManager, didAdd service: MutableService, error: Error?)
}

public protocol PeripheralManagerSubscriptionDelegate: PeripheralManagerDelegate {
    /// This method is invoked when a central configures _characteristic_ to notify or indicate.
    /// It should be used as a cue to start sending updates as the characteristic value changes.
    ///
    /// - Parameters:
    ///   - manager: The peripheral manager providing this update.
    ///   - central: The central that issued the command.
    ///   - characteristic: The characteristic on which notifications or indications were enabled.
    func peripheralManager(
        _ manager: PeripheralManager,
        central: Central,
        didSubscribeTo characteristic: MutableCharacteristic
    )

    /// This method is invoked when a central removes notifications/indications
    /// from _characteristic_.
    ///
    /// - Parameters:
    ///   - manager: The peripheral manager providing this update.
    ///   - central: The central that issued the command.
    ///   - characteristic: The characteristic on which notifications or indications were disabled.
    func peripheralManager(
        _ manager: PeripheralManager,
        central: Central,
        didUnsubscribeFrom characteristic: Characteristic
    )
}

public protocol PeripheralManagerReadingDelegate: PeripheralManagerDelegate {
    /// This method is invoked when _peripheral_ receives an ATT request for a characteristic with
    /// a dynamic value. For every invocation of this method, `respondToRequest:withResult:`
    /// must be called.
    ///
    /// - Parameters:
    ///   - manager: The peripheral manager requesting this information.
    ///   - request: A `ATTRequest` object.
    func peripheralManager(_ manager: PeripheralManager, didReceiveRead request: ATTRequest)
}

public protocol PeripheralManagerWritingDelegate: PeripheralManagerDelegate {
    /// This method is invoked when _peripheral_ receives an ATT request or command for one or more
    /// characteristics with a dynamic value. For every invocation of this method,
    /// `respondToRequest:withResult:` should be called exactly once. If _requests_ contains
    /// multiple requests, they must be treated as an atomic unit. If the execution of one of the
    /// requests would cause a failure, the request and error reason should be provided to
    /// `respondToRequest:withResult:` and none of the requests should be executed.
    ///
    /// - Parameters:
    ///   - manager: The peripheral manager requesting this information.
    ///   - requests: A list of one or more `ATTRequest` objects.
    func peripheralManager(_ manager: PeripheralManager, didReceiveWrite requests: [ATTRequest])

    /// This method is invoked after a failed call to
    /// `updateValue:forCharacteristic:onSubscribedCentrals:`, when _peripheral_ is again ready
    /// to send characteristic value updates.
    ///
    /// - Parameters:
    ///   - manager: The peripheral manager providing this update.
    func peripheralManagerIsReady(toUpdateSubscribers manager: PeripheralManager)
}

@available(iOS 6.0, watchOS 4.0, macOS 10.9, tvOS 11.0, *)
public protocol PeripheralManagerL2CAPDelegate: PeripheralManagerDelegate {
    /// This method is the response to a `self.publishL2CAPChannel(_:)` call.
    ///
    /// The PSM will contain the PSM that was assigned for the published channel.
    ///
    /// - Parameters:
    ///   - manager: The peripheral manager requesting this information.
    ///   - psm: The PSM of the channel that was published.
    ///   - error: If an error occurred, the cause of the failure.
    func peripheralManager(_ manager: PeripheralManager, didPublishL2CAPChannel psm: L2CAPPSM, error: Error?)
    
    /// This method is the response to a `self.unpublishL2CAPChannel(_:)` call.
    ///
    /// The PSM will contain the PSM that was assigned for the unpublished channel.
    ///
    /// - Parameters:
    ///   - manager: The peripheral manager requesting this information.
    ///   - psm: The PSM of the channel that was unpublished.
    ///   - error: If an error occurred, the cause of the failure.
    func peripheralManager(_ manager: PeripheralManager, didUnpublishL2CAPChannel psm: L2CAPPSM, error: Error?)
    
    /// This method is the response to a `peripheral.openL2CAPChannel(_:)` call.
    ///
    /// - Parameters:
    ///   - manager: The peripheral manager requesting this information.
    ///   - channel: The channel that was opened.
    ///   - error: If an error occurred, the cause of the failure.
    @available(iOS 11.0, watchOS 4.0, macOS 10.13, tvOS 11.0, *)
    func peripheralManager(_ manager: PeripheralManager, didOpen channel: L2CAPChannel?, error: Error?)
}

#endif

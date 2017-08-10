//
//  PeripheralManager.swift
//  Blues
//
//  Created by Vincent Esche on 7/15/17.
//  Copyright © 2017 NWTN Berlin. All rights reserved.
//

import Foundation
import CoreBluetooth

#if os(iOS) || os(OSX)

/// The `PeripheralManager` class is an abstraction of the Peripheral and Broadcaster GAP roles,
/// and the GATT Server role. Its primary function is to allow you to manage published services
/// within the GATT database, and to advertise these services to other devices.
/// Each application has sandboxed access to the shared GATT database. You can add services to the
/// database by calling `addService:` they can be removed via `removeService:` and
/// `removeAllServices`,as appropriate. While a service is in the database, it is visible to and
/// can be accessed by any connected GATT Client. However, applications that have not specified
/// the "bluetooth-peripheral" background mode will have the contents of their service(s)
/// "disabled" when in the background. Any remote device trying to access characteristic values or
/// descriptors during this time will receive an error response. Once you've published services that
/// you want to share, you can ask to advertise their availability and allow other devices to
/// connect to you by calling {@link startAdvertising:}. Like the GATT database, advertisement is
/// managed at the system level and shared by all applications. This means that even if you aren't
/// advertising at the moment, someone else might be!
open class PeripheralManager: NSObject, PeripheralManagerProtocol {
    /// The delegate object that will receive peripheral events.
    public weak var delegate: PeripheralManagerDelegate?

    /// Whether or not the peripheral is currently advertising data.
    open var isAdvertising: Bool {
        return self.core.isAdvertising
    }

    internal var core: CBPeripheralManager!

    @available(iOS 10.0, *)
    @available(iOSApplicationExtension 10.0, *)
    public var state: ManagerState {
        return ManagerState(from: self.core.state)
    }

    /// This method does not prompt the user for access. You can use it to detect restricted access
    /// and simply hide UI instead of prompting for access.
    ///
    /// - Returns: The current authorization status for sharing data while backgrounded.
    ///   For the constants returned, see {@link PeripheralManagerAuthorizationStatus}.
    public class func authorizationStatus() -> PeripheralManagerAuthorizationStatus {
        return PeripheralManager.authorizationStatus()
    }

    /// The initialization call. The events of the peripheral role will be dispatched
    /// on the provided queue. If `nil`, the main queue will be used.
    ///
    /// - Parameters:
    ///   - delegate: The delegate that will receive peripheral role events.
    ///   - queue: The dispatch queue on which the events will be dispatched.
    ///   - options: An optional dictionary specifying options for the manager.
    public convenience required init(
        queue: DispatchQueue = .global(),
        options: [String : Any]? = nil
    ) {
        self.init()
        self.core = CBPeripheralManager(delegate: self, queue: queue, options: options)
        self.core.delegate = self
    }

    /// Starts advertising. Supported advertising data types are `AdvertisementDataLocalNameKey`
    /// and `AdvertisementDataServiceUUIDsKey`. When in the foreground, an application can utilize
    /// up to 28 bytes of space in the initial advertisement data for any combination of the
    /// supported advertising data types. If this space is used up, there are an additional 10 bytes
    /// of space in the scan response that can be used only for the local name. Note that these
    /// sizes do not include the 2 bytes of header information that are required for each new data
    /// type. Any service UUIDs that do not fit in the allotted space will be added to a special
    /// "overflow" area, and can only be discovered by an iOS device that is explicitly scanning
    /// for them. While an application is in the background, the local name will not be used and all
    /// service UUIDs will be placed in the "overflow" area. However, applications that have not
    /// specified the "bluetooth-peripheral" background mode will not be able to advertise anything
    /// while in the background.
    ///
    /// - Parameter advertisementData: An optional dictionary containing the data to be advertised.
    public func startAdvertising(_ advertisement: Advertisement?) {
        assert(self.state == .poweredOn, self.apiMisuseErrorMessage())
        self.core.startAdvertising(advertisement?.dictionary)
    }

    /// Stops advertising.
    public func stopAdvertising() {
        assert(self.state == .poweredOn, self.apiMisuseErrorMessage())
        self.core.stopAdvertising()
    }

    /// Sets the desired connection latency for an existing connection to _central_.
    /// Connection latency changes are not guaranteed, so the resultant latency may vary.
    /// If a desired latency is not set, the latency chosen by _central_ at the time of connection
    /// establishment will be used. Typically, it is not necessary to change the latency.
    ///
    /// - Parameters:
    ///   - latency: The desired connection latency.
    ///   - central: A connected central.
    public func setDesiredConnectionLatency(
        _ latency: PeripheralManagerConnectionLatency,
        for central: Central
    ) {
        assert(self.state == .poweredOn, self.apiMisuseErrorMessage())
        self.core.setDesiredConnectionLatency(latency.core, for: central.core)
    }

    /// Publishes a service and its associated characteristic(s) to the local database.
    /// If the service contains included services, they must be published first.
    ///
    /// - Parameter service: A GATT service.
    public func add(_ service: MutableService) {
        assert(self.state == .poweredOn, self.apiMisuseErrorMessage())
        self.core.add(service.core)
    }

    /// Removes a published service from the local database.
    /// If the service is included by other service(s), they must be removed first.
    ///
    /// - Parameter service: A GATT service.
    public func remove(_ service: MutableService) {
        assert(self.state == .poweredOn, self.apiMisuseErrorMessage())
        self.core.remove(service.core)
    }

    /// Removes all published services from the local database.
    public func removeAllServices() {
        assert(self.state == .poweredOn, self.apiMisuseErrorMessage())
        self.core.removeAllServices()
    }

    /// Used to respond to request(s) received via the `peripheralManager:didReceiveReadRequest:`
    /// or `peripheralManager:didReceiveWriteRequests:` delegate methods.
    ///
    /// - Parameters:
    ///   - request: The original request that was received from the central.
    ///   - result: The result of attempting to fulfill _request_.
    public func respond(to request: ATTRequest, withResult result: CBATTError.Code) {
        assert(self.state == .poweredOn, self.apiMisuseErrorMessage())
        self.core.respond(to: request.core, withResult: result)
    }

    /// Sends an updated characteristic value to one or more centrals, via a notification or
    /// indication. If _value_ exceeds `maximumUpdateValueLength`, it will be truncated to fit.
    ///
    /// - Parameters:
    ///   - value: The value to be sent via a notification/indication.
    ///   - characteristic: The characteristic whose value has changed.
    ///   - centrals: A list of `Central` objects to receive the update. Note that centrals which
    ///     have not subscribed to _characteristic_ will be ignored.
    ///     If _nil_, all centrals that are subscribed to _characteristic_ will be updated.
    /// - Returns: _YES_ if the update could be sent, or _NO_ if the underlying transmit queue is
    ///   full. If _NO_ was returned, the delegate method
    ///   `peripheralManagerIsReadyToUpdateSubscribers:` will be called once space has become
    ///   available, and the update should be re-sent if so desired.
    public func update(
        data: Data,
        for characteristic: MutableCharacteristic,
        onSubscribedCentrals centrals: [Central]?
    ) -> Bool {
        assert(self.state == .poweredOn, self.apiMisuseErrorMessage())
        let characteristic = characteristic.core
        let centrals = centrals.map { centrals in
            centrals.map { $0.core }
        }
        return self.core.updateValue(data, for: characteristic, onSubscribedCentrals: centrals)
    }

    fileprivate func apiMisuseErrorMessage() -> String {
        return "\(type(of: self)) can only accept commands while in the connected state."
    }

    internal func delegated<T, U>(to type: T.Type, closure: (T) -> (U)) -> U? {
        if let delegate = self as? T {
            return closure(delegate)
        } else if let delegatedSelf = self as? DelegatedPeripheralManagerProtocol {
            if let delegate = delegatedSelf.delegate as? T {
                return closure(delegate)
            }
        }
        return nil
    }
}

// MARK: - CBPeripheralManagerDelegate
extension PeripheralManager: CBPeripheralManagerDelegate {
    public func peripheralManagerDidUpdateState(_ manager: CBPeripheralManager) {
        self.delegated(to: PeripheralManagerStateDelegate.self) { delegate in
            delegate.peripheralManagerDidUpdateState(self)
        }
    }

    public func peripheralManager(
        _ manager: CBPeripheralManager,
        willRestoreState dictionary: [String : Any]
    ) {
        self.delegated(to: PeripheralManagerRestorationDelegate.self) { delegate in
            let state = PeripheralManagerRestoreState(dictionary: dictionary)
            delegate.peripheralManager(self, willRestoreState: state)
        }
    }

    public func peripheralManagerDidStartAdvertising(
        _ manager: CBPeripheralManager,
        error: Error?
    ) {
        self.delegated(to: PeripheralManagerAdvertisingDelegate.self) { delegate in
            delegate.peripheralManagerDidStartAdvertising(self, error: error)
        }
    }

    public func peripheralManager(
        _ manager: CBPeripheralManager,
        didAdd service: CBService,
        error: Error?
    ) {
        let service = MutableService(core: service as! CBMutableService)
        self.delegated(to: PeripheralManagerServiceAdditionDelegate.self) { delegate in
            delegate.peripheralManager(self, didAdd: service, error: error)
        }
    }

    public func peripheralManager(
        _ manager: CBPeripheralManager,
        central: CBCentral,
        didSubscribeTo characteristic: CBCharacteristic
    ) {
        let central = Central(core: central)
        let characteristic = MutableCharacteristic(core: characteristic as! CBMutableCharacteristic)
        self.delegated(to: PeripheralManagerSubscriptionDelegate.self) { delegate in
            delegate.peripheralManager(self, central: central, didSubscribeTo: characteristic)
        }
    }

    public func peripheralManager(
        _ manager: CBPeripheralManager,
        central: CBCentral,
        didUnsubscribeFrom characteristic: CBCharacteristic
    ) {
        let central = Central(core: central)
        let characteristic = MutableCharacteristic(core: characteristic as! CBMutableCharacteristic)
        self.delegated(to: PeripheralManagerSubscriptionDelegate.self) { delegate in
            delegate.peripheralManager(self, central: central, didSubscribeTo: characteristic)
        }
    }

    public func peripheralManager(
        _ manager: CBPeripheralManager,
        didReceiveRead request: CBATTRequest
    ) {
        let request = ATTRequest(core: request)
        self.delegated(to: PeripheralManagerReadingDelegate.self) { delegate in
            delegate.peripheralManager(self, didReceiveRead: request)
        }
    }

    public func peripheralManager(
        _ manager: CBPeripheralManager,
        didReceiveWrite requests: [CBATTRequest]
    ) {
        let requests = requests.map { ATTRequest(core: $0) }
        self.delegated(to: PeripheralManagerWritingDelegate.self) { delegate in
            delegate.peripheralManager(self, didReceiveWrite: requests)
        }
    }

    public func peripheralManagerIsReady(toUpdateSubscribers manager: CBPeripheralManager) {
        self.delegated(to: PeripheralManagerWritingDelegate.self) { delegate in
            delegate.peripheralManagerIsReady(toUpdateSubscribers: self)
        }
    }
}

#endif

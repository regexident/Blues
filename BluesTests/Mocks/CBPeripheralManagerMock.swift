// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import CoreBluetooth

@testable import Blues

class CorePeripheralManagerMock: CorePeripheralManagerProtocol {
    var state: CBManagerState = .poweredOn
    var delegate: CBPeripheralManagerDelegate? = nil
    var isAdvertising: Bool = false
    var desiredConnectionLatencyStore: CBPeripheralManagerConnectionLatency = .low
    var serviceStore: [CoreMutableServiceProtocol] = []
    var lastATTRequestResponse: CBATTError.Code? = nil
    
    static var _authorizationStatus = CBPeripheralManagerAuthorizationStatus.authorized
    
    static func authorizationStatus() -> CBPeripheralManagerAuthorizationStatus {
        return _authorizationStatus
    }
    
    static var `default`: CorePeripheralManagerMock {
        return CorePeripheralManagerMock(delegate: nil, queue: nil, options: nil)
    }
    
    required init(delegate: CBPeripheralManagerDelegate?, queue: DispatchQueue?, options: [String : Any]?) {}
    
    func startAdvertising(_ advertisementData: [String : Any]?) {
        self.isAdvertising = true
    }
    
    func stopAdvertising() {
        self.isAdvertising = false
    }
    
    func setDesiredConnectionLatency(_ latency: CBPeripheralManagerConnectionLatency, for central: CoreCentralProtocol) {
        desiredConnectionLatencyStore = latency
    }
    
    func add(_ service: CoreMutableServiceProtocol) {
        self.serviceStore.append(service)
    }
    
    func remove(_ service: CoreMutableServiceProtocol) {
        guard let index = serviceStore.index(where: { (knownService) -> Bool in
            knownService.uuid == service.uuid
        }) else {
            return
        }
        
        self.serviceStore.remove(at: index)
    }
    
    func removeAllServices() {
        self.serviceStore.removeAll()
    }
    
    func respond(to request: CoreATTRequestProtocol, withResult result: CBATTError.Code) {
        lastATTRequestResponse = result
    }
    
    func publishL2CAPChannel(withEncryption encryptionRequired: Bool) {}
    func unpublishL2CAPChannel(_ PSM: CBL2CAPPSM) {}
    
    func updateValue(_ value: Data, for characteristic: CBMutableCharacteristic, onSubscribedCentrals centrals: [CoreCentralProtocol]?) -> Bool {
        return false
    }
}

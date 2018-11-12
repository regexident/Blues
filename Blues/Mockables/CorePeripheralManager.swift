// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import CoreBluetooth

internal protocol CBPeripheralManagerProtocol: CBManagerProtocol {
    var delegate: CBPeripheralManagerDelegate? { get set }
    
    var isAdvertising: Bool { get }
    
    @available(iOS 7.0, *)
    static func authorizationStatus() -> CBPeripheralManagerAuthorizationStatus

    func startAdvertising(_ advertisementData: [String : Any]?)
    func stopAdvertising()
    func setDesiredConnectionLatency(_ latency: CBPeripheralManagerConnectionLatency, for central: CBCentralProtocol)
    func add(_ service: CBMutableServiceProtocol)
    func remove(_ service: CBMutableServiceProtocol)
    func removeAllServices()
    func respond(to request: CBATTRequestProtocol, withResult result: CBATTError.Code)
    func updateValue(_ value: Data, for characteristic: CBMutableCharacteristic, onSubscribedCentrals centrals: [CBCentralProtocol]?) -> Bool
    
    @available(iOS 11.0, watchOS 4.0, *)
    func publishL2CAPChannel(withEncryption encryptionRequired: Bool)
    
    @available(iOS 11.0, watchOS 4.0, *)
    func unpublishL2CAPChannel(_ PSM: CBL2CAPPSM)
}

extension CBPeripheralManager: CBPeripheralManagerProtocol {
    func add(_ service: CBMutableServiceProtocol) {
        guard let coreService = protocolCast(service, to: CBMutableService.self) else {
            return
        }
        
        self.add(coreService)
    }
    
    func remove(_ service: CBMutableServiceProtocol) {
        guard let coreService = protocolCast(service, to: CBMutableService.self) else {
            return
        }
        
        self.remove(coreService)
    }
    
    func respond(to request: CBATTRequestProtocol, withResult result: CBATTError.Code) {
        guard let coreRequest = protocolCast(request, to: CBATTRequest.self) else {
            return
        }
        
        self.respond(to: coreRequest, withResult: result)
    }
    
    func setDesiredConnectionLatency(_ latency: CBPeripheralManagerConnectionLatency, for central: CBCentralProtocol) {
        guard let coreCentral = protocolCast(central, to: CBCentral.self) else {
            return
        }
        
        self.setDesiredConnectionLatency(latency, for: coreCentral)
    }
    
    func updateValue(_ value: Data, for characteristic: CBMutableCharacteristic, onSubscribedCentrals centrals: [CBCentralProtocol]?) -> Bool {
        guard let centrals = centrals else {
            return self.updateValue(value, for: characteristic, onSubscribedCentrals: nil)
        }
        
        let coreCentrals = centrals.map { (coreCentral) -> CBCentral in
            return coreCentral as! CBCentral
        }
        
        return self.updateValue(value, for: characteristic, onSubscribedCentrals: coreCentrals)
    }
}

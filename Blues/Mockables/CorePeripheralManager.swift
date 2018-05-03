//
//  CorePeripheralManager.swift
//  Blues
//
//  Created by Michał Kałużny on 14/09/2017.
//  Copyright © 2017 NWTN Berlin. All rights reserved.
//

import CoreBluetooth

internal protocol CorePeripheralManagerProtocol: CoreManagerProtocol {
    var delegate: CBPeripheralManagerDelegate? { get set }
    
    var isAdvertising: Bool { get }
    
    @available(iOS 7.0, *)
    static func authorizationStatus() -> CBPeripheralManagerAuthorizationStatus

    func startAdvertising(_ advertisementData: [String : Any]?)
    func stopAdvertising()
    func setDesiredConnectionLatency(_ latency: CBPeripheralManagerConnectionLatency, for central: CoreCentralProtocol)
    func add(_ service: CoreMutableServiceProtocol)
    func remove(_ service: CoreMutableServiceProtocol)
    func removeAllServices()
    func respond(to request: CoreATTRequestProtocol, withResult result: CBATTError.Code)
    func updateValue(_ value: Data, for characteristic: CBMutableCharacteristic, onSubscribedCentrals centrals: [CoreCentralProtocol]?) -> Bool
    
    @available(iOS 11.0, watchOS 4.0, *)
    func publishL2CAPChannel(withEncryption encryptionRequired: Bool)
    
    @available(iOS 11.0, watchOS 4.0, *)
    func unpublishL2CAPChannel(_ PSM: CBL2CAPPSM)
}

extension CBPeripheralManager: CorePeripheralManagerProtocol {
    func add(_ service: CoreMutableServiceProtocol) {
        guard let coreService = protocolCast(service, to: CBMutableService.self) else {
            return
        }
        
        self.add(coreService)
    }
    
    func remove(_ service: CoreMutableServiceProtocol) {
        guard let coreService = protocolCast(service, to: CBMutableService.self) else {
            return
        }
        
        self.remove(coreService)
    }
    
    func respond(to request: CoreATTRequestProtocol, withResult result: CBATTError.Code) {
        guard let coreRequest = protocolCast(request, to: CBATTRequest.self) else {
            return
        }
        
        self.respond(to: coreRequest, withResult: result)
    }
    
    func setDesiredConnectionLatency(_ latency: CBPeripheralManagerConnectionLatency, for central: CoreCentralProtocol) {
        guard let coreCentral = protocolCast(central, to: CBCentral.self) else {
            return
        }
        
        self.setDesiredConnectionLatency(latency, for: coreCentral)
    }
    
    func updateValue(_ value: Data, for characteristic: CBMutableCharacteristic, onSubscribedCentrals centrals: [CoreCentralProtocol]?) -> Bool {
        guard let centrals = centrals else {
            return self.updateValue(value, for: characteristic, onSubscribedCentrals: nil)
        }
        
        let coreCentrals = centrals.map { (coreCentral) -> CBCentral in
            return coreCentral as! CBCentral
        }
        
        return self.updateValue(value, for: characteristic, onSubscribedCentrals: coreCentrals)
    }
}

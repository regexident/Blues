//
//  CorePeripheralManager.swift
//  Blues
//
//  Created by Michał Kałużny on 14/09/2017.
//  Copyright © 2017 NWTN Berlin. All rights reserved.
//

import CoreBluetooth

internal protocol CorePeripheralManagerProtocol: CoreManagerProtocol {
    weak var delegate: CBPeripheralManagerDelegate? { get set }
    
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
        guard let service = protocolCast(service, to: CBMutableService.self) else {
            return
        }
        
        self.add(service)
    }
    
    func remove(_ service: CoreMutableServiceProtocol) {
        guard let service = protocolCast(service, to: CBMutableService.self) else {
            return
        }
        
        self.remove(service)
    }
    
    func respond(to request: CoreATTRequestProtocol, withResult result: CBATTError.Code) {
        guard let request = protocolCast(request, to: CBATTRequest.self) else {
            return
        }
        
        self.respond(to: request, withResult: result)
    }
    
    func setDesiredConnectionLatency(_ latency: CBPeripheralManagerConnectionLatency, for central: CoreCentralProtocol) {
        guard let central = protocolCast(central, to: CBCentral.self) else {
            return
        }
        
        self.setDesiredConnectionLatency(latency, for: central)
    }
    
    func updateValue(_ value: Data, for characteristic: CBMutableCharacteristic, onSubscribedCentrals centrals: [CoreCentralProtocol]?) -> Bool {
        guard let coreCentrals = centrals else {
            return self.updateValue(value, for: characteristic, onSubscribedCentrals: nil)
        }
        
        let realCentrals = coreCentrals.map { (coreCentral) -> CBCentral in
            return coreCentral as! CBCentral
        }
        
        return self.updateValue(value, for: characteristic, onSubscribedCentrals: realCentrals)
    }
}


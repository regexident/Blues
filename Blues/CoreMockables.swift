//
//  CoreCentral.swift
//  Blues
//
//  Created by Michał Kałużny on 11/09/2017.
//  Copyright © 2017 NWTN Berlin. All rights reserved.
//

import Foundation
import CoreBluetooth

internal protocol CorePeerProtocol {
    @available(OSX 10.13, *)
    var identifier: UUID { get }
}


internal protocol CoreAttributeProtocol {
    var uuid: CBUUID { get }
}

internal protocol CoreCharacteristicsProtocol: class {
    var service: CBService { get }
    var properties: CBCharacteristicProperties { get }
    var value: Data? { get }
    var descriptors: [CBDescriptor]? { get }
   
    @available(OSX, introduced: 10.9, deprecated: 10.13)
    var isBroadcasted: Bool { get }
    
    var isNotifying: Bool { get }
}

internal protocol CoreCentralProtocol: CorePeerProtocol {
    var maximumUpdateValueLength: Int { get }
}

internal protocol CoreServiceProtocol: CoreAttributeProtocol {
    unowned(unsafe) var peripheral: CBPeripheral { get }
    var isPrimary: Bool { get }
    var includedServices: [CBService]? { get }
    var characteristics: [CBCharacteristic]? { get }
}

internal protocol CoreManagerProtocol {
    var state: CBManagerState { get }
}

internal protocol CorePeripheralManagerProtocol: CoreManagerProtocol {
    weak var delegate: CBPeripheralManagerDelegate? { get set }
    
    var isAdvertising: Bool { get }
    
    @available(iOS 7.0, *)
    static func authorizationStatus() -> CBPeripheralManagerAuthorizationStatus
    
    init(delegate: CBPeripheralManagerDelegate?, queue: DispatchQueue?, options: [String : Any]?)
    
    func startAdvertising(_ advertisementData: [String : Any]?)
    func stopAdvertising()
    func setDesiredConnectionLatency(_ latency: CBPeripheralManagerConnectionLatency, for central: CoreCentralProtocol)
    func add(_ service: CBMutableService)
    func remove(_ service: CBMutableService)
    func removeAllServices()
    func respond(to request: CoreATTRequestProtocol, withResult result: CBATTError.Code)
    func updateValue(_ value: Data, for characteristic: CBMutableCharacteristic, onSubscribedCentrals centrals: [CoreCentralProtocol]?) -> Bool

    @available(iOS 11.0, *)
    func publishL2CAPChannel(withEncryption encryptionRequired: Bool)
    
    @available(iOS 11.0, *)
    func unpublishL2CAPChannel(_ PSM: CBL2CAPPSM)
}

protocol CoreATTRequestProtocol {
    var central: CBCentral { get }
    var characteristic: CBCharacteristic { get }
    var offset: Int { get }
    var value: Data? { get }
}

extension CBPeer: CorePeerProtocol {}
extension CBAttribute: CoreAttributeProtocol {}
extension CBCentral: CoreCentralProtocol {}
extension CBService: CoreServiceProtocol {}
extension CBManager: CoreManagerProtocol {}
extension CBCharacteristic: CoreCharacteristicsProtocol {}
extension CBATTRequest: CoreATTRequestProtocol {}

extension CBPeripheralManager: CorePeripheralManagerProtocol {
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

internal func protocolCast<T, U>(_ generic: T, to: U.Type) -> U? {
    guard let concrete = generic as? U else {
        Log.shared.error("Failed to cast generic value of type \(T.self) to concrete type \(U.self)")
        return nil
    }
    return concrete
}

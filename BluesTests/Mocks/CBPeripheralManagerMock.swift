//
//  CBPeripheralManagerMock.swift
//  BluesTests
//
//  Created by Michał Kałużny on 13/09/2017.
//  Copyright © 2017 NWTN Berlin. All rights reserved.
//

import Foundation
import CoreBluetooth

@testable import Blues

class CorePeripheralManagerMock: CorePeripheralManagerProtocol {
    var state: CBManagerState = .poweredOn
    var delegate: CBPeripheralManagerDelegate? = nil
    var isAdvertising: Bool = false
    var desiredConnectionLatencyStore: CBPeripheralManagerConnectionLatency = .low
    var serviceStore: Set<CBMutableService> = .init()
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
    
    func add(_ service: CBMutableService) {
        self.serviceStore.insert(service)
    }
    
    func remove(_ service: CBMutableService) {
        self.serviceStore.remove(service)
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

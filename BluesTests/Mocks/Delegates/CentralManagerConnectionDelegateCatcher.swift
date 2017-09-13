//
//  CentralManagerConnectionDelegateCatcher.swift
//  BluesTests
//
//  Created by Michał Kałużny on 13/09/2017.
//  Copyright © 2017 NWTN Berlin. All rights reserved.
//

@testable import Blues

class CentralManagerConnectionDelegateCatcher: CentralManagerConnectionDelegate {
    typealias NonFailableCallback = (Peripheral, CentralManager) -> Void
    typealias FailableCallback = (Peripheral, Swift.Error?, CentralManager) -> Void

    var willConnectClosure: NonFailableCallback? = nil
    var didConnectClosure: NonFailableCallback? = nil
    var willDisconnectClosure: NonFailableCallback? = nil
    var didDisconnectClosure: FailableCallback? = nil
    var didFailToConnectClosure: FailableCallback? = nil

    func willConnect(to peripheral: Peripheral, on manager: CentralManager) {
        willConnectClosure?(peripheral, manager)
    }
    
    func didConnect(to peripheral: Peripheral, on manager: CentralManager) {
        didConnectClosure?(peripheral, manager)
    }
    
    func willDisconnect(from peripheral: Peripheral, on manager: CentralManager) {
        willDisconnectClosure?(peripheral, manager)
    }
    
    func didDisconnect(from peripheral: Peripheral, error: Swift.Error?, on manager: CentralManager) {
        didDisconnectClosure?(peripheral, error, manager)
    }
    
    func didFailToConnect(to peripheral: Peripheral, error: Swift.Error?, on manager: CentralManager) {
        didFailToConnectClosure?(peripheral, error, manager)
    }
}

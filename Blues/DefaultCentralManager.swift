//
//  DefaultCentralManager.swift
//  Blues
//
//  Created by Vincent Esche on 7/5/17.
//  Copyright © 2017 NWTN Berlin. All rights reserved.
//

import Foundation
import CoreBluetooth

open class DefaultCentralManager:
    CentralManager, DelegatedCentralManagerProtocol, DataSourcedCentralManagerProtocol
{
    public static let `default`: DefaultCentralManager = .init()

    public weak var delegate: CentralManagerDelegate?
    public weak var dataSource: CentralManagerDataSource?

    public required convenience init(
        options: CentralManagerOptions? = nil,
        queue: DispatchQueue = .global()
    ) {
        let core = CBCentralManager(delegate: nil, queue: queue, options: options?.dictionary)
        self.init(core: core)
    }
}

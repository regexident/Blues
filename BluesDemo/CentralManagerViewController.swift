//
//  CentralManagerViewController.swift
//  BluesDemo
//
//  Created by Vincent Esche on 28/10/2016.
//  Copyright © 2016 NWTN Berlin. All rights reserved.
//

import UIKit

import Blues

class CentralManagerViewController: UITableViewController {

    enum Section: Int {
        case peripherals

        var title: String {
            switch self {
            case .peripherals:
                return "Peripherals nearby"
            }
        }
    }

    let queue: DispatchQueue = .init(label: "serial")

    var peripheralViewController: PeripheralViewController?

    let centralManager: DefaultCentralManager = .init()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.clearsSelectionOnViewWillAppear = self.splitViewController!.isCollapsed

        self.centralManager.delegate = self
        self.centralManager.dataSource = self

        if self.centralManager.state == .poweredOn {
            
            self.centralManager.startScanningForPeripherals(timeout: 3.0)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.tableView.reloadData()
    }

    var sortedPeripherals: [Peripheral] {
        return self.peripherals.sorted {
            ($0.name ?? $0.identifier.string) < ($1.name ?? $1.identifier.string)
        }
    }
    var peripherals: [Peripheral] = []

    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showPeripheral" {
            guard let indexPath = self.tableView.indexPathForSelectedRow else {
                return
            }
            let peripherals = self.sortedPeripherals
            let peripheral = peripherals[indexPath.row]
            let navigationController = segue.destination as! UINavigationController
            let controller = navigationController.topViewController as! PeripheralViewController
            controller.peripheral = peripheral as? DefaultPeripheral
            controller.delegate = self
            self.peripheralViewController = controller
            self.centralManager.connect(peripheral: peripheral)
            controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem
            controller.navigationItem.leftItemsSupplementBackButton = true
        }
    }

    @IBAction func scanForDevices(_ sender: UIBarButtonItem) {
        self.centralManager.startScanningForPeripherals(timeout: 3.0)
    }
}

// MARK: - UITableViewDataSource
extension CentralManagerViewController {

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return Section(rawValue: section)!.title
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .peripherals:
            return self.sortedPeripherals.count
        }
    }

    func cellForPeripheral(at indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PeripheralCell", for: indexPath)

        let peripherals = self.sortedPeripherals
        if peripherals.count > indexPath.row {
            let peripheral = peripherals[indexPath.row]

            cell.textLabel!.text = peripheral.name ?? "Unnamed"
            cell.detailTextLabel!.text = peripheral.identifier.string
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Section(rawValue: indexPath.section)! {
        case .peripherals:
            return self.cellForPeripheral(at: indexPath)
        }
    }
}

extension CentralManagerViewController: PeripheralViewControllerDelegate {
    func connect(peripheral: Peripheral) {
        self.centralManager.connect(peripheral: peripheral)
    }

    func disconnect(peripheral: Peripheral) {
        self.centralManager.disconnect(peripheral: peripheral)
    }
}

// MARK: - CentralManagerStateDelegate
extension CentralManagerViewController: CentralManagerStateDelegate {
    func didUpdateState(of manager: CentralManager) {
        self.queue.async {
            
            self.centralManager.startScanningForPeripherals(timeout: 3.0)
        }
    }
}

// MARK: - CentralManagerDiscoveryDelegate
extension CentralManagerViewController: CentralManagerDiscoveryDelegate {
    func didStartScanningForPeripherals(with manager: CentralManager) {
        
        DispatchQueue.main.async {
            if let buttonItem = self.navigationItem.rightBarButtonItem {
                buttonItem.isEnabled = false
                buttonItem.title = "Scanning…"
            }
        }
    }

    func didStopScanningForPeripherals(with manager: CentralManager) {
        
        DispatchQueue.main.async {
            if let buttonItem = self.navigationItem.rightBarButtonItem {
                buttonItem.isEnabled = true
                buttonItem.title = "Scan"
            }
        }
    }

    func didDiscover(peripheral: Peripheral, rssi: Int, with manager: CentralManager) {
        self.queue.async {
            
            self.peripherals.append(peripheral)
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
}

// MARK: - CentralManagerRetrievalDelegate
extension CentralManagerViewController: CentralManagerRetrievalDelegate {
    func didRetrieve(peripherals: [Peripheral], from manager: CentralManager) {

    }

    func didRetrieve(connectedPeripherals: [Peripheral], from manager: CentralManager) {

    }
}

// MARK: - CentralManagerRestorationDelegate
extension CentralManagerViewController: CentralManagerRestorationDelegate {
    func willRestore(state: CentralManagerRestoreState, of manager: CentralManager) {

    }

    func didRestore(peripheral: Peripheral, with manager: CentralManager) {

    }
}

// MARK: - CentralManagerConnectionDelegate
extension CentralManagerViewController: CentralManagerConnectionDelegate {
    func willConnect(to peripheral: Peripheral, on manager: CentralManager) {
        self.queue.async {
            
            self.peripheralViewController?.willConnect()
        }
    }

    func didConnect(to peripheral: Peripheral, on manager: CentralManager) {
        self.queue.async {
            
            self.peripheralViewController?.didConnect()
        }
    }

    func willDisconnect(from peripheral: Peripheral, on manager: CentralManager) {
        self.queue.async {
            
            self.peripheralViewController?.willDisconnect()
        }
    }

    func didDisconnect(from peripheral: Peripheral, error: Swift.Error?, on manager: CentralManager) {
        self.queue.async {
            
            self.peripheralViewController?.didDisconnect(error: error)
        }
    }

    func didFailToConnect(to peripheral: Peripheral, error: Swift.Error?, on manager: CentralManager) {
        
    }
}

// MARK: - CentralManagerDataSource
extension CentralManagerViewController: CentralManagerDataSource {
    func peripheral(
        with identifier: Identifier,
        advertisement: Advertisement?,
        for manager: CentralManager
    ) -> Peripheral {
        return DefaultPeripheral(identifier: identifier, centralManager: self.centralManager)
    }
}

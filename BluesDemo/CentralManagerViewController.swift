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

    var peripheralViewController: PeripheralViewController?
    var centralManager: CentralManager!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.clearsSelectionOnViewWillAppear = self.splitViewController!.isCollapsed

        self.centralManager = CentralManager(delegate: self, dataSource: self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.tableView.reloadData()
    }

    var cachedPeripherals: [Peripheral] = []

    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showPeripheral" {
            guard let indexPath = self.tableView.indexPathForSelectedRow else {
                return
            }
            let peripherals = self.cachedPeripherals
            let peripheral = peripherals[indexPath.row]

            let controller = (segue.destination as! UINavigationController).topViewController as! PeripheralViewController
            controller.peripheral = peripheral
            controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem
            controller.navigationItem.leftItemsSupplementBackButton = true
            self.peripheralViewController = controller
        }
    }
}

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
            return self.cachedPeripherals.count
        }
    }

    func cellForPeripheral(at index: Int) -> UITableViewCell {
        let indexPath = IndexPath(row: index, section: Section.peripherals.rawValue)
        let cell = tableView.dequeueReusableCell(withIdentifier: "PeripheralCell", for: indexPath)

        let peripherals = self.cachedPeripherals
        let peripheral = peripherals[indexPath.row]

        cell.textLabel!.text = peripheral.name ?? "Unnamed"
        cell.detailTextLabel!.text = peripheral.uuid.string

        return cell
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Section(rawValue: indexPath.section)! {
        case .peripherals:
            return self.cellForPeripheral(at: indexPath.row)
        }
    }
}

extension CentralManagerViewController: CentralManagerDataSource {

    func peripheralClass(forAdvertisement advertisement: Advertisement, onManager manager: CentralManager) -> Peripheral.Type {
        return DefaultPeripheral.self
    }
}

extension CentralManagerViewController: CentralManagerDelegate {

    @available(iOSApplicationExtension 10.0, *)
    func didUpdate(state: CentralManagerState, ofManager manager: CentralManager) {
        if state == .poweredOn {
            self.centralManager.startScanningForPeripherals(advertisingWithServices: nil)
        }
    }

    func didDiscover(peripheral: Peripheral, advertisement: Advertisement, withManager manager: CentralManager) {
        DispatchQueue.main.async {
            let section = Section.peripherals.rawValue
            let row = self.cachedPeripherals.count
            self.cachedPeripherals.append(peripheral)
            let indexPath = IndexPath(row: row, section: section)
            self.tableView.beginUpdates()
            self.tableView.insertRows(at: [indexPath], with: .automatic)
            self.tableView.endUpdates()
        }
    }

    func didRetrievePeripherals(peripherals: [Peripheral], fromManager manager: CentralManager) {}

    func didRetrieveConnectedPeripherals(peripherals: [Peripheral], fromManager manager: CentralManager) {}
}

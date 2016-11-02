//
//  PeripheralViewController.swift
//  BluesDemo
//
//  Created by Vincent Esche on 28/10/2016.
//  Copyright © 2016 NWTN Berlin. All rights reserved.
//

import UIKit
import Blues

class PeripheralViewController: UITableViewController {

    var characteristicViewController: CharacteristicViewController?

    weak var previousPeripheralDelegate: PeripheralDelegate?
    weak var peripheral: Peripheral? {
        willSet {
            if self.peripheral !== newValue {
                guard let peripheral = self.peripheral as? DelegatedPeripheral else {
                    return
                }
                peripheral.delegate = self.previousPeripheralDelegate
                let _ = peripheral.disconnect()
            }
        }
        didSet {
            guard let peripheral = self.peripheral as? DelegatedPeripheral else {
                self.previousPeripheralDelegate = nil
                return
            }
            self.previousPeripheralDelegate = peripheral.delegate
            peripheral.delegate = self
            let _ = peripheral.connect()
        }
    }

    var cachedServices: [Service] = []
    var cachedCharacteristicsByService: [Identifier: [Characteristic]] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()

        self.clearsSelectionOnViewWillAppear = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        guard let peripheral = self.peripheral else {
            return
        }
        self.cachedServices = Array(peripheral.services.values)
        for service in self.cachedServices {
            let cachedCharacteristics = Array(service.characteristics.values)
            self.cachedCharacteristicsByService[service.uuid] = cachedCharacteristics
            for characteristic in cachedCharacteristics {
                guard let characteristic = characteristic as? DelegatedCharacteristic else {
                    continue
                }
                characteristic.delegate = self
                let _ = characteristic.read()
                let _ = characteristic.set(notifyValue: true)
            }
        }
        DispatchQueue.main.async {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(
                title: peripheral.state == .connected ? "Disconnect" : "Connect",
                style: .plain,
                target: self,
                action: #selector(self.toggleConnection(_:))
            )
            self.title = self.title(for: peripheral)
            self.tableView.reloadData()
        }
    }

    func toggleConnection(_ sender: UIBarButtonItem?) {
        guard let peripheral = self.peripheral else {
            return
        }
        if peripheral.state == .connected {
            let _ = peripheral.disconnect()
        } else {
            let _ = peripheral.connect()
        }
    }

    func title(for peripheral: Peripheral) -> String {
        return peripheral.name ?? "UUID: \(peripheral.uuid.string)"
    }

    func title(for characteristic: Characteristic) -> String {
        return characteristic.name ?? "UUID: \(characteristic.uuid.string)"
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showCharacteristic" {
            guard let indexPath = self.tableView.indexPathForSelectedRow else {
                return
            }
            let service = self.cachedServices[indexPath.section]
            let characteristics = self.cachedCharacteristicsByService[service.uuid]!
            let characteristic = characteristics[indexPath.row]

            let controller = segue.destination as! CharacteristicViewController
            controller.characteristic = characteristic
            controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem
            controller.navigationItem.leftItemsSupplementBackButton = true
            self.characteristicViewController = controller
        }
    }
}

extension PeripheralViewController {

    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.cachedServices.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let service = self.cachedServices[section]
        return ServiceNames.nameOf(service: service.uuid) ?? service.name ?? service.uuid.string
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let service = self.cachedServices[section]
        let characteristics = self.cachedCharacteristicsByService[service.uuid] ?? []
        return characteristics.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CharacteristicCell", for: indexPath)

        let service = self.cachedServices[indexPath.section]
        let characteristics = self.cachedCharacteristicsByService[service.uuid]!
        let characteristic = characteristics[indexPath.row]

        cell.textLabel!.text = self.title(for: characteristic)

        if case let .ok(data) = characteristic.data {
            if let hexString = data?.hexString {
                cell.detailTextLabel!.text = "Hex: \(hexString)"
            } else {
                cell.detailTextLabel!.text = "No Value"
            }
        }

        return cell
    }
}

extension PeripheralViewController: PeripheralDelegate {

    public func willRestore(peripheral: Peripheral) {
    }

    public func didRestore(peripheral: Peripheral) {
    }

    public func willConnect(peripheral: Peripheral) {
    }

    public func didConnect(peripheral: Peripheral) {
        if case let .err(error) = peripheral.discover(services: nil) {
            print("Error: \(error)")
        }
        DispatchQueue.main.async {
            self.navigationItem.rightBarButtonItem?.title = "Disconnect"
        }
    }

    public func didDisconnect(peripheral: Peripheral, error: Swift.Error?) {
        DispatchQueue.main.async {
            self.navigationItem.rightBarButtonItem?.title = "Connect"
        }
    }

    public func didFailToConnect(peripheral: Peripheral, error: Swift.Error?) {
    }

    func didUpdate(name: String?, ofPeripheral peripheral: Peripheral) {
        self.title = self.title(for: peripheral)
    }

    func didModify(services: [Service], ofPeripheral peripheral: Peripheral) {
    }

    func didRead(rssi: Result<Int, Error>, ofPeripheral peripheral: Peripheral) {
    }

    func didDiscover(services: Result<[Service], Error>, forPeripheral peripheral: Peripheral) {
        guard case let .ok(services) = services else {
            return
        }
        self.cachedServices = services
        for service in services {
            let _ = service.discover(characteristics: nil)
            if let service = service as? DelegatedService {
                service.delegate = self
            }
        }
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
}

extension PeripheralViewController: ServiceDelegate {

    func didDiscover(includedServices: Result<[Service], Error>, forService service: Service) {
    }

    func didDiscover(characteristics: Result<[Characteristic], Error>, forService service: Service) {
        guard case let .ok(characteristics) = characteristics else {
            return
        }
        DispatchQueue.main.async {
            self.cachedCharacteristicsByService[service.uuid] = characteristics
            for characteristic in characteristics {
                let _ = characteristic.discoverDescriptors()
                if let characteristic = characteristic as? DelegatedCharacteristic {
                    let _ = characteristic.read()
                    let _ = characteristic.set(notifyValue: true)
                    characteristic.delegate = self
                }
            }
            let section = self.cachedServices.index(where: { $0.uuid == service.uuid })!
            let rowCount = self.cachedCharacteristicsByService[service.uuid]!.count
            let indexPaths = (0 ..< rowCount).map { IndexPath(row: $0, section: section) }
            self.tableView.beginUpdates()
            self.tableView.insertRows(at: indexPaths, with: .automatic)
            self.tableView.endUpdates()
        }
    }
}

extension PeripheralViewController: CharacteristicDelegate {

    func didUpdate(data: Result<Data, Error>, forCharacteristic characteristic: Characteristic) {
        DispatchQueue.main.async {
            let service = characteristic.service!
            let cachedCharacteristics = self.cachedCharacteristicsByService[service.uuid]!
            let section = self.cachedServices.index(where: { $0.uuid == service.uuid })!
            let row = cachedCharacteristics.index(where: { $0.uuid == characteristic.uuid })!
            let indexPath = IndexPath(row: row, section: section)
            self.tableView.beginUpdates()
            self.tableView.reloadRows(at: [indexPath], with: .none)
            self.tableView.endUpdates()
        }
    }

    func didWrite(data: Result<Data, Error>, forCharacteristic characteristic: Characteristic) {
        DispatchQueue.main.async {
            let service = characteristic.service!
            let cachedCharacteristics = self.cachedCharacteristicsByService[service.uuid]!
            let section = self.cachedServices.index(where: { $0.uuid == service.uuid })!
            let row = cachedCharacteristics.index(where: { $0.uuid == characteristic.uuid })!
            let indexPath = IndexPath(row: row, section: section)
            self.tableView.beginUpdates()
            self.tableView.reloadRows(at: [indexPath], with: .none)
            self.tableView.endUpdates()
        }
    }

    func didUpdate(notificationState isNotifying: Result<Bool, Error>, forCharacteristic characteristic: Characteristic) {
    }

    func didDiscover(descriptors: Result<[Descriptor], Error>, forCharacteristic characteristic: Characteristic) {
    }
}

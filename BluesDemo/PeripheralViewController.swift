//
//  PeripheralViewController.swift
//  BluesDemo
//
//  Created by Vincent Esche on 28/10/2016.
//  Copyright © 2016 NWTN Berlin. All rights reserved.
//

import UIKit
import Blues

import Result

class PeripheralViewController: UITableViewController {

    var characteristicViewController: CharacteristicViewController?

    weak var previousPeripheralDelegate: PeripheralDelegate?
    weak var peripheral: Peripheral? {
        willSet {
            if self.peripheral !== newValue {
                guard let peripheral = self.peripheral as? DefaultPeripheral else {
                    return
                }
                peripheral.delegate = self.previousPeripheralDelegate
                let _ = peripheral.disconnect()
            }
        }
        didSet {
            self.sortedServices = []
            guard let peripheral = self.peripheral as? DefaultPeripheral else {
                self.previousPeripheralDelegate = nil
                let _ = oldValue?.disconnect()
                return
            }
            self.previousPeripheralDelegate = peripheral.delegate
            peripheral.delegate = self
            switch peripheral.connect() {
            case .ok(_): break
            case let .err(error): print(error)
            }
        }
    }

    let queue: DispatchQueue = .init(label: "serial")

    lazy var sortedServices: [Service] = {
        guard let services = self.peripheral?.services?.values else {
            return []
        }
        return Array(services)
    }()

    var sortedCharacteristicsByService: [Identifier: [Characteristic]] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let peripheral = self.peripheral else {
            return
        }
        self.title = self.title(for: peripheral)
        self.clearsSelectionOnViewWillAppear = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.tableView.reloadData()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        guard let peripheral = self.peripheral as? DefaultPeripheral else {
            return
        }

        if peripheral.delegate === self {
            peripheral.delegate = self.previousPeripheralDelegate
        }
    }

    override func willMove(toParentViewController parent: UIViewController?) {
        super.willMove(toParentViewController: parent)

        // Caution: Due to http://www.openradar.me/18002763 this methods is actually never called.
        // Look into Main.storyboard for more info.

        // The back button was pressed or interactive gesture used:
        if parent == nil {
            self.peripheral = nil
        }
    }

    func title(for peripheral: Peripheral) -> String {
        return peripheral.name ?? "UUID: \(peripheral.identifier.string)"
    }

    func title(for characteristic: Characteristic) -> String {
        return characteristic.name ?? "UUID: \(characteristic.identifier.string)"
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showCharacteristic" {
            guard let indexPath = self.tableView.indexPathForSelectedRow else {
                return
            }
            let service = self.sortedServices[indexPath.section]
            let characteristics = self.sortedCharacteristicsByService[service.identifier]!
            let characteristic = characteristics[indexPath.row]

            let controller = segue.destination as! CharacteristicViewController
            controller.characteristic = characteristic
            controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem
            controller.navigationItem.leftItemsSupplementBackButton = true
            self.characteristicViewController = controller
        }
    }

    func humanReadableValue<C>(for characteristic: C) -> String
        where C: Characteristic
    {
        return characteristic.data.map { data in
            if let hexString = data?.hexString {
                return "Hex: \(hexString)"
            } else {
                return "No Value"
            }
        }.asOk.unwrapOr("No data")
    }

    func humanReadableValue<C>(for characteristic: C) -> String
        where C: Characteristic,
              C: TypedCharacteristic,
              C.Transformer.Value: CustomStringConvertible
    {
        return characteristic.value.map { value in
            value!.description
        }.asOk.unwrapOr("No value")
    }
}

extension PeripheralViewController {

    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.sortedServices.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let service = self.sortedServices[section]
        return ServiceNames.nameOf(service: service.identifier) ?? service.name
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let service = self.sortedServices[section]
        let characteristics = self.sortedCharacteristicsByService[service.identifier] ?? []
        return characteristics.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CharacteristicCell", for: indexPath)

        let service = self.sortedServices[indexPath.section]
        let characteristics = self.sortedCharacteristicsByService[service.identifier]!
        let characteristic = characteristics[indexPath.row]

        if case let .ok(data) = characteristic.data {
            let value = self.humanReadableValue(for: characteristic)
            print(value)
            if let hexString = data?.hexString {
                cell.textLabel!.text = "Hex: \(hexString)"
            } else {
                cell.textLabel!.text = "No Value"
            }
        }
        cell.detailTextLabel!.text = self.title(for: characteristic)

        return cell
    }
}

extension PeripheralViewController: PeripheralDelegate {

    public func willRestore(peripheral: Peripheral) {
    }

    public func didRestore(peripheral: Peripheral) {
    }

    public func willConnect(to peripheral: Peripheral) {
    }

    public func didConnect(to peripheral: Peripheral) {
        if case let .err(error) = peripheral.discover(services: nil) {
            print("Error: \(error)")
        }
    }

    public func willDisconnect(from peripheral: Peripheral) {
    }

    public func didDisconnect(from peripheral: Peripheral, error: Swift.Error?) {
    }

    public func didFailToConnect(to peripheral: Peripheral, error: Swift.Error?) {
        print("Error: \(String(describing: error))")
    }

    func didUpdate(name: String?, of peripheral: Peripheral) {
        self.title = self.title(for: peripheral)
    }

    func didModify(services: [Service], of peripheral: Peripheral) {
    }

    func didRead(rssi: Result<Int, Error>, of peripheral: Peripheral) {
    }

    func didDiscover(services: Result<[Service], Error>, for peripheral: Peripheral) {
        guard case let .ok(services) = services else {
            return
        }
        self.queue.async {
            self.sortedServices = services.sorted {
                ($0.name ?? "") < ($1.name ?? "")
            }
            for service in services {
                let _ = service.discover(characteristics: nil)
                if let service = service as? DefaultService {
                    service.delegate = self
                }
            }
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
}

extension PeripheralViewController: ServiceDelegate {

    func didDiscover(includedServices: Result<[Service], Error>, for service: Service) {
    }

    func didDiscover(characteristics: Result<[Characteristic], Error>, for service: Service) {
        guard case let .ok(characteristics) = characteristics else {
            return
        }
        self.queue.async {
            self.sortedCharacteristicsByService[service.identifier] = characteristics
            for characteristic in characteristics {
                let _ = characteristic.discoverDescriptors()
                if let characteristic = characteristic as? DefaultCharacteristic {
                    let _ = characteristic.read()
                    let _ = characteristic.set(notifyValue: true)
                    characteristic.delegate = self
                }
                let _ = characteristic.set(notifyValue: true)
            }
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
}

extension PeripheralViewController: ReadableCharacteristicDelegate {

    func didUpdate(data: Result<Data, Error>, for characteristic: Characteristic) {
        self.queue.async {
            let service = characteristic.service!
            let sortedCharacteristics = self.sortedCharacteristicsByService[service.identifier]!
            let section = self.sortedServices.index(where: { $0.identifier == service.identifier })!
            let row = sortedCharacteristics.index(where: { $0.identifier == characteristic.identifier })!
            let indexPath = IndexPath(row: row, section: section)
            DispatchQueue.main.async {
                self.tableView.beginUpdates()
                self.tableView.reloadRows(at: [indexPath], with: .none)
                self.tableView.endUpdates()
            }
        }
    }
}

extension PeripheralViewController: WritableCharacteristicDelegate {

    func didWrite(data: Result<Data, Error>, for characteristic: Characteristic) {
        self.queue.async {
            let service = characteristic.service!
            let sortedCharacteristics = self.sortedCharacteristicsByService[service.identifier]!
            let section = self.sortedServices.index(where: { $0.identifier == service.identifier })!
            let row = sortedCharacteristics.index(where: { $0.identifier == characteristic.identifier })!
            let indexPath = IndexPath(row: row, section: section)
            DispatchQueue.main.async {
                self.tableView.beginUpdates()
                self.tableView.reloadRows(at: [indexPath], with: .none)
                self.tableView.endUpdates()
            }
        }
    }
}

extension PeripheralViewController: NotifyableCharacteristicDelegate {

    func didUpdate(notificationState isNotifying: Result<Bool, Error>, for characteristic: Characteristic) {
    }
}

extension PeripheralViewController: DescribableCharacteristicDelegate {

    func didDiscover(descriptors: Result<[Descriptor], Error>, for characteristic: Characteristic) {
    }
}

//
//  CharacteristicViewController.swift
//  Blues
//
//  Created by Vincent Esche on 30/10/2016.
//  Copyright © 2016 NWTN Berlin. All rights reserved.
//

import UIKit
import Blues

import Result

class CharacteristicViewController: UITableViewController {

    enum Section: Int {
        case values
        case descriptors
        case properties

        var title: String {
            switch self {
            case .values:
                return "Values"
            case .descriptors:
                return "Descriptors"
            case .properties:
                return "Properties"
            }
        }
    }

    weak var previousCharacteristicDelegate: CharacteristicDelegate?
    weak var characteristic: Characteristic? {
        willSet {
            if self.characteristic !== newValue {
                if let characteristic = self.characteristic as? DelegatedCharacteristic {
                    characteristic.delegate = self.previousCharacteristicDelegate
                }
            }
        }
        didSet {
            self.sortedDescriptors = []
            if let characteristic = self.characteristic as? DelegatedCharacteristic {
                self.previousCharacteristicDelegate = characteristic.delegate
                characteristic.delegate = self
            } else {
                self.previousCharacteristicDelegate = nil
            }
        }
    }

    let queue: DispatchQueue = .init(label: "serial")
    var sortedDescriptors: [Descriptor] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        self.clearsSelectionOnViewWillAppear = true

        self.update()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.clearsSelectionOnViewWillAppear = true

        guard let characteristic = self.characteristic else {
            return
        }
        let _ = characteristic.set(notifyValue: true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        guard let characteristic = self.characteristic else {
            return
        }
        let _ = characteristic.set(notifyValue: true)
    }

    override func willMove(toParentViewController parent: UIViewController?) {
        super.willMove(toParentViewController: parent)

        // The back button was pressed or interactive gesture used:
        if parent == nil {
            self.characteristic = nil
        }
    }

    func update() {
        if let characteristic = self.characteristic {
            DispatchQueue.main.async {
                self.title = characteristic.name ?? "UUID: \(characteristic.uuid.string)"
                self.tableView.reloadData()
            }
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
    }

    func humanReadableProperties(of characteristic: Characteristic) -> [String] {
        guard case let .ok(properties) = characteristic.properties else {
            return []
        }
        let propertyTitles: [(CharacteristicProperties, String)] = [
            (.broadcast, "Broadcast"),
            (.notify, "Notify"),
            (.indicate, "Indicate"),
            (.read, "Read"),
            (.writeWithoutResponse, "Write without Response"),
            (.write, "Write"),
            (.authenticatedSignedWrites, "Authenticated Signed Writes"),
            (.notifyEncryptionRequired, "Notify Encryption Required"),
            (.indicateEncryptionRequired, "Indicate Encryption Required"),
            (.extendedProperties, "Extended Properties"),
        ]
        return propertyTitles.flatMap {
            properties.contains($0.0) ? $0.1 : nil
        }
    }

    func numberOfRowsInSection(_ sectionIndex: Int) -> Int {
        guard let characteristic = self.characteristic else {
            return 0
        }

        switch Section(rawValue: sectionIndex)! {
        case .values:
            return 1
        case .descriptors:
            return self.numberOfDescriptors(of: characteristic)
        case .properties:
            return self.numberOfProperties(of: characteristic)
        }
    }

    func titleFor(section: Int) -> String {
        return Section(rawValue: section)!.title
    }

    func numberOfDescriptors(of characteristic: Characteristic) -> Int {
        return self.sortedDescriptors.count
    }

    func numberOfProperties(of characteristic: Characteristic) -> Int {
        return self.humanReadableProperties(of: characteristic).count
    }

    func cellForValue(at index: Int) -> UITableViewCell {
        let indexPath = IndexPath(row: index, section: Section.values.rawValue)
        let cell = tableView.dequeueReusableCell(withIdentifier: "ValueCell", for: indexPath)

        guard let characteristic = self.characteristic else {
            return cell
        }
        guard case let .ok(data) = characteristic.data else {
            return cell
        }

        cell.textLabel!.text = data?.hexString ?? "No Value"
        cell.detailTextLabel!.text = "Hexadecimal"

        return cell
    }

    func cellForDescriptor(at index: Int) -> UITableViewCell {
        let indexPath = IndexPath(row: index, section: Section.descriptors.rawValue)
        let cell = tableView.dequeueReusableCell(withIdentifier: "DescriptorCell", for: indexPath)

        let descriptor = self.sortedDescriptors[index]
        guard case let .ok(any) = descriptor.any else {
            return cell
        }

        switch any {
        case let data as Data:
            cell.textLabel!.text = data.hexString
        case let string as String:
            cell.textLabel!.text = string
        default:
            cell.textLabel!.text = any.debugDescription
        }
        cell.detailTextLabel!.text = descriptor.name ?? "UUID: \(descriptor.uuid.string)"

        return cell
    }

    func cellForProperty(at index: Int) -> UITableViewCell {
        let indexPath = IndexPath(row: index, section: Section.properties.rawValue)
        let cell = tableView.dequeueReusableCell(withIdentifier: "PropertyCell", for: indexPath)

        guard let characteristic = self.characteristic else {
            return cell
        }

        let sortedProperties = self.humanReadableProperties(of: characteristic).sorted()
        let property = sortedProperties[indexPath.row]

        cell.textLabel!.text = property

        return cell
    }
}

extension CharacteristicViewController {

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.titleFor(section: section)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.numberOfRowsInSection(section)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Section(rawValue: indexPath.section)! {
        case .values:
            return self.cellForValue(at: indexPath.row)
        case .descriptors:
            return self.cellForDescriptor(at: indexPath.row)
        case .properties:
            return self.cellForProperty(at: indexPath.row)
        }
    }

    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return false
    }
}

extension CharacteristicViewController: CharacteristicDelegate {

    func didUpdate(data: Result<Data, Error>, forCharacteristic characteristic: Characteristic) {
        self.queue.async {
            let indexPath = IndexPath(row: 0, section: Section.values.rawValue)
            DispatchQueue.main.async {
                self.tableView.beginUpdates()
                self.tableView.reloadRows(at: [indexPath], with: .none)
                self.tableView.endUpdates()
            }
        }
    }

    func didWrite(data: Result<Data, Error>, forCharacteristic characteristic: Characteristic) {
        self.queue.async {
            let indexPath = IndexPath(row: 0, section: Section.values.rawValue)
            DispatchQueue.main.async {
                self.tableView.beginUpdates()
                self.tableView.reloadRows(at: [indexPath], with: .none)
                self.tableView.endUpdates()
            }
        }
    }

    func didUpdate(notificationState isNotifying: Result<Bool, Error>, forCharacteristic characteristic: Characteristic) {
    }

    func didDiscover(descriptors: Result<[Descriptor], Error>, forCharacteristic characteristic: Characteristic) {
        guard case let .ok(descriptors) = descriptors else {
            return
        }
        self.queue.async {
            self.sortedDescriptors = descriptors.sorted {
                ($0.name ?? $0.uuid.string) < ($1.name ?? $1.uuid.string)
            }
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
}

extension CharacteristicViewController: DescriptorDelegate {

    func didUpdate(any: Result<Any, Error>, forDescriptor descriptor: Descriptor) {
        self.queue.async {
            let section = Section.descriptors.rawValue
            let row = self.sortedDescriptors.index(where: { $0.uuid == descriptor.uuid })!
            let indexPath = IndexPath(row: row, section: section)
            DispatchQueue.main.async {
                self.tableView.beginUpdates()
                self.tableView.reloadRows(at: [indexPath], with: .none)
                self.tableView.endUpdates()
            }
        }
    }

    func didWrite(any: Result<Any, Error>, forDescriptor descriptor: Descriptor) {
        self.queue.async {
            let section = Section.descriptors.rawValue
            let row = self.sortedDescriptors.index(where: { $0.uuid == descriptor.uuid })!
            let indexPath = IndexPath(row: row, section: section)
            DispatchQueue.main.async {
                self.tableView.beginUpdates()
                self.tableView.reloadRows(at: [indexPath], with: .none)
                self.tableView.endUpdates()
            }
        }
    }
}

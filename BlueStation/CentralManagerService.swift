//
//  CentralManagerService.swift
//  BlueStation
//
//  Created by Анастасия Ступникова on 14.11.2022.
//

import CoreBluetooth

private enum State {
    case initial
    case waitingBluetoothOn
    case unsupported
    case scanInProgress
    case idle
}

protocol CentralManagerServiceDelegate: AnyObject {
    func deviceUnsupported()
    func waitingBluetoothOn()
    func scanStarted()
    func deviceFound()
}

final class CentralManagerService: NSObject {
    private var centralManager: CBCentralManager?
    weak var delegate: CentralManagerServiceDelegate?
    
    private var currentState: State = .initial
    private var foundPeripherals: Set<CBPeripheral> = []
    private var peripheralsConnections: [CBPeripheral: Connection] = [:]
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    private func startScan() {
        currentState = .scanInProgress
        delegate?.scanStarted()
        foundPeripherals = []
        centralManager?.scanForPeripherals(withServices: [AudioUUID.service])
    }
    
    func getConnection() -> Connection? {
        guard
            let manager = centralManager,
            case .idle = currentState,
            let peripheral = foundPeripherals.first
        else { return nil }
        
        if let connection = peripheralsConnections[peripheral], connection.isValid {
            return connection
        }
        
        let connection = Connection(peripheral: peripheral, centralManager: manager)
        peripheralsConnections[peripheral] = connection
        return connection
    }
}

extension CentralManagerService: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .resetting, .unauthorized, .poweredOff:
            currentState = .waitingBluetoothOn
            delegate?.waitingBluetoothOn()
        case .poweredOn:
            startScan()
        default:
            currentState = .unsupported
            centralManager = nil
            delegate?.deviceUnsupported()
        }
    }
    
    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        foundPeripherals.insert(peripheral)
        currentState = .idle
        centralManager?.stopScan()
        delegate?.deviceFound()
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheralsConnections[peripheral]?.didConnect()
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        peripheralsConnections[peripheral]?.didDisconnect()
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        peripheralsConnections[peripheral]?.didFailToConnect()
    }
}


//
//  Connection.swift
//  BlueStation
//
//  Created by Анастасия Ступникова on 14.11.2022.
//

import CoreBluetooth

private enum State {
    case connectionInProgress
    case waitingServices
    case waitingCharacteristic
    case connected
    case invalid
}

protocol ConnectionDelegate: AnyObject {
    func connectionReady()
    func connectionClosed()
}

final class Connection: NSObject {
    private weak var centralManager: CBCentralManager?
    private let peripheral: CBPeripheral
    private var bufferCharacteristic: CBCharacteristic?
    private var locationCharacteristic: CBCharacteristic?
    weak var delegate: ConnectionDelegate?
    
    private var currentState: State = .connectionInProgress
    var isValid: Bool { currentState != .invalid }
    
    private var dataQueue: Data = Data()
    private var locationData: Data?
    private var isReadyToSend: Bool = true
    
    init(peripheral: CBPeripheral, centralManager: CBCentralManager) {
        self.peripheral = peripheral
        self.centralManager = centralManager
        super.init()
        peripheral.delegate = self
        centralManager.connect(peripheral)
    }
    
    func didConnect() {
        peripheral.discoverServices([AudioUUID.service])
        changeState(to: .waitingServices)
    }
    
    func didDisconnect() {
        changeState(to: .invalid)
    }
    
    func didFailToConnect() {
        changeState(to: .invalid)
    }
    
    private func changeState(to newState: State) {
        if case .invalid = currentState { return }
        currentState = newState
        
        switch currentState {
        case .connected:
            delegate?.connectionReady()
        case .invalid:
            delegate?.connectionClosed()
        default: break
        }
    }
    
    func close() {
        centralManager?.cancelPeripheralConnection(peripheral)
        changeState(to: .invalid)
    }
    
    func sendAudioData(data: Data) {
        guard currentState == .connected else { return }
        dataQueue.append(data)
        
        if dataQueue.count > 3000 {
            dataQueue = dataQueue.suffix(3000)
        }
        
        if isReadyToSend { sendPacket() }
    }
    
    func sendLocation(locationData: [Double]) {
        guard currentState == .connected else { return }
        
        var data = Data()
        locationData.forEach { data.append(withUnsafeBytes(of: $0) { Data($0) }) }
        
        self.locationData = data
    }
    
    private func sendPacket() {
        guard currentState == .connected else { return }
        guard let bufferCharacteristic = bufferCharacteristic else { return }
        isReadyToSend = false
        
        let data = dataQueue.prefix(400)
        dataQueue = dataQueue.dropFirst(400)

        peripheral.writeValue(
            data,
            for: bufferCharacteristic,
            type: .withoutResponse
        )
    }
}

extension Connection: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let service = peripheral.services?.first else {
            changeState(to: .invalid)
            return
        }
        
        changeState(to: .waitingCharacteristic)
        peripheral.discoverCharacteristics([
            AudioUUID.bufferCharacteristic,
            AudioUUID.locationCharacteristic
        ], for: service)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard
            let characteristics = service.characteristics,
            let bufferCharacteristic = characteristics.first(where: { $0.uuid == AudioUUID.bufferCharacteristic }),
            let locationCharacteristic = characteristics.first(where: { $0.uuid == AudioUUID.locationCharacteristic })
        else {
            changeState(to: .invalid)
            return
        }
        
        self.bufferCharacteristic = bufferCharacteristic
        self.locationCharacteristic = locationCharacteristic
        changeState(to: .connected)
    }
    
    func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
        if let locationData = locationData, let locationCharacteristic = locationCharacteristic {
            self.locationData = nil
            peripheral.writeValue(
                locationData,
                for: locationCharacteristic,
                type: .withoutResponse
            )
        }
        
        guard !dataQueue.isEmpty else {
            isReadyToSend = true
            return
        }
        
        sendPacket()
    }
}

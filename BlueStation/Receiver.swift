//
//  Receiver.swift
//  BlueStation
//
//  Created by Анастасия Ступникова on 14.11.2022.
//

import CoreBluetooth
import AVFoundation

protocol ReceiverDelegate: AnyObject {
    func didReceiveLocation(location: [Double])
}

final class Receiver: NSObject {
    private var peripheralManager: CBPeripheralManager?
    private var audioPlayer = AudioPlayer()
    weak var delegate: ReceiverDelegate?
    
    override init() {
        super.init()
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
    
    private func start() {
        let bufferCharacteristic = CBMutableCharacteristic(
            type: AudioUUID.bufferCharacteristic,
            properties: [.writeWithoutResponse],
            value: nil,
            permissions: [.writeable]
        )
        
        let locationCharacteristic = CBMutableCharacteristic(
            type: AudioUUID.locationCharacteristic,
            properties: [.writeWithoutResponse],
            value: nil,
            permissions: [.writeable]
        )
        
        let service = CBMutableService(type: AudioUUID.service, primary: true)
        service.characteristics = [bufferCharacteristic, locationCharacteristic]
        peripheralManager?.add(service)
        
        peripheralManager?.startAdvertising([
            CBAdvertisementDataLocalNameKey: "BlueStation",
            CBAdvertisementDataServiceUUIDsKey: [AudioUUID.service]
        ])
    }
    
    private func handleSoundPacket(data: Data) {
        let framesCount = AVAudioFrameCount(data.count) * 4
        
        let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 44100, channels: 1, interleaved: false)
        let pcmBuffer = AVAudioPCMBuffer(pcmFormat: format!, frameCapacity: framesCount)!
        pcmBuffer.frameLength = framesCount
        
        for i in 0..<data.count {
            pcmBuffer.floatChannelData!.pointee[i * 4] = Float(data[i]) / 255 - 0.5
            pcmBuffer.floatChannelData!.pointee[i * 4 + 1] = Float(data[i]) / 255 - 0.5
            pcmBuffer.floatChannelData!.pointee[i * 4 + 2] = Float(data[i]) / 255 - 0.5
            pcmBuffer.floatChannelData!.pointee[i * 4 + 3] = Float(data[i]) / 255 - 0.5
        }
        
        audioPlayer.play(buffer: pcmBuffer)
    }
    
    private func handleLocationPacket(data: Data) {
        let doubleSize = MemoryLayout<Double>.size
        
        guard data.count == doubleSize * 3 else { return }
        
        var data = data
        var location: [Double] = []
        
        while data.count >= doubleSize {
            location.append(data.prefix(doubleSize).withUnsafeBytes { $0.load(as: Double.self) })
            data = data.dropFirst(doubleSize)
        }
        
        delegate?.didReceiveLocation(location: location)
    }
}

extension Receiver: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if peripheral.state == .poweredOn {
            start()
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        requests.forEach { request in
            switch request.characteristic.uuid {
            case AudioUUID.bufferCharacteristic:
                request.value.flatMap { handleSoundPacket(data: $0) }
            case AudioUUID.locationCharacteristic:
                request.value.flatMap { handleLocationPacket(data: $0) }
            default: break
            }
        }
    }
}

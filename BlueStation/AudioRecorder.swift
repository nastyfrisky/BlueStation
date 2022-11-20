//
//  AudioSource.swift
//  BlueStation
//
//  Created by Анастасия Ступникова on 13.11.2022.
//

import AVFoundation

final class AudioRecorder {
    private let engine = AVAudioEngine()
    
    func startRecord(onPacket: @escaping (Data) -> Void) {
        let format = engine.inputNode.outputFormat(forBus: 0)
        let bufferSize: UInt32 = UInt32(format.sampleRate) / 4
        
        engine.inputNode.installTap(
            onBus: 0,
            bufferSize: bufferSize,
            format: format
        ) { buffer, time in
            var data: [UInt8] = []
            for i in 0..<buffer.frameLength / 4 {
                let amp = buffer.floatChannelData!.pointee[Int(i) * 4]
                data.append(UInt8((amp + 1) * 255 / 2))
            }
            
            onPacket(Data(data))
        }
        
        try? engine.start()
    }
    
    func stopRecord() {
        engine.stop()
        engine.inputNode.removeTap(onBus: 0)
    }
}

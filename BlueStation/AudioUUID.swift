//
//  AudioUUID.swift
//  BlueStation
//
//  Created by Анастасия Ступникова on 14.11.2022.
//

import CoreBluetooth

enum AudioUUID {
    static let service = CBUUID(nsuuid: UUID(uuidString: "B17843CE-478A-4C9D-A6E5-BCAE47CE4CC6")!)
    static let bufferCharacteristic = CBUUID(nsuuid: UUID(uuidString: "263BF3FF-DD3E-4D00-A6FF-5DAA25403F58")!)
    static let locationCharacteristic = CBUUID(nsuuid: UUID(uuidString: "CB443EFB-AF98-470A-BA12-6CEBA4754F48")!)
}

//
//  Presenter.swift
//  BlueStation
//
//  Created by Анастасия Ступникова on 14.11.2022.
//

import CoreLocation
import AVFoundation

protocol PresenterInput {
    func viewDidLoad()
    func micPressed()
    func micReleased()
}

final class Presenter {
    private let centralManagerService = CentralManagerService()
    private let receiver = Receiver()
    private let audioRecorder = AudioRecorder()
    private let locationProvider = LocationProvider()
    
    private weak var view: ViewControllerInput?
    
    private var currentConnection: Connection?
    private var isReadyToStream = false
    private var isConnected = false
    private var isMicPressed = false
    
    private var locationData: [Double]?
    
    init(view: ViewControllerInput) {
        self.view = view
        centralManagerService.delegate = self
        receiver.delegate = self
    }
}

extension Presenter: PresenterInput {
    private func isMicAccessGranted() -> Bool {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            return true
        case .denied:
            view?.showMicAlert()
            return false
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission { _ in }
            return false
        @unknown default:
            return false
        }
    }
    
    func micPressed() {
        guard isMicAccessGranted() else { return }
        
        isMicPressed = true
        
        currentConnection = centralManagerService.getConnection()
        currentConnection?.delegate = self
        
        locationProvider.requestLocation { [weak self] location in
            self?.locationData = location
            guard self?.isConnected ?? false else { return }
            self?.currentConnection?.sendLocation(locationData: location)
        }
        
        view?.configureState(with: .init(text: "Установка соединения...", color: .systemYellow))
        view?.configureMic(with: .init(color: .systemYellow, isEnabled: true))
    }
    
    func micReleased() {
        isMicPressed = false
        
        audioRecorder.stopRecord()
        
        currentConnection?.delegate = nil
        currentConnection?.close()

        if isReadyToStream {
            view?.configureState(with: .init(text: "Устройство найдено", color: .systemBlue))
            view?.configureMic(with: .init(color: .systemBlue, isEnabled: true))
        }
    }
    
    func viewDidLoad() {
        view?.configureState(with: .init(text: "Инициализация...", color: .black))
        view?.configureMic(with: .init(color: .gray, isEnabled: false))
    }
}

extension Presenter: CentralManagerServiceDelegate {
    func deviceUnsupported() {
        isReadyToStream = false
        view?.configureState(with: .init(text: "Ваше устройство не поддерживает Bluetooth :(", color: .systemRed))
    }
    
    func waitingBluetoothOn() {
        isReadyToStream = false
        view?.configureState(with: .init(text: "Для работы приложения включите Bluetooth", color: .darkGray))
        view?.configureMic(with: .init(color: .gray, isEnabled: false))
    }
    
    func scanStarted() {
        isReadyToStream = false
        view?.configureState(with: .init(text: "Поиск устройств...", color: .black))
    }
    
    func deviceFound() {
        isReadyToStream = true
        view?.configureState(with: .init(text: "Устройство найдено", color: .systemBlue))
        view?.configureMic(with: .init(color: .systemBlue, isEnabled: true))
    }
}

extension Presenter: ConnectionDelegate {
    func connectionReady() {
        view?.configureState(with: .init(text: "Соединение установлено, говорите", color: .systemGreen))
        view?.configureMic(with: .init(color: .systemGreen, isEnabled: true))
        
        locationData.flatMap { self.currentConnection?.sendLocation(locationData: $0) }
        
        audioRecorder.startRecord { [weak self] data in
            self?.currentConnection?.sendAudioData(data: data)
        }
    }
    
    func connectionClosed() {
        currentConnection = nil
        isConnected = false
        
        if isReadyToStream && isMicPressed {
            view?.configureState(with: .init(text: "Произошла ошибка", color: .systemRed))
            view?.configureMic(with: .init(color: .systemRed, isEnabled: true))
        }
    }
}

extension Presenter: ReceiverDelegate {
    func didReceiveLocation(location: [Double]) {
        locationProvider.requestLocation { [weak self] userLocation in
            self?.locationData = userLocation
            self?.showDistanceBetweenLocations(location1: location, location2: userLocation)
        }
        
        if let locationData = locationData {
            showDistanceBetweenLocations(location1: location, location2: locationData)
        }
    }
    
    func showDistanceBetweenLocations(location1: [Double], location2: [Double]) {
        let distance = convertToCLLocation(location: location1).distance(
            from: convertToCLLocation(location: location2)
        )
        
        view?.setDistanceText(text: "Примерное расстояние \(Int(distance)) м.")
    }
    
    func convertToCLLocation(location: [Double]) -> CLLocation {
        CLLocation(
            coordinate: .init(latitude: location[0], longitude: location[1]),
            altitude: location[2],
            horizontalAccuracy: .zero,
            verticalAccuracy: .zero,
            course: .zero,
            speed: .zero,
            timestamp: Date()
        )
    }
}

//
//  LocationProvider.swift
//  BlueStation
//
//  Created by Анастасия Ступникова on 14.11.2022.
//

import CoreLocation

final class LocationProvider: NSObject {
    private let locationManager = CLLocationManager()
    
    private var completion: (([Double]) -> Void)?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
    }
    
    func requestLocation(completion: @escaping ([Double]) -> Void) {
        locationManager.requestLocation()
        self.completion = completion
    }
}

extension LocationProvider: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        completion?([location.coordinate.latitude, location.coordinate.longitude, location.altitude])
        completion = nil
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}
}

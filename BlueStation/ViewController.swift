//
//  ViewController.swift
//  BlueStation
//
//  Created by Анастасия Ступникова on 11.11.2022.
//

import UIKit

protocol ViewControllerInput: AnyObject {
    func configureState(with model: StateViewModel)
    func configureMic(with model: MicrophoneButtonModel)
    func setDistanceText(text: String)
    func showMicAlert()
}

final class ViewController: UIViewController {
    
    private lazy var presenter: PresenterInput = Presenter(view: self)
    private let stateView = StateView()
    private let microphoneButton = MicrophoneButton()
    private let distanceLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 28)
        label.numberOfLines = 0
        return label
    }()
    
    override var preferredStatusBarStyle: UIStatusBarStyle { .darkContent }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        [stateView, distanceLabel, microphoneButton].forEach {
            view.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            stateView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stateView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            stateView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
        ])
        
        NSLayoutConstraint.activate([
            microphoneButton.widthAnchor.constraint(equalToConstant: 100),
            microphoneButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            microphoneButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        
        NSLayoutConstraint.activate([
            distanceLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            distanceLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            distanceLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        microphoneButton.addTarget(self, action: #selector(micPressed), for: .touchDown)
        microphoneButton.addTarget(self, action: #selector(micReleased), for: .touchUpInside)
        microphoneButton.addTarget(self, action: #selector(micReleased), for: .touchUpOutside)
        microphoneButton.addTarget(self, action: #selector(micReleased), for: .touchCancel)
        
        presenter.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNeedsStatusBarAppearanceUpdate()
    }
    
    @objc private func micPressed() {
        presenter.micPressed()
    }
    
    @objc private func micReleased() {
        presenter.micReleased()
    }
}

extension ViewController: ViewControllerInput {
    func configureState(with model: StateViewModel) {
        stateView.configure(with: model)
    }
    
    func configureMic(with model: MicrophoneButtonModel) {
        microphoneButton.configure(with: model)
    }
    
    func setDistanceText(text: String) {
        distanceLabel.text = text
    }
    
    func showMicAlert() {
        let alertViewController = UIAlertController(
            title: "Нужен доступ",
            message: "Для начала общения необходимо разрешение на использование микрофона",
            preferredStyle: .actionSheet
        )
        
        alertViewController.addAction(UIAlertAction(
            title: "Ок",
            style: .default,
            handler: { _ in alertViewController.dismiss(animated: true) }
        ))
        
        present(alertViewController, animated: true)
    }
}

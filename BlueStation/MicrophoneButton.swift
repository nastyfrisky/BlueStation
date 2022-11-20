//
//  MicrophoneButton.swift
//  BlueStation
//
//  Created by Анастасия Ступникова on 14.11.2022.
//

import UIKit

struct MicrophoneButtonModel {
    let color: UIColor
    let isEnabled: Bool
}

final class MicrophoneButton: UIButton {
    init() {
        super.init(frame: .zero)
        setupView()
    }
    
    required init?(coder: NSCoder) { nil }
    
    override func updateConstraints() {
        super.updateConstraints()
        layer.cornerRadius = frame.height / 2
        
        let spacing = frame.height / 4
        imageEdgeInsets = .init(top: spacing, left: spacing, bottom: spacing, right: spacing)
    }
    
    private func setupView() {
        setImage(UIImage(systemName: "mic")?.withRenderingMode(.alwaysTemplate), for: .normal)
        contentVerticalAlignment = .fill
        contentHorizontalAlignment = .fill
        
        tintColor = .white
        
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalTo: heightAnchor)
        ])
    }
}

extension MicrophoneButton {
    func configure(with model: MicrophoneButtonModel) {
        backgroundColor = model.color
        isEnabled = model.isEnabled
    }
}

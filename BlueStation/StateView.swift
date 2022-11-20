//
//  StateView.swift
//  BlueStation
//
//  Created by Анастасия Ступникова on 14.11.2022.
//

import UIKit

struct StateViewModel {
    let text: String
    let color: UIColor
}

private enum Constants {
    static let viewHeight: CGFloat = 40
    static let horizontalSpacing: CGFloat = 16
}

final class StateView: UIView {
    
    private let stateLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()
    
    init() {
        super.init(frame: .zero)
        setupView()
    }
    
    required init?(coder: NSCoder) { nil }
    
    private func setupView() {
        layer.cornerRadius = Constants.viewHeight / 4
        
        addSubview(stateLabel)
        
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: Constants.viewHeight)
        ])
        
        NSLayoutConstraint.activate([
            stateLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Constants.horizontalSpacing),
            stateLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Constants.horizontalSpacing),
            stateLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
}

extension StateView {
    func configure(with model: StateViewModel) {
        stateLabel.text = model.text
        backgroundColor = model.color
    }
}

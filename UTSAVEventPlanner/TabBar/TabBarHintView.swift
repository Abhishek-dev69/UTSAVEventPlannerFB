//
//  TabBarHintView.swift
//  UTSAV
//
//  Created by Abhishek on 10/03/26.
//

import UIKit

final class TabBarHintView: UIView {

    private let label = UILabel()
    private let arrow = UIView()

    init(message: String) {
        super.init(frame: .zero)

        backgroundColor = UIColor(
            red: 139/255,
            green: 59/255,
            blue: 240/255,
            alpha: 1
        )

        layer.cornerRadius = 10
        translatesAutoresizingMaskIntoConstraints = false

        label.text = message
        label.textColor = .white
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.numberOfLines = 0
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        arrow.backgroundColor = backgroundColor
        arrow.translatesAutoresizingMaskIntoConstraints = false
        arrow.transform = CGAffineTransform(rotationAngle: .pi / 4)

        addSubview(label)
        addSubview(arrow)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),

            arrow.widthAnchor.constraint(equalToConstant: 12),
            arrow.heightAnchor.constraint(equalToConstant: 12),
            arrow.centerXAnchor.constraint(equalTo: centerXAnchor),
            arrow.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 6)
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(close))
        addGestureRecognizer(tap)
    }

    required init?(coder: NSCoder) { fatalError() }

    @objc private func close() {
        removeFromSuperview()
    }
}

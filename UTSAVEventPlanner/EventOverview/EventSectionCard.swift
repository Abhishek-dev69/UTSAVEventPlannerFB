import UIKit

final class EventSectionCard: UIView {

    private let onTap: () -> Void

    init(
        iconName: String,
        title: String,
        subtitle: String,
        progress: Float,
        buttonTitle: String,
        onTap: @escaping () -> Void
    ) {
        self.onTap = onTap
        super.init(frame: .zero)
        setupUI(iconName: iconName, title: title, subtitle: subtitle, progress: progress, buttonTitle: buttonTitle)
    }

    required init?(coder: NSCoder) { fatalError("init coder") }

    private func setupUI(iconName: String, title: String, subtitle: String, progress: Float, buttonTitle: String) {

        backgroundColor = .white
        layer.cornerRadius = 20
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.05
        layer.shadowRadius = 6
        layer.shadowOffset = CGSize(width: 0, height: 3)

        translatesAutoresizingMaskIntoConstraints = false

        // Icon container
        let iconBG = UIView()
        iconBG.backgroundColor = UIColor(red: 245/255, green: 235/255, blue: 255/255, alpha: 1)
        iconBG.layer.cornerRadius = 14
        iconBG.translatesAutoresizingMaskIntoConstraints = false
        iconBG.heightAnchor.constraint(equalToConstant: 48).isActive = true
        iconBG.widthAnchor.constraint(equalToConstant: 48).isActive = true

        let icon = UIImageView(image: UIImage(systemName: iconName))
        icon.tintColor = UIColor(red: 140/255, green: 75/255, blue: 245/255, alpha: 1)
        icon.translatesAutoresizingMaskIntoConstraints = false

        iconBG.addSubview(icon)

        NSLayoutConstraint.activate([
            icon.centerXAnchor.constraint(equalTo: iconBG.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: iconBG.centerYAnchor),
            icon.heightAnchor.constraint(equalToConstant: 22)
        ])

        // Labels
        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.text = title

        let subtitleLabel = UILabel()
        subtitleLabel.font = .systemFont(ofSize: 14)
        subtitleLabel.textColor = .gray
        subtitleLabel.text = subtitle

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 2

        let topRow = UIStackView(arrangedSubviews: [iconBG, textStack])
        topRow.axis = .horizontal
        topRow.spacing = 14
        topRow.alignment = .center

        // Progress bar
        let progressView = UIProgressView()
        progressView.trackTintColor = .systemGray5
        progressView.progressTintColor = UIColor(red: 140/255, green: 75/255, blue: 245/255, alpha: 1)
        progressView.layer.cornerRadius = 2
        progressView.clipsToBounds = true
        progressView.progress = progress

        // Button
        let btn = UIButton(type: .system)
        btn.setTitle(buttonTitle, for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        btn.layer.cornerRadius = 18
        btn.heightAnchor.constraint(equalToConstant: 40).isActive = true

        btn.backgroundColor = UIColor(red: 140/255, green: 75/255, blue: 245/255, alpha: 1)
        btn.addAction(UIAction(handler: { _ in self.onTap() }), for: .touchUpInside)

        let main = UIStackView(arrangedSubviews: [topRow, progressView, btn])
        main.axis = .vertical
        main.spacing = 14
        main.translatesAutoresizingMaskIntoConstraints = false

        addSubview(main)

        NSLayoutConstraint.activate([
            main.topAnchor.constraint(equalTo: topAnchor, constant: 18),
            main.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            main.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18),
            main.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -18)
        ])
    }
}


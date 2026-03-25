import UIKit

final class EventSectionCard: UIView {

    private let onTap: () -> Void

    init(
        iconName: String,
        title: String,
        subtitle: String,
        progress: Float? = nil,
        onTap: @escaping () -> Void
    )
    {
        self.onTap = onTap
        super.init(frame: .zero)
        setupUI(iconName: iconName, title: title, subtitle: subtitle, progress: progress)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    private func setupUI(
        iconName: String,
        title: String,
        subtitle: String,
        progress: Float?
    )
    {

        backgroundColor = UIColor(white: 1.0, alpha: 0.85)
        layer.cornerRadius = 18
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.06
        layer.shadowRadius = 6
        layer.shadowOffset = CGSize(width: 0, height: 3)

        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(greaterThanOrEqualToConstant: 95).isActive = true

        // -------------------------
        // ICON
        // -------------------------
        let iconBG = UIView()
        iconBG.backgroundColor = UIColor(red: 245/255, green: 235/255, blue: 255/255, alpha: 1)
        iconBG.layer.cornerRadius = 14
        iconBG.translatesAutoresizingMaskIntoConstraints = false
        iconBG.widthAnchor.constraint(equalToConstant: 48).isActive = true
        iconBG.heightAnchor.constraint(equalToConstant: 48).isActive = true

        let icon = UIImageView(image: UIImage(systemName: iconName))
        icon.tintColor = UIColor(red: 140/255, green: 75/255, blue: 245/255, alpha: 1)
        icon.translatesAutoresizingMaskIntoConstraints = false

        iconBG.addSubview(icon)

        NSLayoutConstraint.activate([
            icon.centerXAnchor.constraint(equalTo: iconBG.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: iconBG.centerYAnchor),
            icon.heightAnchor.constraint(equalToConstant: 22)
        ])

        // -------------------------
        // TEXT CONTENT
        // -------------------------
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)

        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = .systemFont(ofSize: 13)
        subtitleLabel.textColor = .gray

        let progressView = UIProgressView()
        progressView.trackTintColor = .systemGray5
        progressView.progressTintColor = UIColor(
            red: 140/255,
            green: 75/255,
            blue: 245/255,
            alpha: 1
        )

        if let progress {
            progressView.progress = progress
            progressView.isHidden = false
        } else {
            progressView.isHidden = true
        }


        let textStack = UIStackView(arrangedSubviews: [
            titleLabel, subtitleLabel, progressView
        ])
        textStack.axis = .vertical
        textStack.spacing = 6

        // -------------------------
        // CHEVRON ( > ) ON RIGHT
        // -------------------------
        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = .gray
        chevron.translatesAutoresizingMaskIntoConstraints = false
        chevron.widthAnchor.constraint(equalToConstant: 16).isActive = true

        // -------------------------
        // MAIN HORIZONTAL STACK
        // -------------------------
        let mainRow = UIStackView(arrangedSubviews: [
            iconBG, textStack, chevron
        ])
        mainRow.axis = .horizontal
        mainRow.alignment = .center
        mainRow.spacing = 14
        mainRow.translatesAutoresizingMaskIntoConstraints = false

        addSubview(mainRow)

        NSLayoutConstraint.activate([
            mainRow.topAnchor.constraint(equalTo: topAnchor, constant: 18),
            mainRow.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            mainRow.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18),
            mainRow.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -18)
        ])

        // -------------------------
        // FULL TAPPABLE BUTTON
        // -------------------------
        let tapButton = UIButton(type: .custom)
        tapButton.translatesAutoresizingMaskIntoConstraints = false
        tapButton.backgroundColor = .clear
        tapButton.addTarget(self, action: #selector(handleTap), for: .touchUpInside)

        addSubview(tapButton)

        NSLayoutConstraint.activate([
            tapButton.topAnchor.constraint(equalTo: topAnchor),
            tapButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            tapButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            tapButton.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    @objc private func handleTap() {
        animateTap()
        onTap()
    }

    private func animateTap() {
        UIView.animate(withDuration: 0.08, animations: {
            self.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.transform = .identity
            }
        }
    }
}


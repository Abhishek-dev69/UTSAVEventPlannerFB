import UIKit

// MARK: - Gradient headline with intrinsic size (prevents clipping)
private final class GradientLabel: UIView {
    private let gradient = CAGradientLayer()
    private let textLayer = CATextLayer()

    var text: String = "" { didSet { update() } }
    var font: UIFont = .systemFont(ofSize: 56, weight: .heavy) { didSet { update() } }
    var kern: CGFloat = 3 { didSet { update() } }
    var gradientColors: [CGColor] = [UIColor.white.cgColor,
                                     UIColor.systemPurple.withAlphaComponent(0.6).cgColor] {
        didSet { gradient.colors = gradientColors }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = false
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint   = CGPoint(x: 1, y: 1)
        layer.addSublayer(gradient)

        textLayer.contentsScale = UIScreen.main.scale
        textLayer.alignmentMode = .center
        gradient.mask = textLayer

        update()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func attributed() -> NSAttributedString {
        let a = NSMutableAttributedString(string: text)
        a.addAttributes([.font: font, .kern: kern], range: NSRange(location: 0, length: a.length))
        return a
    }
    private func update() {
        textLayer.string = attributed()
        invalidateIntrinsicContentSize()
        setNeedsLayout()
    }
    override var intrinsicContentSize: CGSize {
        let s = (text as NSString).size(withAttributes: [.font: font, .kern: kern])
        return CGSize(width: ceil(s.width), height: ceil(s.height * 1.1))
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        gradient.frame = bounds
        textLayer.frame = bounds
    }
}

// MARK: - Welcome Screen
final class WelcomeViewController: UIViewController {

    private let backgroundGradient = CAGradientLayer()

    private let welcomeLabel: UILabel = {
        let l = UILabel()
        l.text = "Welcome to"
        l.textAlignment = .center
        l.textColor = UIColor.white.withAlphaComponent(0.9)
        l.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let bigTitle: GradientLabel = {
        let g = GradientLabel()
        g.text = "UTSΛV"
        g.font = UIFont.systemFont(ofSize: 56, weight: .heavy)
        g.kern = 3
        g.gradientColors = [UIColor.white.cgColor,
                            UIColor.systemPurple.withAlphaComponent(0.6).cgColor]
        g.layer.shadowColor = UIColor.black.cgColor
        g.layer.shadowOpacity = 0.35
        g.layer.shadowOffset = CGSize(width: 0, height: 6)
        g.layer.shadowRadius = 12
        g.translatesAutoresizingMaskIntoConstraints = false
        return g
    }()

    private let subheadLabel: UILabel = {
        let l = UILabel()
        l.text = "Choose your role to begin"
        l.textAlignment = .center
        l.textColor = UIColor.white.withAlphaComponent(0.78)
        l.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // Cards
    private let plannerCard = RoleCardView(
        assetName: "event_planner",
        title: "Event Planner",
        subtitle: "Organize and\nmanage events"
    )
    private let vendorCard = RoleCardView(
        assetName: "vendor",
        title: "Vendor",
        subtitle: "Provide services\nand offerings"
    )

    private lazy var cardsStack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [plannerCard, vendorCard])
        s.axis = .vertical
        s.spacing = 18
        s.alignment = .fill
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupBackground()
        layout()

        // Wire tap → push programmatic Login
        plannerCard.addTarget(self, action: #selector(openPlannerLogin), for: .touchUpInside)

        // Accessibility
        plannerCard.isAccessibilityElement = true
        plannerCard.accessibilityTraits = .button
        plannerCard.accessibilityLabel = "Event Planner"
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        backgroundGradient.frame = view.bounds
    }

    private func setupBackground() {
        backgroundGradient.colors = [
            UIColor(red: 0.58, green: 0.28, blue: 0.95, alpha: 1).cgColor,
            UIColor(red: 0.41, green: 0.16, blue: 0.82, alpha: 1).cgColor,
            UIColor(red: 0.27, green: 0.07, blue: 0.49, alpha: 1).cgColor
        ]
        backgroundGradient.locations = [0.0, 0.55, 1.0]
        backgroundGradient.startPoint = CGPoint(x: 0.5, y: 0.0)
        backgroundGradient.endPoint   = CGPoint(x: 0.5, y: 1.0)
        view.layer.insertSublayer(backgroundGradient, at: 0)
    }

    private func layout() {
        let column = UIStackView(arrangedSubviews: [welcomeLabel, bigTitle, subheadLabel, cardsStack])
        column.axis = .vertical
        column.alignment = .center
        column.spacing = 16
        column.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(column)

        NSLayoutConstraint.activate([
            column.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            column.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
            column.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 96),
            column.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24)
        ])

        [welcomeLabel, subheadLabel].forEach {
            $0.leadingAnchor.constraint(equalTo: column.leadingAnchor).isActive = true
            $0.trailingAnchor.constraint(equalTo: column.trailingAnchor).isActive = true
        }
        NSLayoutConstraint.activate([
            bigTitle.leadingAnchor.constraint(equalTo: column.leadingAnchor),
            bigTitle.trailingAnchor.constraint(equalTo: column.trailingAnchor)
        ])

        cardsStack.leadingAnchor.constraint(equalTo: column.leadingAnchor).isActive = true
        cardsStack.trailingAnchor.constraint(equalTo: column.trailingAnchor).isActive = true
    }

    // MARK: - Navigation
    @objc private func openPlannerLogin() {
        // IMPORTANT: we are NOT loading a nib anymore.
        let loginVC = LoginViewController() // programmatic VC
        if let nav = navigationController {
            nav.pushViewController(loginVC, animated: true)
        } else {
            // Fallback if this VC wasn't embedded in a nav controller
            let nav = UINavigationController(rootViewController: loginVC)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true)
        }
    }
}

// MARK: - Reusable Role Card (uses asset images for the left tile)
private final class RoleCardView: UIControl {

    private let container = UIView()
    private let blurView: UIVisualEffectView
    private let topHighlight = CAGradientLayer()
    private let borderLayer = CAShapeLayer()

    private let iconShadow = UIView()
    private let iconImageView = UIImageView()

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))

    init(assetName: String, title: String, subtitle: String) {
        blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialLight))
        super.init(frame: .zero)

        isUserInteractionEnabled = true

        container.backgroundColor = UIColor.white.withAlphaComponent(0.18)
        container.layer.cornerRadius = 22
        container.layer.shadowColor = UIColor.black.cgColor
        container.layer.shadowOpacity = 0.18
        container.layer.shadowOffset = CGSize(width: 0, height: 10)
        container.layer.shadowRadius = 16
        container.translatesAutoresizingMaskIntoConstraints = false
        container.isUserInteractionEnabled = false
        addSubview(container)

        blurView.alpha = 0.35
        blurView.clipsToBounds = true
        blurView.layer.cornerRadius = 22
        blurView.translatesAutoresizingMaskIntoConstraints = false
        blurView.isUserInteractionEnabled = false
        container.addSubview(blurView)

        topHighlight.colors = [
            UIColor.white.withAlphaComponent(0.25).cgColor,
            UIColor.white.withAlphaComponent(0.0).cgColor
        ]
        topHighlight.startPoint = CGPoint(x: 0.5, y: 0.0)
        topHighlight.endPoint   = CGPoint(x: 0.5, y: 1.0)
        blurView.layer.addSublayer(topHighlight)

        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.strokeColor = UIColor.white.withAlphaComponent(0.25).cgColor
        borderLayer.lineWidth = 1
        container.layer.addSublayer(borderLayer)

        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 16
        row.translatesAutoresizingMaskIntoConstraints = false
        row.isUserInteractionEnabled = false
        container.addSubview(row)

        iconShadow.translatesAutoresizingMaskIntoConstraints = false
        iconShadow.layer.shadowColor = UIColor.black.cgColor
        iconShadow.layer.shadowOpacity = 0.25
        iconShadow.layer.shadowOffset = CGSize(width: 0, height: 8)
        iconShadow.layer.shadowRadius = 12

        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.image = UIImage(named: assetName)
        iconImageView.contentMode = .scaleAspectFill
        iconImageView.clipsToBounds = true
        iconImageView.layer.cornerRadius = 18

        iconShadow.addSubview(iconImageView)
        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: iconShadow.leadingAnchor),
            iconImageView.trailingAnchor.constraint(equalTo: iconShadow.trailingAnchor),
            iconImageView.topAnchor.constraint(equalTo: iconShadow.topAnchor),
            iconImageView.bottomAnchor.constraint(equalTo: iconShadow.bottomAnchor),
            iconShadow.widthAnchor.constraint(equalToConstant: 64),
            iconShadow.heightAnchor.constraint(equalToConstant: 64)
        ])

        titleLabel.text = title
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 22, weight: .semibold)

        subtitleLabel.text = subtitle
        subtitleLabel.numberOfLines = 0
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.85)
        subtitleLabel.font = .systemFont(ofSize: 15, weight: .regular)

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.alignment = .leading
        textStack.spacing = 6
        textStack.isUserInteractionEnabled = false

        chevron.tintColor = UIColor.white.withAlphaComponent(0.95)
        chevron.setContentHuggingPriority(.required, for: .horizontal)
        chevron.isUserInteractionEnabled = false

        row.addArrangedSubview(iconShadow)
        row.addArrangedSubview(textStack)
        row.addArrangedSubview(chevron)

        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),
            container.topAnchor.constraint(equalTo: topAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor),

            blurView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            blurView.topAnchor.constraint(equalTo: container.topAnchor),
            blurView.bottomAnchor.constraint(equalTo: container.bottomAnchor),

            row.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            row.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            row.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            row.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16),

            heightAnchor.constraint(greaterThanOrEqualToConstant: 104)
        ])

        addTarget(self, action: #selector(touchDown), for: [.touchDown, .touchDragEnter])
        addTarget(self, action: #selector(touchUp), for: [.touchCancel, .touchDragExit, .touchUpInside])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return bounds.contains(point)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        topHighlight.frame = bounds
        let path = UIBezierPath(roundedRect: container.bounds, cornerRadius: 22)
        borderLayer.path = path.cgPath
        container.layer.shadowPath = path.cgPath
        iconShadow.layer.shadowPath = UIBezierPath(
            roundedRect: CGRect(origin: .zero, size: CGSize(width: 64, height: 64)),
            cornerRadius: 18
        ).cgPath
    }

    @objc private func touchDown() {
        UIView.animate(withDuration: 0.12) {
            self.container.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
            self.container.layer.shadowOpacity = 0.28
        }
    }
    @objc private func touchUp() {
        UIView.animate(withDuration: 0.22,
                       delay: 0,
                       usingSpringWithDamping: 0.85,
                       initialSpringVelocity: 0.6,
                       options: [.allowUserInteraction]) {
            self.container.transform = .identity
            self.container.layer.shadowOpacity = 0.18
        }
    }
}

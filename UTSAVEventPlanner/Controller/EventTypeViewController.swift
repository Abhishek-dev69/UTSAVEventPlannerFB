import UIKit

// MARK: - Model
struct EventTypeItem {
    let title: String
    let imageName: String
}

// MARK: - Controller
final class EventTypeViewController: UIViewController {

    // Header: close button on the left
    private let closeButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "xmark")
        config.baseForegroundColor = .label
        config.contentInsets = .init(top: 8, leading: 8, bottom: 8, trailing: 8)
        let b = UIButton(configuration: config)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.backgroundColor = UIColor.black.withAlphaComponent(0.06)
        b.layer.cornerRadius = 18
        b.clipsToBounds = true
        return b
    }()

    // Centered title, larger and bold
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text = "Select Your Client Event Type"
        l.font = .systemFont(ofSize: 18, weight: .bold) // increased + bold
        l.textColor = .label
        l.textAlignment = .center
        l.numberOfLines = 0
        // Allow the label to compress if needed, but prefer center
        l.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        l.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return l
    }()

    // Collection
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 16
        layout.sectionInset = .init(top: 0, left: 0, bottom: 12, right: 0)

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.backgroundColor = .clear
        cv.register(EventTypeCell.self, forCellWithReuseIdentifier: EventTypeCell.reuseID)
        cv.dataSource = self
        cv.delegate = self
        cv.alwaysBounceVertical = true
        cv.allowsMultipleSelection = false
        return cv
    }()

    // Floating Next button
    private let nextButton: UIButton = {
        var cfg = UIButton.Configuration.filled()
        cfg.title = "Next"
        cfg.baseBackgroundColor = UIColor(red: 0x8B/255.0, green: 0x3B/255.0, blue: 0xF0/255.0, alpha: 1.0)
        cfg.baseForegroundColor = .white
        cfg.cornerStyle = .large
        cfg.contentInsets = .init(top: 14, leading: 28, bottom: 14, trailing: 28)
        let b = UIButton(configuration: cfg)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.layer.cornerRadius = 26
        b.layer.masksToBounds = true
        b.alpha = 0
        b.isHidden = true
        return b
    }()

    // Data
    private let items: [EventTypeItem] = [
        .init(title: "Wedding",          imageName: "event_wedding"),
        .init(title: "Birthday Party",   imageName: "event_birthday"),
        .init(title: "Corporate Event",  imageName: "event_corporate"),
        .init(title: "Baby Shower",      imageName: "event_babyshower"),
        .init(title: "Engagement Party", imageName: "event_engagement"),
        .init(title: "Anniversary",      imageName: "event_anniversary"),
        .init(title: "Schools",          imageName: "event_schools"),
        .init(title: "Holiday Party",    imageName: "event_holiday")
    ]

    private var selectedIndexPath: IndexPath?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        buildLayout()

        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
    }

    // Hide nav bar while this VC is visible to remove the top white/nav area
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if navigationController != nil {
            navigationController?.setNavigationBarHidden(true, animated: false)
        }
    }

    // Restore nav bar when leaving the screen
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if navigationController != nil {
            navigationController?.setNavigationBarHidden(false, animated: false)
        }
    }

    // COMPACT buildLayout (reduced top spacing and centered header)
    private func buildLayout() {
        let header = UIView()
        header.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(header)
        header.addSubview(closeButton)
        header.addSubview(titleLabel)

        view.addSubview(collectionView)
        view.addSubview(nextButton)

        NSLayoutConstraint.activate([
            // header sits close to safe area (notch)
            header.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 6),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),

            // close button left
            closeButton.leadingAnchor.constraint(equalTo: header.leadingAnchor),
            closeButton.topAnchor.constraint(equalTo: header.topAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 36),
            closeButton.heightAnchor.constraint(equalToConstant: 36),

            // center title horizontally inside header
            titleLabel.centerXAnchor.constraint(equalTo: header.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),

            // make sure the title doesn't grow so large that it overlaps the close button:
            // header.width - leftPadding(12) - closeButtonWidth(36) - safety(16) => enforce max width
            titleLabel.widthAnchor.constraint(lessThanOrEqualTo: header.widthAnchor, multiplier: 1.0, constant: -88),

            // minimal header height
            header.bottomAnchor.constraint(equalTo: closeButton.bottomAnchor),

            // collection below header (tight spacing)
            collectionView.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 8),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),

            // next button
            nextButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            nextButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24)
        ])

        // ensure flow layout uses same insets
        if let flow = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            flow.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 12, right: 0)
        }
    }

    private func showNextButton() {
        if nextButton.isHidden {
            nextButton.isHidden = false
            nextButton.alpha = 0
        }
        UIView.animate(withDuration: 0.22) {
            self.nextButton.alpha = 1
        }
    }

    private func hideNextButton() {
        UIView.animate(withDuration: 0.18, animations: {
            self.nextButton.alpha = 0
        }, completion: { _ in
            self.nextButton.isHidden = true
        })
    }

    @objc private func closeTapped() {
        // If embedded in a navigation controller:
        if let nav = navigationController {
            // If this VC is NOT the first controller in the nav stack — just pop
            if nav.viewControllers.first !== self {
                nav.popViewController(animated: true)
                return
            }

            // If this VC is the first in nav and the nav was presented modally, dismiss the nav
            if presentingViewController != nil {
                nav.dismiss(animated: true, completion: nil)
                return
            }
        }

        // Otherwise if presented modally, dismiss
        if presentingViewController != nil {
            dismiss(animated: true, completion: nil)
            return
        }

        // Fallback: try dismissing the root
        view.window?.rootViewController?.dismiss(animated: true, completion: nil)
    }

    // NEXT → EventDetailsViewController (push if nav exists, else present wrapped in nav)
    @objc private func nextTapped() {
        guard let ip = selectedIndexPath else { return }
        _ = items[ip.item] // chosen if you need it

        let vc = EventDetailsViewController()

        // Preferred: push onto current navigation controller (if present)
        if let nav = navigationController {
            nav.pushViewController(vc, animated: true)
            return
        }

        // Fallback: present EventDetails wrapped in a nav controller so it shows a nav bar
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        nav.navigationBar.prefersLargeTitles = false
        present(nav, animated: true)
    }
}

// MARK: - DataSource & Delegate
extension EventTypeViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: EventTypeCell.reuseID,
            for: indexPath
        ) as! EventTypeCell

        cell.configure(with: items[indexPath.item])
        cell.setSelected(selectedIndexPath == indexPath, animated: false)

        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {

        let flow = collectionViewLayout as! UICollectionViewFlowLayout
        let spacing = flow.minimumInteritemSpacing
        let available = collectionView.bounds.width - spacing

        let w = floor(available / 2.0)
        return CGSize(width: w, height: w * 0.78)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        // Toggle if same item is tapped again
        if selectedIndexPath == indexPath {
            selectedIndexPath = nil
            hideNextButton()
            if let cell = collectionView.cellForItem(at: indexPath) as? EventTypeCell {
                cell.setSelected(false, animated: true)
            }
            return
        }

        // Unselect previous
        if let prev = selectedIndexPath,
           let prevCell = collectionView.cellForItem(at: prev) as? EventTypeCell {
            prevCell.setSelected(false, animated: true)
            collectionView.deselectItem(at: prev, animated: false)
        }

        // Select new
        selectedIndexPath = indexPath
        if let cell = collectionView.cellForItem(at: indexPath) as? EventTypeCell {
            cell.setSelected(true, animated: true)
        }

        showNextButton()
    }
}

// MARK: - Cell
final class EventTypeCell: UICollectionViewCell {

    static let reuseID = "EventTypeCell"

    private let container = UIView()
    private let imageView = UIImageView()
    private let gradientLayer = CAGradientLayer()

    // small black rounded background behind the title
    private let textBackground: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor.black.withAlphaComponent(0.55)
        v.layer.cornerRadius = 8
        v.clipsToBounds = true
        return v
    }()

    private let titleLabel = UILabel()
    private let selectionBorder = CAShapeLayer()

    private let heartBadge: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "heart.fill"))
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.tintColor = .systemPurple
        iv.backgroundColor = .clear
        iv.isHidden = true
        return iv
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setup() {
        contentView.backgroundColor = .clear

        container.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(container)

        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 16
        imageView.clipsToBounds = true
        container.addSubview(imageView)

        gradientLayer.colors = [
            UIColor.black.withAlphaComponent(0.0).cgColor,
            UIColor.black.withAlphaComponent(0.65).cgColor,
            UIColor.black.withAlphaComponent(0.90).cgColor
        ]
        gradientLayer.locations = [0.4, 0.8, 1.0]
        imageView.layer.addSublayer(gradientLayer)

        // add text background and title
        container.addSubview(textBackground)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        titleLabel.numberOfLines = 0
        textBackground.addSubview(titleLabel)

        container.addSubview(heartBadge)

        selectionBorder.strokeColor = UIColor.systemBlue.cgColor
        selectionBorder.lineWidth = 2
        selectionBorder.fillColor = UIColor.clear.cgColor
        selectionBorder.isHidden = true
        contentView.layer.addSublayer(selectionBorder)

        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            container.topAnchor.constraint(equalTo: contentView.topAnchor),
            container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            imageView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: container.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: container.bottomAnchor),

            // text background
            textBackground.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            textBackground.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -12),
            textBackground.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12),

            // title inside the pill
            titleLabel.leadingAnchor.constraint(equalTo: textBackground.leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: textBackground.trailingAnchor, constant: -8),
            titleLabel.topAnchor.constraint(equalTo: textBackground.topAnchor, constant: 6),
            titleLabel.bottomAnchor.constraint(equalTo: textBackground.bottomAnchor, constant: -6),

            heartBadge.widthAnchor.constraint(equalToConstant: 22),
            heartBadge.heightAnchor.constraint(equalToConstant: 22),
            heartBadge.topAnchor.constraint(equalTo: container.topAnchor, constant: 6),
            heartBadge.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -6),
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = imageView.bounds
        let path = UIBezierPath(roundedRect: contentView.bounds, cornerRadius: 16)
        selectionBorder.path = path.cgPath
        selectionBorder.frame = contentView.bounds
    }

    func configure(with item: EventTypeItem) {
        titleLabel.text = item.title
        imageView.image = UIImage(named: item.imageName)
    }

    func setSelected(_ selected: Bool, animated: Bool) {
        selectionBorder.isHidden = !selected
        heartBadge.isHidden = !selected
    }
}

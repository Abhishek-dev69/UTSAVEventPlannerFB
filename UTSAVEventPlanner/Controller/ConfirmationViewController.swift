import UIKit

final class ConfirmationViewController: UIViewController {

    // MARK: - Data
    private let details: EventDetails
    private let currencyFormatter: NumberFormatter
    private let dateFormatter: DateFormatter
    private let navTitle: String?

    // MARK: - UI
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let stack = UIStackView()

    private let addServiceButton: UIButton = {
        var cfg = UIButton.Configuration.filled()
        cfg.title = "Add Service"
        cfg.baseForegroundColor = .white
        cfg.baseBackgroundColor = UIColor(red: 0x8B/255, green: 0x3B/255, blue: 0xF0/255, alpha: 1)
        cfg.cornerStyle = .large
        cfg.contentInsets = .init(top: 16, leading: 24, bottom: 16, trailing: 24)
        let b = UIButton(configuration: cfg)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.layer.cornerRadius = 28
        b.layer.masksToBounds = true
        return b
    }()

    private let doLaterButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("I’ll do it later", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        b.setTitleColor(.secondaryLabel, for: .normal)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    // MARK: - Init
    init(
        details: EventDetails,
        currencyFormatter: NumberFormatter,
        dateFormatter: DateFormatter,
        title: String? = nil
    ) {
        self.details = details
        self.currencyFormatter = currencyFormatter
        self.dateFormatter = dateFormatter
        self.navTitle = title
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = navTitle ?? "Confirmation"
        view.backgroundColor = .systemGroupedBackground
        navigationItem.largeTitleDisplayMode = .never

        setupLayout()
        populate()

        addServiceButton.addTarget(self, action: #selector(didTapAddService), for: .touchUpInside)
        doLaterButton.addTarget(self, action: #selector(didTapDoLater), for: .touchUpInside)

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(didTapBack)
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.navigationBar.prefersLargeTitles = false
    }

    // MARK: - Layout
    private func setupLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        stack.translatesAutoresizingMaskIntoConstraints = false

        stack.axis = .vertical
        stack.spacing = 16

        view.addSubview(scrollView)
        view.addSubview(addServiceButton)
        view.addSubview(doLaterButton)

        scrollView.addSubview(contentView)
        contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: addServiceButton.topAnchor, constant: -12),

            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24),

            addServiceButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            addServiceButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            addServiceButton.bottomAnchor.constraint(equalTo: doLaterButton.topAnchor, constant: -8),
            addServiceButton.heightAnchor.constraint(equalToConstant: 56),

            doLaterButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            doLaterButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8)
        ])
    }

    // MARK: - Populate UI
    private func populate() {
        stack.addArrangedSubview(card(title: "Event Name", value: details.eventName))
        stack.addArrangedSubview(card(title: "Client Name", value: details.clientName))
        stack.addArrangedSubview(card(title: "Location", value: details.location))
        stack.addArrangedSubview(card(title: "Guest Count", value: "\(details.guestCount) People"))

        let budget = currencyFormatter.string(
            from: NSNumber(value: details.budgetInPaise / 100)
        ) ?? "—"
        stack.addArrangedSubview(card(title: "Budget", value: budget))

        let start = dateFormatter.string(from: details.startDate)
        let end = dateFormatter.string(from: details.endDate)

        let datesRow = UIStackView()
        datesRow.axis = .horizontal
        datesRow.spacing = 16
        datesRow.distribution = .fillEqually
        datesRow.addArrangedSubview(card(title: "Start Date", value: start))
        datesRow.addArrangedSubview(card(title: "End Date", value: end))

        stack.addArrangedSubview(datesRow)
    }

    // MARK: - Card Component
    private func card(title: String, value: String) -> UIView {
        let container = UIView()
        container.backgroundColor = .secondarySystemGroupedBackground
        container.layer.cornerRadius = 14
        container.layer.shadowColor = UIColor.black.withAlphaComponent(0.15).cgColor
        container.layer.shadowOpacity = 0.1
        container.layer.shadowRadius = 6
        container.layer.shadowOffset = CGSize(width: 0, height: 3)

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 13)
        titleLabel.textColor = .secondaryLabel

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        valueLabel.numberOfLines = 0

        let vStack = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        vStack.axis = .vertical
        vStack.spacing = 8
        vStack.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(vStack)

        NSLayoutConstraint.activate([
            vStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 14),
            vStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 14),
            vStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -14),
            vStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -14)
        ])

        return container
    }

    // MARK: - Actions
    @objc private func didTapAddService() {
        let svc = ServicePickerViewController()
        svc.title = "Add Services"

        let nav = UINavigationController(rootViewController: svc)
        nav.modalPresentationStyle = .fullScreen
        nav.navigationBar.prefersLargeTitles = false

        svc.navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain,
            target: self,
            action: #selector(dismissServicePicker)
        )

        present(nav, animated: true)
    }

    @objc private func dismissServicePicker() {
        presentedViewController?.dismiss(animated: true)
    }

    // ✅ FIXED
    @objc private func didTapDoLater() {
        presentingViewController?.dismiss(animated: true)

        NotificationCenter.default.post(
            name: NSNotification.Name("ReloadEventsDashboard"),
            object: nil
        )
    }

    @objc private func didTapBack() {
        navigationController?.popViewController(animated: true)
    }
}


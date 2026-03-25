import UIKit

final class VendorPaymentDetailViewController: UIViewController {

    // MARK: - Inputs
    private let vendorId: String
    private let vendorName: String

    // MARK: - UI
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let addPaymentButton = UIButton(type: .system)

    // Header views
    private let headerView = UIView()
    private let titleLabel = UILabel()
    private let totalLabel = UILabel()
    private let remainingLabel = UILabel()
    private let progressView = UIProgressView(progressViewStyle: .bar)

    private let utsavPurple = UIColor(
        red: 139/255, green: 59/255, blue: 240/255, alpha: 1
    )

    // MARK: - Data
    private var payments: [PaymentRecord] = []
    private var totalPayable: Double = 0
    private var totalPaid: Double = 0

    // MARK: - Init
    init(vendorId: String, vendorName: String, totalPayable: Double) {
        self.vendorId = vendorId
        self.vendorName = vendorName
        self.totalPayable = totalPayable
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("Use init(vendorId:vendorName:totalPayable:)")
    }

    // MARK: - Lifecycle
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateGradientFrame()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        applyBrandGradient()
        view.backgroundColor = .clear
        
        setupUTSAVNavbar(title: vendorName)
        navigationItem.largeTitleDisplayMode = .never

        setupTable()
        setupHeader()
        setupBottomButton()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reloadDataSelf),
            name: Notification.Name("ReloadPaymentsList"),
            object: nil
        )

        Task { await loadData() }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Header
    private func setupHeader() {
        headerView.backgroundColor = .clear

        let cardContainer = UIView()
        cardContainer.backgroundColor = .white.withAlphaComponent(0.85)
        cardContainer.layer.cornerRadius = 16
        cardContainer.layer.shadowColor = UIColor.black.cgColor
        cardContainer.layer.shadowOpacity = 0.08
        cardContainer.layer.shadowRadius = 10
        cardContainer.layer.shadowOffset = CGSize(width: 0, height: 4)
        cardContainer.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(cardContainer)

        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        titleLabel.text = vendorName

        totalLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        totalLabel.text = "Loading summary..."

        remainingLabel.font = .systemFont(ofSize: 14)
        remainingLabel.text = "Please wait..."
        remainingLabel.textColor = .secondaryLabel

        progressView.progressTintColor = utsavPurple
        progressView.trackTintColor = utsavPurple.withAlphaComponent(0.15)
        progressView.layer.cornerRadius = 3
        progressView.clipsToBounds = true

        [titleLabel, totalLabel, progressView, remainingLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            cardContainer.addSubview($0)
        }

        NSLayoutConstraint.activate([
            cardContainer.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 12),
            cardContainer.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            cardContainer.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            cardContainer.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -12),

            titleLabel.topAnchor.constraint(equalTo: cardContainer.topAnchor, constant: 14),
            titleLabel.leadingAnchor.constraint(equalTo: cardContainer.leadingAnchor, constant: 14),

            totalLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            totalLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),

            progressView.topAnchor.constraint(equalTo: totalLabel.bottomAnchor, constant: 10),
            progressView.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: cardContainer.trailingAnchor, constant: -14),
            progressView.heightAnchor.constraint(equalToConstant: 6),

            remainingLabel.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 10),
            remainingLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            remainingLabel.bottomAnchor.constraint(equalTo: cardContainer.bottomAnchor, constant: -14)
        ])

        headerView.layoutIfNeeded()
        let size = headerView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        headerView.frame.size.height = size.height
        tableView.tableHeaderView = headerView
    }

    // MARK: - Table
    private func setupTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = UIColor.black.withAlphaComponent(0.12)
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = .clear
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")

        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - Bottom Button
    private func setupBottomButton() {
        setupUTSAVPrimaryButton(addPaymentButton, title: "+ Add Payment")
        addPaymentButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        addPaymentButton.addTarget(self, action: #selector(addPaymentTapped), for: .touchUpInside)

        view.addSubview(addPaymentButton)
        view.bringSubviewToFront(addPaymentButton)

        NSLayoutConstraint.activate([
            addPaymentButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            addPaymentButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            addPaymentButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -18)
        ])

        tableView.contentInset.bottom = 80
    }

    // MARK: - Data
    @objc private func reloadDataSelf() {
        Task { await loadData() }
    }

    private func loadData() async {
        do {
            payments = try await PaymentSupabaseManager.shared
                .fetchVendorPayments(vendorId: vendorId)

            totalPaid = payments.reduce(0) { $0 + $1.amount }

            await MainActor.run {
                updateHeader()
                tableView.reloadData()
            }
        } catch {
            print("Vendor detail error:", error)
        }
    }

    private func updateHeader() {
        let remaining = max(0, totalPayable - totalPaid)
        totalLabel.text = "Total Amount: ₹\(fmt(totalPayable))"
        remainingLabel.text = "Remaining: ₹\(fmt(remaining))"
        progressView.setProgress(totalPayable > 0 ? Float(totalPaid / totalPayable) : 0, animated: true)
    }

    // MARK: - Actions
    @objc private func addPaymentTapped() {
        let vc = RecordVendorPaymentViewController(
            vendorId: vendorId,
            vendorName: vendorName
        )
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .pageSheet
        present(nav, animated: true)
    }

    // MARK: - Helpers
    private func fmt(_ v: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return f.string(from: NSNumber(value: v)) ?? "0"
    }
}

// MARK: - Table
extension VendorPaymentDetailViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        payments.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        68
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let p = payments[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.selectionStyle = .none
        cell.backgroundColor = .clear

        // LEFT: Date & Method
        cell.textLabel?.numberOfLines = 2
        let dateStr = formattedDate(p.received_on)
        let title = NSMutableAttributedString(
            string: dateStr,
            attributes: [.font: UIFont.systemFont(ofSize: 15), .foregroundColor: UIColor.label]
        )
        title.append(NSAttributedString(
            string: "\n\(p.method.isEmpty ? "Payment" : p.method)",
            attributes: [.font: UIFont.systemFont(ofSize: 13), .foregroundColor: UIColor.secondaryLabel]
        ))
        cell.textLabel?.attributedText = title

        // RIGHT: Amount
        let rightLabel = UILabel()
        rightLabel.text = "₹\(fmt(p.amount))"
        rightLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        rightLabel.textColor = .label
        rightLabel.sizeToFit()
        cell.accessoryView = rightLabel

        return cell
    }

    private func formattedDate(_ iso: String) -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        if let d = df.date(from: iso) {
            let out = DateFormatter()
            out.dateFormat = "dd MMM yyyy"
            return out.string(from: d)
        }
        let isoFmt = ISO8601DateFormatter()
        if let d = isoFmt.date(from: iso) {
            let out = DateFormatter()
            out.dateFormat = "dd MMM yyyy"
            return out.string(from: d)
        }
        return iso
    }
}

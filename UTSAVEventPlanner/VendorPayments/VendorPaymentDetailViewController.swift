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
        red: 139/255,
        green: 59/255,
        blue: 240/255,
        alpha: 1
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
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        navigationItem.title = vendorName
        navigationItem.largeTitleDisplayMode = .never
        setupNavAppearance()

        setupTable()
        setupHeader()
        setupBottomButton()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reloadData),
            name: Notification.Name("ReloadPaymentsList"),
            object: nil
        )

        Task { await loadData() }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Navigation
    private func setupNavAppearance() {
        let ap = UINavigationBarAppearance()
        ap.configureWithOpaqueBackground()
        ap.backgroundColor = .systemBackground
        ap.titleTextAttributes = [.foregroundColor: UIColor.label]
        navigationController?.navigationBar.standardAppearance = ap
        navigationController?.navigationBar.scrollEdgeAppearance = ap
        navigationController?.navigationBar.tintColor = .label
    }

    // MARK: - Header
    private func setupHeader() {
        headerView.backgroundColor = .systemBackground

        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        titleLabel.text = vendorName

        totalLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        remainingLabel.font = .systemFont(ofSize: 14)
        remainingLabel.textColor = .secondaryLabel

        progressView.progressTintColor = utsavPurple
        progressView.trackTintColor = .systemGray5
        progressView.layer.cornerRadius = 3
        progressView.clipsToBounds = true

        [titleLabel, totalLabel, progressView, remainingLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            headerView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),

            totalLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            totalLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),

            progressView.topAnchor.constraint(equalTo: totalLabel.bottomAnchor, constant: 12),
            progressView.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20),
            progressView.heightAnchor.constraint(equalToConstant: 6),

            remainingLabel.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 8),
            remainingLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            remainingLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -20)
        ])

        headerView.layoutIfNeeded()
        headerView.frame.size.height = 170
        tableView.tableHeaderView = headerView
    }

    // MARK: - Table
    private func setupTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")

        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - Bottom Button
    private func setupBottomButton() {
        addPaymentButton.setTitle("+ Add Payment", for: .normal)
        addPaymentButton.setTitleColor(.white, for: .normal)
        addPaymentButton.backgroundColor = utsavPurple
        addPaymentButton.layer.cornerRadius = 26
        addPaymentButton.translatesAutoresizingMaskIntoConstraints = false
        addPaymentButton.addTarget(self, action: #selector(addPaymentTapped), for: .touchUpInside)

        view.addSubview(addPaymentButton)

        NSLayoutConstraint.activate([
            addPaymentButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            addPaymentButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            addPaymentButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            addPaymentButton.heightAnchor.constraint(equalToConstant: 52)
        ])

        tableView.contentInset.bottom = 90
    }

    // MARK: - Data
    @objc private func reloadData() {
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

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let p = payments[indexPath.row]

        // ✅ Use value1 style for amount on right
        let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
        cell.selectionStyle = .none

        // LEFT: Date
        cell.textLabel?.text = formattedDate(p.received_on)
        cell.textLabel?.font = .systemFont(ofSize: 15)

        // RIGHT: Amount
        cell.detailTextLabel?.text = "₹\(fmt(p.amount))"
        cell.detailTextLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        cell.detailTextLabel?.textColor = .label

        // METHOD BELOW DATE
        let methodLabel = UILabel()
        methodLabel.text = p.method
        methodLabel.font = .systemFont(ofSize: 13)
        methodLabel.textColor = .secondaryLabel
        methodLabel.translatesAutoresizingMaskIntoConstraints = false

        cell.contentView.addSubview(methodLabel)

        NSLayoutConstraint.activate([
            methodLabel.leadingAnchor.constraint(equalTo: cell.textLabel!.leadingAnchor),
            methodLabel.topAnchor.constraint(equalTo: cell.textLabel!.bottomAnchor, constant: 2)
        ])

        return cell
    }

    private func formattedDate(_ iso: String) -> String {
        let isoFmt = ISO8601DateFormatter()
        if let d = isoFmt.date(from: iso) {
            let f = DateFormatter()
            f.dateFormat = "dd MMM yyyy"
            return f.string(from: d)
        }
        return iso
    }
}


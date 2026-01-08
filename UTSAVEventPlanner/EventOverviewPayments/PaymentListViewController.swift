//
// PaymentListViewController.swift
// Shows Client / Vendor payments for an event (opens from EventOverview -> Payment Status "Open")
//

import UIKit

final class PaymentListViewController: UIViewController {

    private let segmented = UISegmentedControl(items: ["Client Payments", "Vendor Payments"])
    private let headerCard = UIView()
    private let titleLabel = UILabel()
    private let totalLabel = UILabel()
    private let remainingLabel = UILabel()
    private let progressView = UIProgressView(progressViewStyle: .default)
    private let transactionsTable = UITableView(frame: .zero, style: .plain)
    private let addPaymentButton = UIButton(type: .system)

    private var event: EventRecord

    // data
    private var payments: [PaymentRecord] = []
    private var totalAmount: Double = 0.0
    private var receivedAmount: Double = 0.0

    // current payer type
    private var payerType: String {
        segmented.selectedSegmentIndex == 0 ? "client" : "vendor"
    }

    // MARK: - Init
    init(event: EventRecord) {
        self.event = event
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("Use init(event:)") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 0.97, alpha: 1)
        setupNav()
        setupUI()
        setupTable()
        setupObservers()
        Task { await loadData() }
    }

    private func setupNav() {
        navigationItem.title = event.eventName
        let back = UIBarButtonItem(image: UIImage(systemName: "chevron.left"), style: .plain, target: self, action: #selector(backPressed))
        back.tintColor = .black
        navigationItem.leftBarButtonItem = back
    }
    @objc private func backPressed() { navigationController?.popViewController(animated: true) }

    private func setupUI() {
        segmented.selectedSegmentIndex = 0
        segmented.translatesAutoresizingMaskIntoConstraints = false
        segmented.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        view.addSubview(segmented)

        headerCard.backgroundColor = .white
        headerCard.layer.cornerRadius = 12
        headerCard.layer.shadowOpacity = 0.05
        headerCard.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerCard)

        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.text = "Client: \(event.clientName)"
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        totalLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        totalLabel.translatesAutoresizingMaskIntoConstraints = false

        remainingLabel.font = .systemFont(ofSize: 13)
        remainingLabel.textColor = .secondaryLabel
        remainingLabel.translatesAutoresizingMaskIntoConstraints = false

        progressView.layer.cornerRadius = 3
        progressView.clipsToBounds = true
        progressView.translatesAutoresizingMaskIntoConstraints = false

        headerCard.addSubview(titleLabel)
        headerCard.addSubview(totalLabel)
        headerCard.addSubview(progressView)
        headerCard.addSubview(remainingLabel)

        addPaymentButton.setTitle("+  Add Payment", for: .normal)
        addPaymentButton.setTitleColor(.white, for: .normal)
        addPaymentButton.backgroundColor = UIColor(red: 140/255, green: 75/255, blue: 245/255, alpha: 1)
        addPaymentButton.layer.cornerRadius = 22
        addPaymentButton.translatesAutoresizingMaskIntoConstraints = false
        addPaymentButton.addTarget(self, action: #selector(addPaymentTapped), for: .touchUpInside)
        view.addSubview(addPaymentButton)

        transactionsTable.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(transactionsTable)

        NSLayoutConstraint.activate([
            segmented.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            segmented.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmented.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            segmented.heightAnchor.constraint(equalToConstant: 36),

            headerCard.topAnchor.constraint(equalTo: segmented.bottomAnchor, constant: 12),
            headerCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            headerCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            titleLabel.topAnchor.constraint(equalTo: headerCard.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: headerCard.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: headerCard.trailingAnchor, constant: -12),

            totalLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            totalLabel.leadingAnchor.constraint(equalTo: headerCard.leadingAnchor, constant: 12),

            progressView.topAnchor.constraint(equalTo: totalLabel.bottomAnchor, constant: 8),
            progressView.leadingAnchor.constraint(equalTo: headerCard.leadingAnchor, constant: 12),
            progressView.trailingAnchor.constraint(equalTo: headerCard.trailingAnchor, constant: -12),
            progressView.heightAnchor.constraint(equalToConstant: 6),

            remainingLabel.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 8),
            remainingLabel.leadingAnchor.constraint(equalTo: headerCard.leadingAnchor, constant: 12),
            remainingLabel.bottomAnchor.constraint(equalTo: headerCard.bottomAnchor, constant: -12),

            addPaymentButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            addPaymentButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            addPaymentButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -18),
            addPaymentButton.heightAnchor.constraint(equalToConstant: 44),

            transactionsTable.topAnchor.constraint(equalTo: headerCard.bottomAnchor, constant: 12),
            transactionsTable.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            transactionsTable.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            transactionsTable.bottomAnchor.constraint(equalTo: addPaymentButton.topAnchor, constant: -12)
        ])
    }

    private func setupTable() {
        transactionsTable.dataSource = self
        transactionsTable.delegate = self
        transactionsTable.register(UITableViewCell.self, forCellReuseIdentifier: "txCell")
        transactionsTable.separatorStyle = .none
    }

    private func setupObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(reloadPayments), name: Notification.Name("ReloadPaymentsList"), object: nil)
    }

    @objc private func reloadPayments() {
        Task { await loadData() }
    }

    @objc private func segmentChanged() {
        // update UI and data
        Task { await loadPaymentsOnly() }
    }

    // MARK: - Data loading
    @MainActor
    private func loadData() async {
        // 1) total from cart items
        do {
            let cart = try await EventDataManager.shared.fetchCartItems(eventId: event.id)
            totalAmount = cart.reduce(0.0) { acc, c in
                if let lt = c.lineTotal { return acc + lt }
                let r = c.rate ?? 0; let q = Double(c.quantity ?? 0)
                return acc + (r * q)
            }
        } catch {
            print("load cart error:", error)
            totalAmount = 0.0
        }

        // 2) payments
        await loadPaymentsOnly()
    }

    @MainActor
    private func loadPaymentsOnly() async {
        do {
            // fetch all payments (we'll filter by payerType locally since your schema currently doesn't have payer_type)
            // If you added payer_type to DB, modify PaymentSupabaseManager.fetchPayments to accept payerType.
            let filtered = try await PaymentSupabaseManager.shared.fetchPayments(eventId: event.id, payerType: payerType)
            self.payments = filtered
            self.receivedAmount = self.payments.reduce(0.0) { $0 + $1.amount }

            // If PaymentRecord has a payerType field, use: self.payments = all.filter { $0.payerType == payerType }

            self.receivedAmount = self.payments.reduce(0.0) { $0 + $1.amount }

            updateHeaderUI()
            transactionsTable.reloadData()
        } catch {
            print("load payments error:", error)
            self.payments = []
            self.receivedAmount = 0.0
            updateHeaderUI()
            transactionsTable.reloadData()
        }
    }

    private func updateHeaderUI() {
        totalLabel.text = "Total Amount: ₹\(formatMoney(totalAmount))"
        let remaining = max(0.0, totalAmount - receivedAmount)
        remainingLabel.text = "Remaining: ₹\(formatMoney(remaining))"
        let progress = totalAmount > 0 ? Float(min(1.0, receivedAmount / totalAmount)) : 0.0
        progressView.setProgress(progress, animated: true)
    }

    private func formatMoney(_ v: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 2
        return f.string(from: NSNumber(value: v)) ?? "0"
    }

    @objc private func addPaymentTapped() {

        let contentVC: UIViewController

        if segmented.selectedSegmentIndex == 0 {
            contentVC = RecordClientPaymentViewController(event: event)
        } else {
            contentVC = RecordVendorPaymentViewController(event: event)
        }

        let nav = UINavigationController(rootViewController: contentVC)
        nav.modalPresentationStyle = .pageSheet

        if let sheet = nav.sheetPresentationController {
            sheet.detents = [
                .medium(),   // 👈 dropdown height
                .large()     // 👈 expandable if needed
            ]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 20
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
        }

        present(nav, animated: true)
    }
}

extension PaymentListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ t: UITableView, numberOfRowsInSection section: Int) -> Int {
        payments.count
    }

    func tableView(_ t: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 68 }

    func tableView(_ t: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let p = payments[indexPath.row]
        let cell = t.dequeueReusableCell(withIdentifier: "txCell", for: indexPath)
        cell.selectionStyle = .none

        // left: amount bold, below: method; right: date
        let amt = "₹\(formatMoney(p.amount))"
        var method = p.method
        if method.isEmpty { method = "Payment" }
        let dateText = formattedDateDisplay(p.received_on)

        // Build content
        let title = NSMutableAttributedString(string: amt, attributes: [
            .font: UIFont.systemFont(ofSize: 16, weight: .semibold)
        ])
        title.append(NSAttributedString(string: "\n\(method)", attributes: [
            .font: UIFont.systemFont(ofSize: 13),
            .foregroundColor: UIColor.secondaryLabel
        ]))

        cell.textLabel?.numberOfLines = 2
        cell.textLabel?.attributedText = title
        cell.detailTextLabel?.text = dateText

        // Use accessory-like right-aligned label
        let rightLabel = UILabel()
        rightLabel.text = dateText
        rightLabel.font = .systemFont(ofSize: 13)
        rightLabel.textColor = .secondaryLabel
        rightLabel.sizeToFit()

        cell.accessoryView = rightLabel
        return cell
    }

    private func formattedDateDisplay(_ iso: String) -> String {
        // expected receivedOn is "yyyy-MM-dd" (or ISO). Try parse.
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        if let d = df.date(from: iso) {
            let out = DateFormatter()
            out.dateFormat = "dd MMM"
            return out.string(from: d)
        }
        // fallback: attempt ISO8601
        let isoFmt = ISO8601DateFormatter()
        if let d = isoFmt.date(from: iso) {
            let out = DateFormatter()
            out.dateFormat = "dd MMM"
            return out.string(from: d)
        }
        return iso
    }
}


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
    private let utsavPurple = UIColor(
        red: 139/255,
        green: 59/255,
        blue: 240/255,
        alpha: 1
    )
    
    private func styleSegments() {
        segmented.selectedSegmentTintColor = UIColor(
            red: 136/255,
            green: 71/255,
            blue: 246/255,
            alpha: 1
        )

        segmented.setTitleTextAttributes(
            [.foregroundColor: UIColor.white],
            for: .selected
        )

        segmented.setTitleTextAttributes(
            [.foregroundColor: UIColor.gray],
            for: .normal
        )
    }


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

        let back = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backPressed)
        )
        back.tintColor = .black
        navigationItem.leftBarButtonItem = back

        // ✅ SHARE ICON
        let share = UIBarButtonItem(
            image: UIImage(systemName: "square.and.arrow.up"),
            style: .plain,
            target: self,
            action: #selector(shareTapped)
        )
        share.tintColor = .black
        navigationItem.rightBarButtonItem = share
    }
    @objc private func shareTapped() {
        let pdfURL = generatePaymentPDF()
        let vc = UIActivityViewController(activityItems: [pdfURL], applicationActivities: nil)

        if let pop = vc.popoverPresentationController {
            pop.barButtonItem = navigationItem.rightBarButtonItem
        }

        present(vc, animated: true)
    }
    private func generatePaymentPDF() -> URL {

        // ✅ Force Light Mode ONLY while generating PDF
        let previousStyle = view.overrideUserInterfaceStyle
        view.overrideUserInterfaceStyle = .light
        defer { view.overrideUserInterfaceStyle = previousStyle }

        let brandLogo = UIImage(named: "utsav_logo")
        let fileName = "Payment Summary of \(event.eventName).pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842) // A4
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        let paid = receivedAmount
        let remaining = max(0, totalAmount - paid)

        try? renderer.writePDF(to: url) { context in
            context.beginPage()

            let ctx = context.cgContext
            var y: CGFloat = 0

            // =========================
            // HEADER BAR
            // =========================
            let headerHeight: CGFloat = 90
            let utsavPurple = UIColor(
                red: 138/255,
                green: 73/255,
                blue: 246/255,
                alpha: 1
            )

            ctx.setFillColor(utsavPurple.cgColor)
            ctx.fill(CGRect(x: 0, y: 0, width: pageRect.width, height: headerHeight))

            // --- BRAND LOGO ---
            if let logo = brandLogo {
                let logoSize: CGFloat = 44
                let logoRect = CGRect(x: 24, y: 22, width: logoSize, height: logoSize)
                logo.draw(in: logoRect)

                "UTSAV".draw(
                    at: CGPoint(x: logoRect.maxX + 10, y: 26),
                    withAttributes: [
                        .font: UIFont.boldSystemFont(ofSize: 16),
                        .foregroundColor: UIColor.white
                    ]
                )

                "Where Events Flow, Not Fail".draw(
                    at: CGPoint(x: logoRect.maxX + 10, y: 46),
                    withAttributes: [
                        .font: UIFont.systemFont(ofSize: 10),
                        .foregroundColor: UIColor.white.withAlphaComponent(0.85)
                    ]
                )
            }

            // --- RIGHT SIDE TITLE ---
            "Payment Summary".draw(
                at: CGPoint(x: pageRect.width - 240, y: 28),
                withAttributes: [
                    .font: UIFont.boldSystemFont(ofSize: 26),
                    .foregroundColor: UIColor.white
                ]
            )

            "\(event.eventName) • \(event.clientName)".draw(
                at: CGPoint(x: pageRect.width - 240, y: 60),
                withAttributes: [
                    .font: UIFont.systemFont(ofSize: 14),
                    .foregroundColor: UIColor.white.withAlphaComponent(0.9)
                ]
            )

            y = headerHeight + 24

            // =========================
            // SUMMARY CARD
            // =========================
            let cardRect = CGRect(x: 24, y: y, width: pageRect.width - 48, height: 120)
            ctx.setFillColor(UIColor.white.cgColor)
            ctx.setShadow(
                offset: CGSize(width: 0, height: 2),
                blur: 6,
                color: UIColor.black.withAlphaComponent(0.1).cgColor
            )
            ctx.fill(cardRect)
            ctx.setShadow(offset: .zero, blur: 0, color: nil)

            func drawSummary(title: String, value: String, x: CGFloat) {
                title.draw(
                    at: CGPoint(x: x, y: y + 24),
                    withAttributes: [
                        .font: UIFont.systemFont(ofSize: 14, weight: .medium),
                        .foregroundColor: UIColor(white: 0.4, alpha: 1)
                    ]
                )

                value.draw(
                    at: CGPoint(x: x, y: y + 48),
                    withAttributes: [
                        .font: UIFont.boldSystemFont(ofSize: 18),
                        .foregroundColor: UIColor.black
                    ]
                )
            }

            drawSummary(title: "Total Amount", value: "₹\(formatMoney(totalAmount))", x: 40)
            drawSummary(title: "Paid", value: "₹\(formatMoney(paid))", x: 220)
            drawSummary(title: "Remaining", value: "₹\(formatMoney(remaining))", x: 380)

            y += cardRect.height + 32

            // =========================
            // PAYMENT HISTORY TITLE
            // =========================
            "Payment History".draw(
                at: CGPoint(x: 32, y: y),
                withAttributes: [
                    .font: UIFont.boldSystemFont(ofSize: 18),
                    .foregroundColor: UIColor.black
                ]
            )

            y += 20

            // =========================
            // TABLE HEADER
            // =========================
            let headerY = y
            ctx.setFillColor(UIColor(white: 0.95, alpha: 1).cgColor)
            ctx.fill(CGRect(x: 24, y: headerY, width: pageRect.width - 48, height: 32))

            func drawHeader(_ text: String, x: CGFloat) {
                text.draw(
                    at: CGPoint(x: x, y: headerY + 8),
                    withAttributes: [
                        .font: UIFont.systemFont(ofSize: 13, weight: .semibold),
                        .foregroundColor: UIColor(white: 0.3, alpha: 1)
                    ]
                )
            }

            drawHeader("Amount", x: 40)
            drawHeader("Method", x: 200)
            drawHeader("Date", x: 400)

            y += 32

            // =========================
            // TABLE ROWS
            // =========================
            for p in payments {

                if y > pageRect.height - 80 {
                    context.beginPage()
                    y = 40
                }

                ctx.setStrokeColor(UIColor(white: 0.85, alpha: 1).cgColor)
                ctx.setLineWidth(0.5)
                ctx.move(to: CGPoint(x: 24, y: y))
                ctx.addLine(to: CGPoint(x: pageRect.width - 24, y: y))
                ctx.strokePath()

                "₹\(formatMoney(p.amount))".draw(
                    at: CGPoint(x: 40, y: y + 10),
                    withAttributes: [
                        .font: UIFont.systemFont(ofSize: 13),
                        .foregroundColor: UIColor.black
                    ]
                )

                (p.method.isEmpty ? "Payment" : p.method).draw(
                    at: CGPoint(x: 200, y: y + 10),
                    withAttributes: [
                        .font: UIFont.systemFont(ofSize: 13),
                        .foregroundColor: UIColor.black
                    ]
                )

                formattedDateDisplay(p.received_on).draw(
                    at: CGPoint(x: 400, y: y + 10),
                    withAttributes: [
                        .font: UIFont.systemFont(ofSize: 13),
                        .foregroundColor: UIColor.black
                    ]
                )

                y += 32
            }

            // =========================
            // REMINDER
            // =========================
            let reminderText = """
            This is a gentle reminder that an amount of ₹\(formatMoney(remaining)) is currently pending for the event.

            We sincerely appreciate the payment received so far and kindly request you to settle the remaining balance at your convenience.

            Thank you for your cooperation and Trust.
            """

            (reminderText as NSString).draw(
                in: CGRect(x: 32, y: pageRect.height - 120, width: pageRect.width - 64, height: 70),
                withAttributes: [
                    .font: UIFont.systemFont(ofSize: 12),
                    .foregroundColor: UIColor(white: 0.35, alpha: 1)
                ]
            )

            // =========================
            // FOOTER
            // =========================
            let footerText = "Generated by UTSAV • \(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .none))"
            footerText.draw(
                at: CGPoint(x: 32, y: pageRect.height - 40),
                withAttributes: [
                    .font: UIFont.systemFont(ofSize: 10),
                    .foregroundColor: UIColor(white: 0.45, alpha: 1)
                ]
            )
        }

        return url
    }

    @objc private func backPressed() { navigationController?.popViewController(animated: true) }

    private func setupUI() {
        segmented.selectedSegmentIndex = 0
        segmented.translatesAutoresizingMaskIntoConstraints = false
        segmented.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        view.addSubview(segmented)
        
        styleSegments()

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

        // ✅ UTSAV BRAND COLORS
        progressView.progressTintColor = utsavPurple
        progressView.trackTintColor = UIColor(
            red: 139/255,
            green: 59/255,
            blue: 240/255,
            alpha: 0.15
        )

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


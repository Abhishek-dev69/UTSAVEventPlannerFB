//
// EventOverviewViewController.swift
// Updated: header shows Client Name + labeled fields (Date, Location, Guests)
// Fixed: conditional binding error for non-optional guestCount
// Updated: 2025-12-11
//

import UIKit

final class EventOverviewViewController: UIViewController {

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    private var event: EventRecord

    // Data
    private var cartItems: [CartItemRecord] = []
    private var inhouseItems: [CartItemRecord] = []
    private var outsourceItems: [CartItemRecord] = []
    private var totalAmount: Double = 0.0
    private var receivedAmount: Double = 0.0

    // Header UI
    private let headerCard = UIView()
    private let headerClientLabel = UILabel()    // now shows CLIENT NAME (bold)
    private let headerDateLabel = UILabel()
    private let headerLocationLabel = UILabel()
    private let headerGuestLabel = UILabel()

    // MARK: Init
    init(event: EventRecord) {
        self.event = event
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("Use init(event:)") }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor(white: 0.97, alpha: 1)
        setupNav()
        setupScroll()
        setupHeaderCard()   // header added before building sections

        Task { await loadCartAndPayments() }
    }

    private func setupNav() {
        // Keep navigation title as event name
        navigationItem.title = event.eventName

        let backItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backPressed)
        )
        backItem.tintColor = .black
        navigationItem.leftBarButtonItem = backItem

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        appearance.titleTextAttributes = [.font: UIFont.systemFont(ofSize: 20, weight: .semibold)]

        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }

    @objc private func backPressed() {
        navigationController?.popViewController(animated: true)
    }

    // -----------------------------
    // MARK: SCROLLVIEW SETUP (fix taps)
    // -----------------------------
    private func setupScroll() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        // improve tap responsiveness
        scrollView.delaysContentTouches = false
        scrollView.canCancelContentTouches = false

        view.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        contentStack.axis = .vertical
        contentStack.spacing = 18
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32)
        ])
    }

    // -----------------------------
    // MARK: HEADER CARD SETUP
    // -----------------------------
    private func setupHeaderCard() {
        headerCard.translatesAutoresizingMaskIntoConstraints = false
        headerCard.backgroundColor = .white
        headerCard.layer.cornerRadius = 14
        headerCard.layer.shadowColor = UIColor.black.cgColor
        headerCard.layer.shadowOpacity = 0.06
        headerCard.layer.shadowRadius = 8
        headerCard.layer.shadowOffset = CGSize(width: 0, height: 6)

        headerClientLabel.translatesAutoresizingMaskIntoConstraints = false
        headerClientLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        headerClientLabel.numberOfLines = 2

        headerDateLabel.translatesAutoresizingMaskIntoConstraints = false
        headerDateLabel.font = .systemFont(ofSize: 13)
        headerDateLabel.textColor = .secondaryLabel
        headerDateLabel.numberOfLines = 2

        headerLocationLabel.translatesAutoresizingMaskIntoConstraints = false
        headerLocationLabel.font = .systemFont(ofSize: 13)
        headerLocationLabel.textColor = .secondaryLabel
        headerLocationLabel.numberOfLines = 2

        headerGuestLabel.translatesAutoresizingMaskIntoConstraints = false
        headerGuestLabel.font = .systemFont(ofSize: 13)
        headerGuestLabel.textColor = .secondaryLabel

        // header content layout
        headerCard.addSubview(headerClientLabel)
        headerCard.addSubview(headerDateLabel)
        headerCard.addSubview(headerLocationLabel)
        headerCard.addSubview(headerGuestLabel)

        NSLayoutConstraint.activate([
            headerClientLabel.topAnchor.constraint(equalTo: headerCard.topAnchor, constant: 16),
            headerClientLabel.leadingAnchor.constraint(equalTo: headerCard.leadingAnchor, constant: 16),
            headerClientLabel.trailingAnchor.constraint(equalTo: headerCard.trailingAnchor, constant: -16),

            headerDateLabel.topAnchor.constraint(equalTo: headerClientLabel.bottomAnchor, constant: 10),
            headerDateLabel.leadingAnchor.constraint(equalTo: headerCard.leadingAnchor, constant: 16),
            headerDateLabel.trailingAnchor.constraint(equalTo: headerCard.trailingAnchor, constant: -16),

            headerLocationLabel.topAnchor.constraint(equalTo: headerDateLabel.bottomAnchor, constant: 10),
            headerLocationLabel.leadingAnchor.constraint(equalTo: headerCard.leadingAnchor, constant: 16),
            headerLocationLabel.trailingAnchor.constraint(equalTo: headerCard.trailingAnchor, constant: -16),

            headerGuestLabel.topAnchor.constraint(equalTo: headerLocationLabel.bottomAnchor, constant: 10),
            headerGuestLabel.leadingAnchor.constraint(equalTo: headerCard.leadingAnchor, constant: 16),
            headerGuestLabel.trailingAnchor.constraint(equalTo: headerCard.trailingAnchor, constant: -16),
            headerGuestLabel.bottomAnchor.constraint(equalTo: headerCard.bottomAnchor, constant: -16)
        ])

        // Insert header at top of content stack
        contentStack.addArrangedSubview(headerCard)
    }

    // -----------------------------
    // MARK: LOAD DATA
    // -----------------------------
    @MainActor
    private func loadCartAndPayments() async {
        do {
            cartItems = try await EventDataManager.shared.fetchCartItems(eventId: event.id)
            let payments = try await EventDataManager.shared.fetchPayments(eventId: event.id)
            receivedAmount = payments.reduce(0.0, { $0 + $1.amount })
        } catch {
            print("Error loading:", error)
        }

        computeFromCart()
        updateHeaderContent()
        buildAllSections()
    }

    private func sourceType(for item: CartItemRecord) -> String {
        if let s = item.sourceType, !s.isEmpty { return s.lowercased() }
        if let t = item.metadata?["type"], !t.isEmpty { return t.lowercased() }
        let name = item.serviceName?.lowercased() ?? ""
        return name.contains("outsource") ? "outsource" : "in_house"
    }

    private func lineTotal(for item: CartItemRecord) -> Double {
        if let lt = item.lineTotal { return lt }
        return (item.rate ?? 0) * Double(item.quantity ?? 0)
    }

    private func computeFromCart() {
        inhouseItems = cartItems.filter { sourceType(for: $0) == "in_house" || sourceType(for: $0) == "inhouse" }
        outsourceItems = cartItems.filter { sourceType(for: $0) == "outsource" }
        totalAmount = cartItems.reduce(0) { $0 + lineTotal(for: $1) }
    }

    // -----------------------------
    // MARK: BUILD SECTIONS
    // -----------------------------
    private func buildAllSections() {
        // remove everything after header (keep header as first)
        let keepHeader = contentStack.arrangedSubviews.first == headerCard
        contentStack.arrangedSubviews.forEach { view in
            if keepHeader && view === headerCard { return }
            view.removeFromSuperview()
        }

        addClientRequirements()
        addBudgetCheckIn()
        addPaymentStatus()
        addInventory()
    }

    private func addClientRequirements() {
        let subtitle = "\(inhouseItems.count) in-house · \(outsourceItems.count) outsourced"

        let card = EventSectionCard(
            iconName: "checklist",
            title: "Client Requirements",
            subtitle: subtitle,
            progress: computeProgressForRequirements()
        ) { [weak self] in
            guard let self else { return }
            self.navigationController?.pushViewController(
                ClientRequirementsViewController(event: self.event, cartItems: self.cartItems),
                animated: true
            )
        }

        contentStack.addArrangedSubview(card)
    }

    private func addBudgetCheckIn() {
        let budgetRupees = Double(event.budgetInPaise) / 100.0
        let spent = receivedAmount
        let subtitle = "Spent ₹\(formatMoney(spent)) of ₹\(formatMoney(budgetRupees))"
        let progress: Float = budgetRupees > 0 ? Float(spent / budgetRupees) : 0

        let card = EventSectionCard(
            iconName: "indianrupeesign.circle",
            title: "Budget Check-in",
            subtitle: subtitle,
            progress: progress
        ) { [weak self] in
            guard let self else { return }
            let budgetVC = BudgetDetailViewController()
            self.navigationController?.pushViewController(budgetVC, animated: true)
        }

        contentStack.addArrangedSubview(card)
    }

    private func addPaymentStatus() {
        let percent = totalAmount > 0 ? (receivedAmount / totalAmount) : 0.0
        let subtitle = "Received ₹\(formatMoney(receivedAmount)) of ₹\(formatMoney(totalAmount)) (\(Int(percent * 100))%)"

        let card = EventSectionCard(
            iconName: "rupeesign.circle",
            title: "Payment Status",
            subtitle: subtitle,
            progress: Float(percent)
        ) { [weak self] in
            guard let self else { return }
            self.navigationController?.pushViewController(
                PaymentListViewController(event: self.event),
                animated: true
            )
        }

        contentStack.addArrangedSubview(card)
    }

    private func addInventory() {
        let card = EventSectionCard(
            iconName: "shippingbox",
            title: "Inventory Overview",
            subtitle: "Manage items & usage",
            progress: 0.0
        ) { [weak self] in
            guard let self else { return }
            self.navigationController?.pushViewController(
                InventoryOverviewViewController(event: self.event),
                animated: true
            )
        }

        contentStack.addArrangedSubview(card)
    }

    private func computeProgressForRequirements() -> Float {
        let total = max(1, cartItems.count)
        let done = Double(inhouseItems.count + outsourceItems.count)
        return Float(min(1.0, done / Double(total)))
    }

    private func formatMoney(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 2
        return f.string(from: NSNumber(value: value)) ?? "0"
    }

    // -----------------------------
    // MARK: HEADER CONTENT UPDATES
    // -----------------------------
    private func updateHeaderContent() {
        // Show client name in the header (bold). If missing, fallback to eventName.
        let client = (event.clientName).trimmingCharacters(in: .whitespacesAndNewlines)
        headerClientLabel.text = !client.isEmpty ? client : (event.eventName)

        headerDateLabel.text = composedDateString(startISO: event.startDate, endISO: event.endDate)

        // Location label prefixed with "Location:"
        let locRaw = (event.location).trimmingCharacters(in: .whitespacesAndNewlines)
        headerLocationLabel.text = !locRaw.isEmpty ? "Location: \(locRaw)" : "Location: not available"

        // Guests label prefixed with "Guests:"
        let guestText: String
        // event.guestCount is non-optional Int in your model; handle accordingly
        if event.guestCount > 0 {
            guestText = "Guests: \(event.guestCount) Registered Attendees"
        } else {
            guestText = "Guests: —"
        }
        headerGuestLabel.text = guestText
    }

    private func composedDateString(startISO: String, endISO: String) -> String {
        // Try ISO8601 (with time) first, then yyyy-MM-dd, then fallback to raw
        let iso = ISO8601DateFormatter()
        let dfShort = DateFormatter()
        dfShort.dateStyle = .medium
        dfShort.timeStyle = .short

        // helper parse attempts:
        func parseDate(_ s: String) -> Date? {
            if s.isEmpty { return nil }
            if let d = iso.date(from: s) { return d }
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd"
            df.timeZone = TimeZone(secondsFromGMT: 0)
            if let d = df.date(from: s) { return d }
            return nil
        }

        if let s = parseDate(startISO), let e = parseDate(endISO) {
            if Calendar.current.isDate(s, inSameDayAs: e) {
                return dfShort.string(from: s)
            } else {
                return "\(dfShort.string(from: s)) - \(dfShort.string(from: e))"
            }
        } else if let s = parseDate(startISO) {
            return dfShort.string(from: s)
        } else if !startISO.isEmpty || !endISO.isEmpty {
            return "\(startISO) \(endISO)"
        } else {
            return "Date not set"
        }
    }
}


import UIKit

final class EventOverviewViewController: UIViewController {

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    private var event: EventRecord

    // Data
    private var cartItems: [CartItemRecord] = []
    private var inhouseItems: [CartItemRecord] = []
    private var outsourceItems: [CartItemRecord] = []
    private var totalAmount: Double = 0.0          // ✅ Cart Total (Client Budget)
    private var receivedAmount: Double = 0.0       // ✅ Payments received
    private var totalExpenses: Double = 0.0        // ✅ Expenses (Budget Entries)

    // Header UI
    private let headerCard = UIView()
    private let headerClientLabel = UILabel()
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
        setupHeaderCard()

        // ✅ 1. Load cached overview instantly
        if let cached = EventOverviewStore.shared.load(eventId: event.id) {
            self.cartItems = cached.cartItems
            self.receivedAmount = cached.receivedAmount
            self.totalExpenses = cached.totalExpenses

            computeFromCart()
            updateHeaderContent()
            buildAllSections()
        }

        // ✅ 2. Sync in background
        Task { await refreshFromServer() }
    }

    // MARK: - NAV
    private func setupNav() {
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

    // MARK: - SCROLLVIEW
    private func setupScroll() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
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

    // MARK: - HEADER CARD
    private func setupHeaderCard() {
        headerCard.backgroundColor = .white
        headerCard.layer.cornerRadius = 14
        headerCard.layer.shadowColor = UIColor.black.cgColor
        headerCard.layer.shadowOpacity = 0.06
        headerCard.layer.shadowRadius = 8
        headerCard.layer.shadowOffset = CGSize(width: 0, height: 6)

        headerClientLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        headerClientLabel.numberOfLines = 2

        headerDateLabel.font = .systemFont(ofSize: 13)
        headerDateLabel.textColor = .secondaryLabel

        headerLocationLabel.font = .systemFont(ofSize: 13)
        headerLocationLabel.textColor = .secondaryLabel

        headerGuestLabel.font = .systemFont(ofSize: 13)
        headerGuestLabel.textColor = .secondaryLabel

        [headerClientLabel, headerDateLabel, headerLocationLabel, headerGuestLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            headerCard.addSubview($0)
        }

        NSLayoutConstraint.activate([
            headerClientLabel.topAnchor.constraint(equalTo: headerCard.topAnchor, constant: 16),
            headerClientLabel.leadingAnchor.constraint(equalTo: headerCard.leadingAnchor, constant: 16),
            headerClientLabel.trailingAnchor.constraint(equalTo: headerCard.trailingAnchor, constant: -16),

            headerDateLabel.topAnchor.constraint(equalTo: headerClientLabel.bottomAnchor, constant: 10),
            headerDateLabel.leadingAnchor.constraint(equalTo: headerCard.leadingAnchor, constant: 16),

            headerLocationLabel.topAnchor.constraint(equalTo: headerDateLabel.bottomAnchor, constant: 10),
            headerLocationLabel.leadingAnchor.constraint(equalTo: headerCard.leadingAnchor, constant: 16),

            headerGuestLabel.topAnchor.constraint(equalTo: headerLocationLabel.bottomAnchor, constant: 10),
            headerGuestLabel.leadingAnchor.constraint(equalTo: headerCard.leadingAnchor, constant: 16),
            headerGuestLabel.bottomAnchor.constraint(equalTo: headerCard.bottomAnchor, constant: -16)
        ])

        contentStack.addArrangedSubview(headerCard)
    }

    // MARK: - LOAD ALL DATA
    @MainActor
    private func refreshFromServer() async {
        do {
            let cart = try await EventDataManager.shared.fetchCartItems(eventId: event.id)
            let payments = try await EventDataManager.shared.fetchPayments(eventId: event.id)
            let expenses = try await EventDataManager.shared.fetchBudgetEntries(eventId: event.id)

            let received = payments.reduce(0) { $0 + $1.amount }
            let spent = expenses.reduce(0) { $0 + $1.amount }

            let overview = EventOverviewCache(
                eventId: event.id,
                cartItems: cart,
                receivedAmount: received,
                totalExpenses: spent
            )

            // ✅ Save to cache
            EventOverviewStore.shared.save(overview)

            await MainActor.run {
                self.cartItems = cart
                self.receivedAmount = received
                self.totalExpenses = spent

                self.computeFromCart()
                self.updateHeaderContent()
                self.buildAllSections()
            }

        } catch {
            print("⚠️ Overview sync failed (offline?):", error)
            // ❌ Keep cached UI
        }
    }

    // MARK: - CART COMPUTATION
    private func sourceType(for item: CartItemRecord) -> String {
        if let s = item.sourceType, !s.isEmpty { return s.lowercased() }
        return "in_house"
    }

    private func lineTotal(for item: CartItemRecord) -> Double {
        item.lineTotal ?? ((item.rate ?? 0) * Double(item.quantity ?? 0))
    }

    private func computeFromCart() {
        inhouseItems = cartItems.filter { sourceType(for: $0) != "outsource" }
        outsourceItems = cartItems.filter { sourceType(for: $0) == "outsource" }

        // ✅ CLIENT BUDGET = CART TOTAL
        totalAmount = cartItems.reduce(0) { $0 + lineTotal(for: $1) }
    }

    // MARK: - BUILD UI SECTIONS
    private func buildAllSections() {
        contentStack.arrangedSubviews.dropFirst().forEach { $0.removeFromSuperview() }

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

    // ✅ FIXED BUDGET CHECK-IN LOGIC
    private func addBudgetCheckIn() {
        let cartTotal = totalAmount          // ✅ Client Budget
        let spent = totalExpenses            // ✅ Expenses
        let subtitle = "Spent ₹\(formatMoney(spent)) of ₹\(formatMoney(cartTotal))"
        let progress: Float = cartTotal > 0 ? Float(spent / cartTotal) : 0

        let card = EventSectionCard(
            iconName: "indianrupeesign.circle",
            title: "Budget Check-in",
            subtitle: subtitle,
            progress: progress
        ) { [weak self] in
            guard let self else { return }

            EventDataManager.shared.currentEventId = self.event.id
            let vc = BudgetDetailViewController()
            self.navigationController?.pushViewController(vc, animated: true)
        }

        contentStack.addArrangedSubview(card)
    }

    // ✅ PAYMENT STATUS (CORRECT LOGIC)
    private func addPaymentStatus() {
        let percent = totalAmount > 0 ? (receivedAmount / totalAmount) : 0
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
            subtitle: "Track items & usage",
            progress: 0
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
        return Float(done / Double(total))
    }

    private func formatMoney(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: value)) ?? "0"
    }

    // MARK: - HEADER CONTENT
    private func updateHeaderContent() {
        let client = event.clientName.trimmingCharacters(in: .whitespacesAndNewlines)
        headerClientLabel.text = !client.isEmpty ? client : event.eventName

        headerDateLabel.text = composedDateString(startISO: event.startDate, endISO: event.endDate)

        let loc = event.location.trimmingCharacters(in: .whitespacesAndNewlines)
        headerLocationLabel.text = !loc.isEmpty ? "Location: \(loc)" : "Location: —"

        headerGuestLabel.text = event.guestCount > 0 ? "Guests: \(event.guestCount)" : "Guests: —"
    }

    private func composedDateString(startISO: String, endISO: String) -> String {
        let iso = ISO8601DateFormatter()
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short

        func parse(_ s: String) -> Date? {
            iso.date(from: s)
        }

        if let s = parse(startISO), let e = parse(endISO) {
            return Calendar.current.isDate(s, inSameDayAs: e)
                ? df.string(from: s)
                : "\(df.string(from: s)) - \(df.string(from: e))"
        }

        return startISO.isEmpty ? "Date not set" : startISO
    }
}


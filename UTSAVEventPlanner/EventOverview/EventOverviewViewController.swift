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
    private var totalExpenses: Double = 0.0

    // Header UI
    private let headerCard = UIView()
    private let headerClientLabel = UILabel()

    private let headerDateIcon = UIImageView()
    private let headerDateLabel = UILabel()

    private let headerLocationIcon = UIImageView()
    private let headerLocationLabel = UILabel()

    private let headerGuestIcon = UIImageView()
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

        if let cached = EventOverviewStore.shared.load(eventId: event.id) {
            self.cartItems = cached.cartItems
            self.receivedAmount = cached.receivedAmount
            self.totalExpenses = cached.totalExpenses

            computeFromCart()
            updateHeaderContent()
            buildAllSections()
        }

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

    // MARK: - HEADER CARD (UPDATED WITH ICONS)
    private func setupHeaderCard() {
        headerCard.backgroundColor = .white
        headerCard.layer.cornerRadius = 14
        headerCard.layer.shadowColor = UIColor.black.cgColor
        headerCard.layer.shadowOpacity = 0.06
        headerCard.layer.shadowRadius = 8
        headerCard.layer.shadowOffset = CGSize(width: 0, height: 6)

        headerClientLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        headerClientLabel.numberOfLines = 2

        func setupIcon(_ icon: UIImageView, name: String) {
            icon.image = UIImage(systemName: name)
            icon.tintColor = .secondaryLabel
            icon.contentMode = .scaleAspectFit
            icon.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                icon.widthAnchor.constraint(equalToConstant: 16),
                icon.heightAnchor.constraint(equalToConstant: 16)
            ])
        }

        setupIcon(headerDateIcon, name: "calendar")
        setupIcon(headerLocationIcon, name: "location.fill")
        setupIcon(headerGuestIcon, name: "person.2")

        [headerDateLabel, headerLocationLabel, headerGuestLabel].forEach {
            $0.font = .systemFont(ofSize: 13)
            $0.textColor = .secondaryLabel
        }

        let dateRow = UIStackView(arrangedSubviews: [headerDateIcon, headerDateLabel])
        dateRow.axis = .horizontal
        dateRow.spacing = 6

        let locationRow = UIStackView(arrangedSubviews: [headerLocationIcon, headerLocationLabel])
        locationRow.axis = .horizontal
        locationRow.spacing = 6

        let guestRow = UIStackView(arrangedSubviews: [headerGuestIcon, headerGuestLabel])
        guestRow.axis = .horizontal
        guestRow.spacing = 6

        let infoStack = UIStackView(arrangedSubviews: [
            headerClientLabel,
            dateRow,
            locationRow,
            guestRow
        ])
        infoStack.axis = .vertical
        infoStack.spacing = 8
        infoStack.translatesAutoresizingMaskIntoConstraints = false

        headerCard.addSubview(infoStack)

        NSLayoutConstraint.activate([
            infoStack.topAnchor.constraint(equalTo: headerCard.topAnchor, constant: 16),
            infoStack.leadingAnchor.constraint(equalTo: headerCard.leadingAnchor, constant: 16),
            infoStack.trailingAnchor.constraint(equalTo: headerCard.trailingAnchor, constant: -16),
            infoStack.bottomAnchor.constraint(equalTo: headerCard.bottomAnchor, constant: -16)
        ])

        contentStack.addArrangedSubview(headerCard)
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
        totalAmount = cartItems.reduce(0) { $0 + lineTotal(for: $1) }
    }

    // MARK: - HEADER CONTENT (UPDATED)
    private func updateHeaderContent() {
        let client = event.clientName.trimmingCharacters(in: .whitespacesAndNewlines)
        headerClientLabel.text = !client.isEmpty ? client : event.eventName

        headerDateLabel.text = composedDateString(startISO: event.startDate, endISO: event.endDate)

        let loc = event.location.trimmingCharacters(in: .whitespacesAndNewlines)
        headerLocationLabel.text = !loc.isEmpty ? loc : "—"

        headerGuestLabel.text = event.guestCount > 0 ? "\(event.guestCount)" : "—"
    }

    // ✅ DATE FORMAT CHANGED TO dd/MM/yyyy
    private func composedDateString(startISO: String, endISO: String) -> String {

        func parseDate(_ value: String) -> Date? {
            // 1️⃣ Try ISO8601
            let isoFormatter = ISO8601DateFormatter()
            if let date = isoFormatter.date(from: value) {
                return date
            }

            // 2️⃣ Try simple yyyy-MM-dd (your current format)
            let simpleFormatter = DateFormatter()
            simpleFormatter.dateFormat = "yyyy-MM-dd"
            simpleFormatter.locale = Locale(identifier: "en_US_POSIX")
            if let date = simpleFormatter.date(from: value) {
                return date
            }

            // 3️⃣ Try full timestamp format
            let fullFormatter = DateFormatter()
            fullFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            fullFormatter.locale = Locale(identifier: "en_US_POSIX")
            return fullFormatter.date(from: value)
        }

        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "dd/MM/yyyy"

        guard let startDate = parseDate(startISO) else {
            return "Date not set"
        }

        if let endDate = parseDate(endISO) {
            if Calendar.current.isDate(startDate, inSameDayAs: endDate) {
                return outputFormatter.string(from: startDate)
            } else {
                return "\(outputFormatter.string(from: startDate)) - \(outputFormatter.string(from: endDate))"
            }
        }

        return outputFormatter.string(from: startDate)
    }

    // MARK: - LOAD SERVER DATA (UNCHANGED)
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

            EventOverviewStore.shared.save(overview)

            self.cartItems = cart
            self.receivedAmount = received
            self.totalExpenses = spent

            computeFromCart()
            updateHeaderContent()
            buildAllSections()

        } catch {
            print("⚠️ Overview sync failed:", error)
        }
    }

    // MARK: - UI SECTIONS (UNCHANGED)
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

    private func addBudgetCheckIn() {
        let subtitle = "Spent ₹\(formatMoney(totalExpenses)) of ₹\(formatMoney(totalAmount))"
        let progress: Float = totalAmount > 0 ? Float(totalExpenses / totalAmount) : 0

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
}


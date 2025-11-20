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

        Task { await loadCartAndPayments() }
    }

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

    // -----------------------------
    // MARK: SCROLLVIEW SETUP (fix taps)
    // -----------------------------
    private func setupScroll() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        // ❗Critical fixes for instant taps:
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
    // MARK: LOAD DATA
    // -----------------------------
    @MainActor
    private func loadCartAndPayments() async {
        do {
            cartItems = try await EventDataManager.shared.fetchCartItems(eventId: event.id)
            receivedAmount = try await EventDataManager.shared.fetchPayments(eventId: event.id)
                .reduce(0.0, { $0 + $1.amount })
        } catch {
            print("Error loading:", error)
        }

        computeFromCart()
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
        contentStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

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
        ) {}

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
}


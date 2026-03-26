import UIKit

final class PaymentsEventsListViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .plain)

    // MARK: - Scroll Reporting
    var onScroll: ((CGFloat) -> Void)?

    // 🔵 Pull-to-refresh control
    private let refreshControl = UIRefreshControl()

    // MARK: - Data
    private var allEvents: [EventRecord] = []
    private var filteredEvents: [EventRecord] = []
    private var isSearching = false

    // store per-event totals
    private var eventPayments: [String: (total: Double, remaining: Double)] = [:]

    private let emptyLabel: UILabel = {
        let l = UILabel()
        l.text = "No events found.\nCreate an event to start adding payments."
        l.numberOfLines = 0
        l.textAlignment = .center
        l.font = UIFont.preferredFont(forTextStyle: .body)
        l.textColor = .secondaryLabel
        return l
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        applyBrandGradient()
        setupTable()
        setupKeyboardDismissTap()

        // show spinner during first load
        refreshControl.beginRefreshing()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(paymentDidChange),
            name: Notification.Name("ReloadPaymentsList"),
            object: nil
        )

        Task {
            await refreshEvents(force: true)
            await MainActor.run {
                self.refreshControl.endRefreshing()
            }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func paymentDidChange() {
        Task {
            await refreshEvents(force: true)
        }
    }

    // MARK: - Pull to Refresh
    @objc private func handlePullToRefresh() {
        Task {
            await refreshEvents(force: true)

            await MainActor.run {
                self.refreshControl.endRefreshing()
            }
        }
    }

    // MARK: - Refresh Events
    func refreshEvents(force: Bool = false) async {

        if !force && PaymentsEventStore.shared.hasCache {

            allEvents = PaymentsEventStore.shared.cachedEvents
            filteredEvents = allEvents

            await computeEventSummaries()

            await MainActor.run {
                tableView.reloadData()
                updateEmptyState()
            }

            return
        }

        do {

            let fetched = try await EventSupabaseManager.shared.fetchAllEventsForUser()

            PaymentsEventStore.shared.set(fetched)

            allEvents = fetched
            filteredEvents = fetched

            await computeEventSummaries()

            await MainActor.run {
                tableView.reloadData()
                updateEmptyState()
            }

        } catch {
            print("❌ Payments refresh error:", error)
        }
    }

    // MARK: - Totals Calculation
    // MARK: - Totals Calculation
    private func computeEventSummaries() async {

        guard !allEvents.isEmpty else { return }

        let eventIds = allEvents.map { $0.id }

        do {

            // Try fetching from API
            async let cartItemsTask = EventDataManager.shared.fetchCartItemsForEvents(eventIds: eventIds)
            async let paymentsTask = PaymentSupabaseManager.shared.fetchPaymentsForEvents(eventIds: eventIds)

            let cartItems = try await cartItemsTask
            let payments = try await paymentsTask

            // Save to cache for offline use
            CartItemsStore.shared.set(cartItems)
            PaymentsStore.shared.set(payments)

            calculateTotals(cartItems: cartItems, payments: payments)

        } catch {

            print("⚠️ Offline mode → using cached totals")

            let cartItems = CartItemsStore.shared.cachedItems
            let payments = PaymentsStore.shared.cachedPayments

            calculateTotals(cartItems: cartItems, payments: payments)
        }
    }
    private func calculateTotals(cartItems: [CartItemRecord], payments: [PaymentRecord]) {

        let cartsByEvent = Dictionary(grouping: cartItems) { $0.eventId ?? "" }
        let paymentsByEvent = Dictionary(grouping: payments) { $0.event_id ?? "" }

        var map: [String:(Double,Double)] = [:]

        for event in allEvents {

            let carts = cartsByEvent[event.id] ?? []
            let pays = paymentsByEvent[event.id] ?? []

            let total = carts.reduce(0.0) {
                $0 + ($1.lineTotal ?? (Double($1.quantity ?? 0) * ($1.rate ?? 0)))
            }

            let received = pays.reduce(0.0) { $0 + $1.amount }

            let remaining = max(0, total - received)

            map[event.id] = (total, remaining)
        }

        eventPayments = map
    }
    // MARK: - UI Setup
    private func setupTable() {

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(EventPaymentCardCell.self, forCellReuseIdentifier: "EventPaymentCardCell")
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 140
        tableView.keyboardDismissMode = .onDrag
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .clear

        // 🔵 Attach refresh control
        refreshControl.addTarget(
            self,
            action: #selector(handlePullToRefresh),
            for: .valueChanged
        )

        tableView.refreshControl = refreshControl

        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func updateEmptyState() {
        let source = isSearching ? filteredEvents : allEvents
        tableView.backgroundView = source.isEmpty ? emptyLabel : nil
    }

    private func setupKeyboardDismissTap() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}

// MARK: - Search
extension PaymentsEventsListViewController: EventSearchable {

    func updateSearch(text: String) {

        let query = text.trimmingCharacters(in: .whitespacesAndNewlines)

        if query.isEmpty {
            isSearching = false
            filteredEvents = allEvents
        } else {
            isSearching = true
            filteredEvents = allEvents.filter {
                $0.eventName.localizedCaseInsensitiveContains(query) ||
                $0.clientName.localizedCaseInsensitiveContains(query)
            }
        }

        tableView.reloadData()
        updateEmptyState()
    }
}

// MARK: - TableView
extension PaymentsEventsListViewController: UITableViewDataSource, UITableViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        onScroll?(scrollView.contentOffset.y)
    }

    func tableView(_ t: UITableView, numberOfRowsInSection section: Int) -> Int {
        (isSearching ? filteredEvents : allEvents).count
    }

    func tableView(_ t: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let list = isSearching ? filteredEvents : allEvents
        let record = list[indexPath.row]

        let cell = t.dequeueReusableCell(
            withIdentifier: "EventPaymentCardCell",
            for: indexPath
        ) as! EventPaymentCardCell

        let summary = eventPayments[record.id]

        cell.configure(
            with: record,
            total: summary?.total,
            remaining: summary?.remaining
        )

        return cell
    }

    func tableView(_ t: UITableView, didSelectRowAt indexPath: IndexPath) {

        t.deselectRow(at: indexPath, animated: true)

        let list = isSearching ? filteredEvents : allEvents
        let vc = PaymentListViewController(event: list[indexPath.row])

        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
}

import UIKit

final class PaymentsEventsListViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .plain)

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
        view.backgroundColor = .clear
        setupTable()
        setupKeyboardDismissTap()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(paymentDidChange),
            name: Notification.Name("ReloadPaymentsList"),
            object: nil
        )

        Task { await refreshEvents(force: true) }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func paymentDidChange() {
        Task { await refreshEvents(force: true) }
    }

    // MARK: - Refresh
    func refreshEvents(force: Bool = false) async {
        do {
            let fetched = try await EventSupabaseManager.shared.fetchAllEventsForUser()
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

    // MARK: - Totals
    private func computeEventSummaries() async {
        var map: [String: (Double, Double)] = [:]

        await withTaskGroup(of: (String, Double, Double).self) { group in
            for event in allEvents {
                group.addTask {
                    var total = 0.0
                    var received = 0.0

                    let cart = try? await EventDataManager.shared.fetchCartItems(eventId: event.id)
                    total = cart?.reduce(0) {
                        $0 + (($1.lineTotal) ?? (Double($1.quantity ?? 0) * ($1.rate ?? 0)))
                    } ?? 0

                    let payments = try? await PaymentSupabaseManager.shared.fetchPayments(eventId: event.id)
                    received = payments?.reduce(0) { $0 + $1.amount } ?? 0

                    return (event.id, total, max(0, total - received))
                }
            }

            for await (id, total, remaining) in group {
                map[id] = (total, remaining)
            }
        }

        eventPayments = map
    }

    // MARK: - UI
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

// MARK: - Table
extension PaymentsEventsListViewController: UITableViewDataSource, UITableViewDelegate {

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
        cell.configure(with: record, total: summary?.total, remaining: summary?.remaining)
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


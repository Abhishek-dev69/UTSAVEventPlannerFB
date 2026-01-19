import UIKit

final class PaymentsEventsListViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .plain)
    private var events: [EventRecord] = []

    // store per-event totals (eventId -> (total, remaining))
    private var eventPayments: [String: (total: Double, remaining: Double)] = [:]

    // MARK: - 🔥 CACHE CONTROL
    private var hasLoadedOnce = false
    private var lastFetchTime: Date?
    private let refreshCooldown: TimeInterval = 60 // seconds

    // Empty state label
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
        navigationItem.title = "All Events Payments Track"

        setupTable()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(paymentDidChange),
            name: Notification.Name("ReloadPaymentsList"),
            object: nil
        )

        // ✅ First load must hit DB
        Task { await refreshEvents(force: true) }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    @objc private func paymentDidChange() {
        Task {
            // 🔥 Force recompute even if cached
            await refreshEvents(force: true)
        }
    }

    // MARK: - Public refresh API
    // Called by PaymentsRootController or pull-to-refresh
    func refreshEvents(force: Bool = false) async {

        // ✅ Prevent unnecessary DB calls
        if !force,
           hasLoadedOnce,
           let last = lastFetchTime,
           Date().timeIntervalSince(last) < refreshCooldown {
            return
        }

        do {
            let fetched = try await EventSupabaseManager.shared.fetchAllEventsForUser()

            events = fetched

            // compute per-event totals concurrently
            await computeEventSummaries()

            hasLoadedOnce = true
            lastFetchTime = Date()

            await MainActor.run {
                tableView.reloadData()
                updateEmptyState()
                tableView.refreshControl?.endRefreshing()
            }
        } catch {
            print("❌ PaymentsEventsListViewController.refreshEvents error:", error)
            await MainActor.run {
                tableView.refreshControl?.endRefreshing()
                updateEmptyState()
            }
        }
    }

    // MARK: - Compute totals
    @MainActor
    private func computeEventSummaries() async {
        var map: [String: (Double, Double)] = [:]

        await withTaskGroup(of: (String, Double, Double).self) { group in
            for event in events {
                group.addTask {
                    var totalAmount: Double = 0.0
                    do {
                        let cart = try await EventDataManager.shared.fetchCartItems(eventId: event.id)
                        totalAmount = cart.reduce(0.0) { acc, c in
                            if let lt = c.lineTotal { return acc + lt }
                            let r = c.rate ?? 0
                            let q = Double(c.quantity ?? 0)
                            return acc + (r * q)
                        }
                    } catch {
                        totalAmount = 0.0
                    }

                    var receivedAmount: Double = 0.0
                    do {
                        let payments = try await PaymentSupabaseManager.shared.fetchPayments(eventId: event.id)
                        receivedAmount = payments.reduce(0.0) { $0 + $1.amount }
                    } catch {
                        receivedAmount = 0.0
                    }

                    let remaining = max(0.0, totalAmount - receivedAmount)
                    return (event.id, totalAmount, remaining)
                }
            }

            for await (id, total, remaining) in group {
                map[id] = (total, remaining)
            }
        }

        eventPayments = map
    }

    // MARK: - Table setup
    private func setupTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(EventPaymentCardCell.self, forCellReuseIdentifier: "EventPaymentCardCell")
        tableView.separatorStyle = .none
        tableView.contentInset.bottom = 120


        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 140

        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .clear

        let rc = UIRefreshControl()
        rc.addTarget(self, action: #selector(pullToRefresh(_:)), for: .valueChanged)
        tableView.refreshControl = rc

        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        updateEmptyState()
    }

    // MARK: - Pull to refresh (FORCED)
    @objc private func pullToRefresh(_ sender: UIRefreshControl) {
        Task {
            await refreshEvents(force: true)
        }
    }

    private func updateEmptyState() {
        tableView.backgroundView = events.isEmpty ? emptyLabel : nil
    }
}

// MARK: - Table Delegate & DataSource
extension PaymentsEventsListViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ t: UITableView, numberOfRowsInSection section: Int) -> Int {
        events.count
    }

    func tableView(_ t: UITableView, didSelectRowAt indexPath: IndexPath) {
        t.deselectRow(at: indexPath, animated: true)

        guard indexPath.row < events.count else { return }

        let event = events[indexPath.row]
        let vc = PaymentListViewController(event: event)
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }

    func tableView(_ t: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard indexPath.row < events.count else {
            return UITableViewCell()
        }

        let cell = t.dequeueReusableCell(
            withIdentifier: "EventPaymentCardCell",
            for: indexPath
        ) as! EventPaymentCardCell

        let record = events[indexPath.row]
        if let s = eventPayments[record.id] {
            cell.configure(with: record, total: s.total, remaining: s.remaining)
        } else {
            cell.configure(with: record, total: nil, remaining: nil)
        }

        return cell
    }
}


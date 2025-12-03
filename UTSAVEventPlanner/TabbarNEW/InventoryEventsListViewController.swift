import UIKit

final class InventoryEventsListViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .plain)
    private var events: [EventRecord] = []

    // Empty state label shown as table background when no events
    private let emptyLabel: UILabel = {
        let l = UILabel()
        l.text = "No events found.\nCreate an event to start adding inventory."
        l.numberOfLines = 0
        l.textAlignment = .center
        l.font = UIFont.preferredFont(forTextStyle: .body)
        l.textColor = .secondaryLabel
        return l
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor(white: 0.97, alpha: 1)
        navigationItem.title = "Event Inventory Tracks"

        setupTable()

        // observe inventory count updates
        NotificationCenter.default.addObserver(self, selector: #selector(inventoryCountsUpdated(_:)), name: .inventoryCountsUpdated, object: nil)

        Task { await refreshEvents() }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // Public async refresh entry point (called by parent or pull-to-refresh)
    func refreshEvents() async {
        do {
            events = try await EventSupabaseManager.shared.fetchAllEventsForUser()

            await MainActor.run {
                tableView.reloadData()
                updateEmptyState()
                tableView.refreshControl?.endRefreshing()
            }

            // kick off background loads for events with missing counts
            for event in events {
                if InventoryManager.shared.cachedSentQuantity(forEventId: event.id) == nil ||
                    InventoryManager.shared.cachedReceivedQuantity(forEventId: event.id) == nil {
                    Task { await InventoryManager.shared.loadCounts(forEventId: event.id) }
                }
            }
        } catch {
            print("❌ Inventory refresh error:", error)
            await MainActor.run {
                tableView.refreshControl?.endRefreshing()
                updateEmptyState()
            }
        }
    }

    private func setupTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false

        // register the new simplified inventory card
        tableView.register(InventoryCardCell.self, forCellReuseIdentifier: "InventoryCardCell")

        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 120

        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .clear

        // Pull to refresh
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

    @objc private func pullToRefresh(_ sender: UIRefreshControl) {
        Task { await refreshEvents() }
    }

    private func updateEmptyState() {
        tableView.backgroundView = events.isEmpty ? emptyLabel : nil
    }

    @objc private func inventoryCountsUpdated(_ note: Notification) {
        guard let userInfo = note.userInfo,
              let eventId = userInfo["eventId"] as? String else { return }

        if let idx = events.firstIndex(where: { $0.id == eventId }) {
            Task { @MainActor in
                tableView.reloadRows(at: [IndexPath(row: idx, section: 0)], with: .none)
            }
        }
    }
}

extension InventoryEventsListViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ t: UITableView, numberOfRowsInSection section: Int) -> Int {
        events.count
    }

    func tableView(_ t: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard indexPath.row < events.count else { return UITableViewCell() }

        let cell = t.dequeueReusableCell(withIdentifier: "InventoryCardCell", for: indexPath) as! InventoryCardCell
        let record = events[indexPath.row]

        // try to read cached sent/received quantities
        let cachedSent = InventoryManager.shared.cachedSentQuantity(forEventId: record.id)
        let cachedReceived = InventoryManager.shared.cachedReceivedQuantity(forEventId: record.id)

        cell.configure(with: record, sentQuantity: cachedSent, receivedQuantity: cachedReceived)

        // kick off background load if either value is missing
        if cachedSent == nil || cachedReceived == nil {
            Task { await InventoryManager.shared.loadCounts(forEventId: record.id) }
        }

        return cell
    }

    func tableView(_ t: UITableView, didSelectRowAt indexPath: IndexPath) {
        t.deselectRow(at: indexPath, animated: true)

        guard indexPath.row < events.count else { return }
        let event = events[indexPath.row]

        let vc = InventoryOverviewViewController(event: event)
        vc.hidesBottomBarWhenPushed = true

        navigationController?.pushViewController(vc, animated: true)
    }
}


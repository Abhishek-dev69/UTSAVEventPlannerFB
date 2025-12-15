import UIKit

final class InventoryEventsListViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .plain)
    private var events: [EventRecord] = []

    // Empty state label
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

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(inventoryCountsUpdated(_:)),
            name: .inventoryCountsUpdated,
            object: nil
        )

        Task { await refreshEvents() }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Data

    func refreshEvents() async {
        do {
            events = try await EventSupabaseManager.shared.fetchAllEventsForUser()

            await MainActor.run {
                tableView.reloadData()
                updateEmptyState()
                tableView.refreshControl?.endRefreshing()
            }

            // Load inventory counts for all events
            for event in events {
                Task {
                    await InventoryManager.shared.loadCounts(forEventId: event.id)
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

    // MARK: - UI

    private func setupTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(InventoryCardCell.self, forCellReuseIdentifier: "InventoryCardCell")
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 120
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

    private func updateEmptyState() {
        tableView.backgroundView = events.isEmpty ? emptyLabel : nil
    }

    @objc private func pullToRefresh(_ sender: UIRefreshControl) {
        Task { await refreshEvents() }
    }

    // MARK: - Notification

    @objc private func inventoryCountsUpdated(_ note: Notification) {
        guard let eventId = note.userInfo?["eventId"] as? String else { return }

        if let index = events.firstIndex(where: { $0.id == eventId }) {
            Task { @MainActor in
                tableView.reloadRows(
                    at: [IndexPath(row: index, section: 0)],
                    with: .none
                )
            }
        }
    }
}

// MARK: - TableView
extension InventoryEventsListViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        events.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(
            withIdentifier: "InventoryCardCell",
            for: indexPath
        ) as! InventoryCardCell

        let event = events[indexPath.row]

        let allocated = InventoryManager.shared.allocated(for: event.id)
        let received = InventoryManager.shared.received(for: event.id)
        let lost = InventoryManager.shared.lost(for: event.id)

        cell.configure(
            event: event,
            allocated: allocated,
            received: received,
            lost: lost
        )

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let event = events[indexPath.row]
        let vc = InventoryOverviewViewController(event: event)
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
}


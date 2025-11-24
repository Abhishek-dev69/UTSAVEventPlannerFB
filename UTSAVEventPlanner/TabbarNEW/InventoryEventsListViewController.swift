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
    }

    // Public async refresh entry point (called by parent or pull-to-refresh)
    func refreshEvents() async {
        do {
            // Use the unified fetch used across app (dashboard) to avoid mismatches
            events = try await EventSupabaseManager.shared.fetchAllEventsForUser()

            await MainActor.run {
                tableView.reloadData()
                updateEmptyState()
                tableView.refreshControl?.endRefreshing()
            }
        } catch {
            // Keep logs helpful for diagnosing sync/fetch issues
            print("❌ Inventory refresh error:", error)

            await MainActor.run {
                tableView.refreshControl?.endRefreshing()
                // Optionally keep previous events shown, but update empty state anyway
                updateEmptyState()
            }
        }
    }

    private func setupTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false

        // Register card UI cell
        tableView.register(EventPaymentCardCell.self, forCellReuseIdentifier: "EventPaymentCardCell")

        tableView.separatorStyle = .none
        tableView.rowHeight = 82
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

        // initial empty background
        updateEmptyState()
    }

    @objc private func pullToRefresh(_ sender: UIRefreshControl) {
        Task {
            await refreshEvents()
        }
    }

    private func updateEmptyState() {
        if events.isEmpty {
            tableView.backgroundView = emptyLabel
        } else {
            tableView.backgroundView = nil
        }
    }
}

// MARK: - UITableViewDataSource / Delegate

extension InventoryEventsListViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ t: UITableView, numberOfRowsInSection section: Int) -> Int {
        events.count
    }

    func tableView(_ t: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard indexPath.row < events.count else {
            // Defensive: return an empty default cell if index out of bounds
            return UITableViewCell()
        }

        let cell = t.dequeueReusableCell(
            withIdentifier: "EventPaymentCardCell",
            for: indexPath
        ) as! EventPaymentCardCell

        let record = events[indexPath.row]
        cell.configure(with: record)
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


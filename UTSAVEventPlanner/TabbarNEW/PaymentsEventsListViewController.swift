import UIKit

final class PaymentsEventsListViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .plain)
    private var events: [EventRecord] = []

    // Empty state label shown as table background when no events
    private let emptyLabel: UILabel = {
        let l = UILabel()
        l.text = "No events found.\nCreate an event to start adding payments."
        l.numberOfLines = 0
        l.textAlignment = .center
        l.font = UIFont.preferredFont(forTextStyle: .body)
        l.textColor = .secondaryLabel
        return l
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor(white: 0.97, alpha: 1)
        navigationItem.title = "All Events Payments Tracks"

        setupTable()
    }

    // Called by PaymentsRootController or pull-to-refresh
    func refreshEvents() async {
        do {
            // Use unified fetch used across app (dashboard) to avoid mismatches
            events = try await EventSupabaseManager.shared.fetchAllEventsForUser()

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

    private func setupTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
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

extension PaymentsEventsListViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ t: UITableView, numberOfRowsInSection section: Int) -> Int {
        events.count
    }

    func tableView(_ t: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard indexPath.row < events.count else {
            return UITableViewCell()
        }

        let cell = t.dequeueReusableCell(withIdentifier: "EventPaymentCardCell", for: indexPath) as! EventPaymentCardCell
        let record = events[indexPath.row]
        cell.configure(with: record)
        return cell
    }

    func tableView(_ t: UITableView, didSelectRowAt indexPath: IndexPath) {
        t.deselectRow(at: indexPath, animated: true)

        guard indexPath.row < events.count else { return }

        let event = events[indexPath.row]
        let vc = PaymentListViewController(event: event)
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
}


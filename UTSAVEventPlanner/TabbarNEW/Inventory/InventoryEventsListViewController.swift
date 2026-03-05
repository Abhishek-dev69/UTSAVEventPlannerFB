import UIKit

final class InventoryEventsListViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .plain)

    // Loading spinner
    private let spinner = UIActivityIndicatorView(style: .large)

    private var events: [EventRecord] = []
    private var filteredEvents: [EventRecord] = []
    private var isSearching = false

    private let searchController = UISearchController(searchResultsController: nil)

    private let emptyLabel: UILabel = {
        let l = UILabel()
        l.text = "No events found.\nCreate an event to start adding inventory."
        l.numberOfLines = 0
        l.textAlignment = .center
        l.font = UIFont.preferredFont(forTextStyle: .body)
        l.textColor = .secondaryLabel
        return l
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor(white: 0.97, alpha: 1)
        navigationItem.title = "Inventory"

        setupSearch()
        setupTable()
        setupSpinner()
        setupKeyboardDismissTap()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(inventoryCountsUpdated(_:)),
            name: .inventoryCountsUpdated,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(inventoryUpdated(_:)),
            name: .inventoryUpdated,
            object: nil
        )

        Task { await refreshEvents() }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Spinner
    private func setupSpinner() {
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.hidesWhenStopped = true
        view.addSubview(spinner)

        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    // MARK: - Search
    private func setupSearch() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search events"
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }

    // MARK: - Refresh Events
    func refreshEvents() async {

        await MainActor.run {
            spinner.startAnimating()
        }

        do {

            events = try await EventSupabaseManager.shared.fetchAllEventsForUser()

            filteredEvents = events

            // ⚡ Load inventory counts in parallel
            await withTaskGroup(of: Void.self) { group in

                for event in events {

                    group.addTask {
                        await InventoryManager.shared.loadCounts(
                            forEventId: event.id
                        )
                    }
                }
            }

            await MainActor.run {

                spinner.stopAnimating()

                tableView.reloadData()
                updateEmptyState()
                tableView.refreshControl?.endRefreshing()
            }

        } catch {

            await MainActor.run {

                spinner.stopAnimating()
                tableView.refreshControl?.endRefreshing()
                updateEmptyState()
            }

            print("❌ Inventory refresh error:", error)
        }
    }

    // MARK: - Notifications

    @objc private func inventoryCountsUpdated(_ note: Notification) {

        guard let eventId = note.userInfo?["eventId"] as? String else {
            return
        }

        if let index = events.firstIndex(where: { $0.id == eventId }) {

            let indexPath = IndexPath(row: index, section: 0)

            DispatchQueue.main.async {
                if self.tableView.indexPathsForVisibleRows?.contains(indexPath) == true {
                    self.tableView.reloadRows(at: [indexPath], with: .none)
                }
            }
        }
    }

    @objc private func inventoryUpdated(_ note: Notification) {

        Task {
            await refreshEvents()
        }
    }

    // MARK: - UI Setup
    private func setupTable() {

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(
            InventoryCardCell.self,
            forCellReuseIdentifier: "InventoryCardCell"
        )

        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 120
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .clear
        tableView.keyboardDismissMode = .onDrag

        let rc = UIRefreshControl()
        rc.addTarget(self, action: #selector(pullToRefresh), for: .valueChanged)
        tableView.refreshControl = rc

        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func updateEmptyState() {
        let source = isSearching ? filteredEvents : events
        tableView.backgroundView = source.isEmpty ? emptyLabel : nil
    }

    @objc private func pullToRefresh() {
        Task { await refreshEvents() }
    }

    private func setupKeyboardDismissTap() {
        let tap = UITapGestureRecognizer(
            target: self,
            action: #selector(dismissKeyboard)
        )

        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc private func dismissKeyboard() {
        searchController.searchBar.resignFirstResponder()
    }
}

// MARK: - Search Delegate
extension InventoryEventsListViewController: UISearchResultsUpdating {

    func updateSearchResults(for searchController: UISearchController) {

        let text = searchController.searchBar.text ?? ""

        if text.isEmpty {

            isSearching = false
            filteredEvents = events

        } else {

            isSearching = true

            filteredEvents = events.filter {

                $0.eventName.localizedCaseInsensitiveContains(text) ||
                $0.clientName.localizedCaseInsensitiveContains(text)
            }
        }

        tableView.reloadData()
        updateEmptyState()
    }
}

// MARK: - TableView
extension InventoryEventsListViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ t: UITableView, numberOfRowsInSection section: Int) -> Int {
        (isSearching ? filteredEvents : events).count
    }

    func tableView(
        _ t: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {

        let list = isSearching ? filteredEvents : events
        let event = list[indexPath.row]

        let cell = t.dequeueReusableCell(
            withIdentifier: "InventoryCardCell",
            for: indexPath
        ) as! InventoryCardCell

        cell.configure(
            title: event.eventName,
            allocated: InventoryManager.shared.allocated(for: event.id),
            received: InventoryManager.shared.received(for: event.id),
            pending: InventoryManager.shared.notReceived(for: event.id),
            lost: InventoryManager.shared.lost(for: event.id)
        )

        return cell
    }

    func tableView(
        _ t: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {

        t.deselectRow(at: indexPath, animated: true)

        let list = isSearching ? filteredEvents : events

        let vc = InventoryOverviewViewController(
            event: list[indexPath.row]
        )

        vc.hidesBottomBarWhenPushed = true

        navigationController?.pushViewController(vc, animated: true)
    }
}

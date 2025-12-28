import UIKit

final class DashboardListViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .plain)

    // MARK: UI Elements
    private let avatar = UIImageView()
    private let titleLabel = UILabel()
    private let addButton = UIButton(type: .system)
    private let segments = UISegmentedControl(items: ["All", "Upcoming", "Completed"])

    // Empty State
    private let emptyStateView = UIView()
    private let emptyIcon = UIImageView()
    private let emptyLabel = UILabel()
    private let emptySubLabel = UILabel()

    private var allEvents: [EventRecord] = []
    private var events: [EventRecord] = []

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor(white: 0.97, alpha: 1)

        setupHeader()
        setupSegments()
        setupTable()
        setupEmptyState()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reloadEvents),
            name: NSNotification.Name("ReloadEventsDashboard"),
            object: nil
        )

        Task { await loadEvents() }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Header
    private func setupHeader() {
        avatar.image = UIImage(systemName: "person.circle")
        avatar.tintColor = .gray
        avatar.layer.cornerRadius = 22
        avatar.clipsToBounds = true
        avatar.translatesAutoresizingMaskIntoConstraints = false
        avatar.isUserInteractionEnabled = true
        avatar.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(profileTapped))
        )

        titleLabel.text = "Dashboard"
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let plusConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold)
        addButton.setImage(UIImage(systemName: "plus", withConfiguration: plusConfig), for: .normal)
        addButton.tintColor = UIColor(red: 136/255, green: 71/255, blue: 246/255, alpha: 1)
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.addTarget(self, action: #selector(addEventTapped), for: .touchUpInside)

        view.addSubview(avatar)
        view.addSubview(titleLabel)
        view.addSubview(addButton)

        NSLayoutConstraint.activate([
            avatar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            avatar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            avatar.widthAnchor.constraint(equalToConstant: 44),
            avatar.heightAnchor.constraint(equalToConstant: 44),

            titleLabel.centerYAnchor.constraint(equalTo: avatar.centerYAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            addButton.centerYAnchor.constraint(equalTo: avatar.centerYAnchor),
            addButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            addButton.widthAnchor.constraint(equalToConstant: 24),
            addButton.heightAnchor.constraint(equalToConstant: 24)
        ])
    }

    // MARK: - Segments
    private func setupSegments() {
        segments.selectedSegmentIndex = 0
        segments.selectedSegmentTintColor = UIColor(red: 136/255, green: 71/255, blue: 246/255, alpha: 1)
        segments.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        segments.setTitleTextAttributes([.foregroundColor: UIColor.gray], for: .normal)
        segments.translatesAutoresizingMaskIntoConstraints = false
        segments.addTarget(self, action: #selector(segmentedChanged), for: .valueChanged)

        view.addSubview(segments)

        NSLayoutConstraint.activate([
            segments.topAnchor.constraint(equalTo: avatar.bottomAnchor, constant: 16),
            segments.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segments.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            segments.heightAnchor.constraint(equalToConstant: 36)
        ])
    }

    // MARK: - Table
    private func setupTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        tableView.register(EventCardCell.self, forCellReuseIdentifier: "EventCardCell")
        tableView.dataSource = self
        tableView.delegate = self

        view.addSubview(tableView)
        let longPress = UILongPressGestureRecognizer(
            target: self,
            action: #selector(handleLongPress(_:))
        )
        tableView.addGestureRecognizer(longPress)


        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: segments.bottomAnchor, constant: 18),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    private func deleteEvent(_ event: EventRecord, at indexPath: IndexPath) async {

        do {
            try await EventSupabaseManager.shared.deleteEvent(eventId: event.id)

            await MainActor.run {

                // Remove locally
                self.allEvents.removeAll { $0.id == event.id }
                self.events.removeAll { $0.id == event.id }

                // Animate row deletion
                self.tableView.deleteRows(at: [indexPath], with: .automatic)

                self.updateEmptyState()

                // Notify others if needed
                NotificationCenter.default.post(
                    name: NSNotification.Name("ReloadEventsDashboard"),
                    object: nil
                )
            }

        } catch {
            print("❌ Delete failed:", error)

            await MainActor.run {
                let errAlert = UIAlertController(
                    title: "Error",
                    message: "Failed to delete event. Please try again.",
                    preferredStyle: .alert
                )
                errAlert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(errAlert, animated: true)
            }
        }
    }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {

        guard gesture.state == .began else { return }

        let point = gesture.location(in: tableView)
        guard let indexPath = tableView.indexPathForRow(at: point) else { return }

        let event = events[indexPath.row]

        let alert = UIAlertController(
            title: event.eventName,
            message: "Are you sure you want to delete this event?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        alert.addAction(
            UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
                guard let self = self else { return }
                Task {
                    await self.deleteEvent(event, at: indexPath)
                }
            }
        )

        present(alert, animated: true)
    }


    // MARK: - Empty State
    private func setupEmptyState() {
        emptyIcon.image = UIImage(systemName: "calendar.badge.plus")
        emptyIcon.tintColor = UIColor(red: 136/255, green: 71/255, blue: 246/255, alpha: 1)

        emptyLabel.text = "No Events Yet"
        emptyLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        emptyLabel.textColor = .darkGray

        emptySubLabel.text = "Tap + to create your first event"
        emptySubLabel.font = .systemFont(ofSize: 14)
        emptySubLabel.textColor = .gray

        let stack = UIStackView(arrangedSubviews: [emptyIcon, emptyLabel, emptySubLabel])
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false

        emptyStateView.addSubview(stack)
        emptyStateView.alpha = 0
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyStateView)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: emptyStateView.centerYAnchor),

            emptyStateView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func updateEmptyState() {
        let noEvents = events.isEmpty
        emptyStateView.alpha = noEvents ? 1 : 0
        tableView.alpha = noEvents ? 0 : 1
    }

    // MARK: - Data
    @objc private func reloadEvents() {
        Task { await loadEvents() }
    }

    private func loadEvents() async {
        do {
            let uid = try await EventSupabaseManager.shared.ensureUserId()
            let fetched = try await EventSupabaseManager.shared.fetchUserEvents(userId: uid)

            await MainActor.run {
                self.allEvents = fetched
                self.events = fetched
                self.tableView.reloadData()
                self.updateEmptyState()
            }
        } catch {
            print("Error loading events:", error)
        }
    }

    // MARK: - Actions
    @objc private func segmentedChanged() {
        events = allEvents
        tableView.reloadData()
    }

    @objc private func addEventTapped() {
        let vc = EventDetailsViewController()
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }

    @objc private func profileTapped() {
        navigationController?.setNavigationBarHidden(false, animated: true)
        navigationController?.pushViewController(ProfileViewController(), animated: true)
    }
}

// MARK: - Helpers (DB → UI Model)

private let dashboardDateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd"
    f.timeZone = .init(abbreviation: "UTC")
    return f
}()

private let dashboardCurrencyFormatter: NumberFormatter = {
    let nf = NumberFormatter()
    nf.numberStyle = .currency
    nf.currencyCode = "INR"
    nf.locale = Locale(identifier: "en_IN")
    nf.maximumFractionDigits = 0
    return nf
}()

private func parseDate(_ string: String) -> Date {
    dashboardDateFormatter.date(from: string) ?? Date()
}


// MARK: - Table Delegates
extension DashboardListViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        events.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "EventCardCell",
            for: indexPath
        ) as! EventCardCell
        cell.configure(with: events[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {

        tableView.deselectRow(at: indexPath, animated: true)

        let record = events[indexPath.row]
        EventSession.shared.currentEventId = record.id

        let servicesAdded = record.metadata?["servicesAdded"] == "true"

        if servicesAdded {
            // ✅ Event fully configured → Overview
            let vc = EventOverviewViewController(event: record)
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)

        } else {
            // ⏳ Setup pending → Confirmation

            let details = EventDetails(
                eventName: record.eventName,
                clientName: record.clientName,
                location: record.location,
                guestCount: record.guestCount,
                budgetInPaise: Int(record.budgetInPaise), // ✅ Int64 → Int
                startDate: parseDate(record.startDate),   // ✅ String → Date
                endDate: parseDate(record.endDate)
            )

            let vc = ConfirmationViewController(
                details: details,
                currencyFormatter: dashboardCurrencyFormatter,
                dateFormatter: dashboardDateFormatter,
                title: record.eventName
            )

            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}


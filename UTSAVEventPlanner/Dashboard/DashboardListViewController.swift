import UIKit

final class DashboardListViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .plain)

    // MARK: UI Elements
    private let avatar = UIImageView()
    private let titleLabel = UILabel()
    private let addButton = UIButton(type: .system)
    private let segments = UISegmentedControl(items: ["All Events", "Upcoming", "Completed"])

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

        NotificationCenter.default.addObserver(self,
            selector: #selector(reloadEvents),
            name: NSNotification.Name("ReloadEventsDashboard"),
            object: nil)

        Task { await loadEvents() }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    // MARK: Header
    private func setupHeader() {
        avatar.image = UIImage(systemName: "person.circle")
        avatar.tintColor = .gray
        avatar.layer.cornerRadius = 22
        avatar.clipsToBounds = true
        avatar.translatesAutoresizingMaskIntoConstraints = false
        avatar.isUserInteractionEnabled = true
        avatar.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(profileTapped)))

        titleLabel.text = "Dashboard"
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        addButton.setImage(UIImage(systemName: "plus"), for: .normal)
        addButton.tintColor = .white
        addButton.backgroundColor = UIColor(red: 136/255, green: 71/255, blue: 246/255, alpha: 1)
        addButton.layer.cornerRadius = 24
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
            addButton.widthAnchor.constraint(equalToConstant: 48),
            addButton.heightAnchor.constraint(equalToConstant: 48)
        ])

        // Pulse animation
        UIView.animate(withDuration: 1.3,
                       delay: 0,
                       options: [.repeat, .autoreverse],
                       animations: {
            self.addButton.transform = CGAffineTransform(scaleX: 1.08, y: 1.08)
        })
    }

    // MARK: Segments
    private func setupSegments() {
        segments.selectedSegmentIndex = 0
        segments.backgroundColor = .clear
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

    // MARK: Table
    private func setupTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        tableView.register(EventCardCell.self, forCellReuseIdentifier: "EventCardCell")
        tableView.dataSource = self
        tableView.delegate = self

        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: segments.bottomAnchor, constant: 18),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    // MARK: Empty State
    private func setupEmptyState() {
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        emptyIcon.translatesAutoresizingMaskIntoConstraints = false
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        emptySubLabel.translatesAutoresizingMaskIntoConstraints = false

        emptyIcon.image = UIImage(systemName: "calendar.badge.plus")
        emptyIcon.tintColor = UIColor(red: 136/255, green: 71/255, blue: 246/255, alpha: 1)

        emptyLabel.text = "No Events Yet"
        emptyLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        emptyLabel.textColor = .darkGray
        emptyLabel.textAlignment = .center

        emptySubLabel.text = "Tap + to create your first event"
        emptySubLabel.font = .systemFont(ofSize: 14)
        emptySubLabel.textColor = .gray
        emptySubLabel.textAlignment = .center

        emptyStateView.alpha = 0

        emptyStateView.addSubview(emptyIcon)
        emptyStateView.addSubview(emptyLabel)
        emptyStateView.addSubview(emptySubLabel)
        view.addSubview(emptyStateView)

        NSLayoutConstraint.activate([
            emptyStateView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            emptyIcon.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            emptyIcon.topAnchor.constraint(equalTo: emptyStateView.topAnchor),
            emptyIcon.widthAnchor.constraint(equalToConstant: 60),
            emptyIcon.heightAnchor.constraint(equalToConstant: 60),

            emptyLabel.topAnchor.constraint(equalTo: emptyIcon.bottomAnchor, constant: 12),
            emptyLabel.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),

            emptySubLabel.topAnchor.constraint(equalTo: emptyLabel.bottomAnchor, constant: 6),
            emptySubLabel.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            emptySubLabel.bottomAnchor.constraint(equalTo: emptyStateView.bottomAnchor)
        ])
    }

    private func updateEmptyState() {
        UIView.animate(withDuration: 0.3) {
            let noEvents = self.events.isEmpty
            self.emptyStateView.alpha = noEvents ? 1 : 0
            self.tableView.alpha = noEvents ? 0 : 1
        }
    }

    // MARK: Load Events
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

    // MARK: External Setter (Used by OnboardingWelcomeViewController)
    func setEvents(_ events: [EventRecord]) {
        self.allEvents = events
        self.events = events

        if isViewLoaded {
            tableView.reloadData()
            updateEmptyState()
        }
    }

    // MARK: Segments
    @objc private func segmentedChanged() {
        switch segments.selectedSegmentIndex {
        case 0: events = allEvents
        case 1: events = allEvents.filter { _ in true }    // placeholder
        case 2: events = allEvents.filter { _ in false }   // placeholder
        default: break
        }

        tableView.reloadData()
        updateEmptyState()
    }

    // MARK: Actions
    @objc private func addEventTapped() {
        let vc = EventTypeViewController()
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }

    @objc private func profileTapped() {
        navigationController?.setNavigationBarHidden(false, animated: true)
        navigationController?.pushViewController(ProfileViewController(), animated: true)
    }
}


// MARK: - Table Delegates
extension DashboardListViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ t: UITableView, numberOfRowsInSection section: Int) -> Int {
        events.count
    }

    func tableView(_ t: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = t.dequeueReusableCell(withIdentifier: "EventCardCell", for: indexPath) as! EventCardCell
        cell.configure(with: events[indexPath.row])
        return cell
    }

    func tableView(_ t: UITableView, didSelectRowAt indexPath: IndexPath) {
        t.deselectRow(at: indexPath, animated: true)

        let selectedEvent = events[indexPath.row]
        EventSession.shared.currentEventId = selectedEvent.id

        let vc = EventOverviewViewController(event: selectedEvent)
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
}


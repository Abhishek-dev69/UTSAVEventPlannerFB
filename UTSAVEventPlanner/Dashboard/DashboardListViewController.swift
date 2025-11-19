import UIKit

final class DashboardListViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .plain)

    // MARK: UI Elements
    private let avatar = UIImageView()
    private let titleLabel = UILabel()
    private let addButton = UIButton(type: .system)
    private let segments = UISegmentedControl(items: ["All Events", "Upcoming", "Completed"])

    private var allEvents: [EventRecord] = []
    private var events: [EventRecord] = []

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 0.97, alpha: 1)

        setupHeader()
        setupSegments()
        setupTable()

        NotificationCenter.default.addObserver(self, selector: #selector(reloadEvents), name: NSNotification.Name("ReloadEventsDashboard"), object: nil)

        Task { await loadEvents() }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // You previously hid nav bar here. Keep it hidden for the dashboard header
        // but ensure profile push will show the nav bar before pushing.
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: Header
    private func setupHeader() {
        avatar.image = UIImage(systemName: "person.circle")
        avatar.tintColor = .gray
        avatar.layer.cornerRadius = 22
        avatar.clipsToBounds = true
        avatar.translatesAutoresizingMaskIntoConstraints = false
        avatar.isUserInteractionEnabled = true // make it tappable

        // add tap gesture to open profile
        let tap = UITapGestureRecognizer(target: self, action: #selector(profileTapped))
        avatar.addGestureRecognizer(tap)

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
    }

    // MARK: Segmented Control
    private func setupSegments() {
        segments.selectedSegmentIndex = 0
        segments.backgroundColor = .clear
        segments.selectedSegmentTintColor = UIColor(red: 136/255, green: 71/255, blue: 246/255, alpha: 1)
        segments.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        segments.setTitleTextAttributes([.foregroundColor: UIColor.gray], for: .normal)

        segments.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(segments)

        segments.addTarget(self, action: #selector(segmentedChanged), for: .valueChanged)

        NSLayoutConstraint.activate([
            segments.topAnchor.constraint(equalTo: avatar.bottomAnchor, constant: 16),
            segments.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segments.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            segments.heightAnchor.constraint(equalToConstant: 36)
        ])
    }

    // MARK: TableView
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
            // anchor to safe area bottom so bottom controls / home indicator don't overlap
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    // MARK: Data Loading
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
            }
        } catch {
            print("Error loading events:", error)
        }
    }

    func setEvents(_ events: [EventRecord]) {
        self.allEvents = events
        self.events = events
        if isViewLoaded { tableView.reloadData() }
    }

    // MARK: Segmented Filtering
    @objc private func segmentedChanged() {
        switch segments.selectedSegmentIndex {
        case 0:
            events = allEvents
        case 1:
            // TODO: implement upcoming filter — requires EventRecord date field
            events = allEvents.filter { event in
                // placeholder: treat all as upcoming for now
                return true
            }
        case 2:
            // TODO: implement completed filter — requires EventRecord status field
            events = allEvents.filter { event in
                // placeholder: none completed
                return false
            }
        default:
            events = allEvents
        }
        tableView.reloadData()
    }

    // MARK: Add Event
    @objc private func addEventTapped() {
        let vc = EventTypeViewController()
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }

    // MARK: Profile Tap
    @objc private func profileTapped() {
        // Ensure navBar is visible on the pushed screen
        navigationController?.setNavigationBarHidden(false, animated: true)

        let vc = ProfileViewController()
        // prefer the profile screen to show the standard nav bar
        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - Table DataSource & Delegate
extension DashboardListViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ t: UITableView, numberOfRowsInSection section: Int) -> Int { events.count }

    func tableView(_ t: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = t.dequeueReusableCell(withIdentifier: "EventCardCell", for: indexPath) as! EventCardCell
        cell.configure(with: events[indexPath.row])
        return cell
    }

    func tableView(_ t: UITableView, didSelectRowAt indexPath: IndexPath) {
        t.deselectRow(at: indexPath, animated: true)
        let selectedEvent = events[indexPath.row]
        let vc = EventOverviewViewController(event: selectedEvent)

        EventSession.shared.currentEventId = selectedEvent.id

        if let nav = self.navigationController {
            vc.hidesBottomBarWhenPushed = true
            nav.pushViewController(vc, animated: true)
        } else {
            // fallback: present modally inside a nav controller
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true)
        }
    }
}


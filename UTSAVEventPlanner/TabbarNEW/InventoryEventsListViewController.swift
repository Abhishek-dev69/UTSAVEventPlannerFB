import UIKit

final class InventoryEventsListViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .plain)
    private var events: [EventRecord] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor(white: 0.97, alpha: 1)
        navigationItem.title = "Event Inventory Tracks"

        setupTable()
    }

    func refreshEvents() async {
        do {
            let uid = try await SupabaseManager.shared.ensureUserId()
            events = try await EventSupabaseManager.shared.fetchUserEvents(userId: uid)

            await MainActor.run {
                tableView.reloadData()
            }
        } catch {
            print("❌ Inventory refresh error:", error)
        }
    }

    private func setupTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "eventCell")
        tableView.separatorStyle = .none
        tableView.rowHeight = 82
        tableView.dataSource = self
        tableView.delegate = self

        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

extension InventoryEventsListViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ t: UITableView, numberOfRowsInSection section: Int) -> Int {
        events.count
    }

    func tableView(_ t: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let event = events[indexPath.row]
        let cell = t.dequeueReusableCell(withIdentifier: "eventCell", for: indexPath)

        cell.textLabel?.text = event.eventName
        cell.textLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        cell.accessoryType = .disclosureIndicator

        return cell
    }

    func tableView(_ t: UITableView, didSelectRowAt indexPath: IndexPath) {
        let event = events[indexPath.row]

        let vc = InventoryOverviewViewController(event: event)   // FIXED HERE
        vc.hidesBottomBarWhenPushed = true

        navigationController?.pushViewController(vc, animated: true)
    }
}


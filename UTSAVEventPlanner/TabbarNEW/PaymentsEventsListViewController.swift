import UIKit

final class PaymentsEventsListViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .plain)
    private var events: [EventRecord] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor(white: 0.97, alpha: 1)
        navigationItem.title = "All Events Payments Tracks"

        setupTable()
    }

    // Called by PaymentsRootController
    func refreshEvents() async {
        do {
            let uid = try await SupabaseManager.shared.ensureUserId()
            events = try await EventSupabaseManager.shared.fetchUserEvents(userId: uid)

            await MainActor.run {
                tableView.reloadData()
            }
        } catch {
            print("❌ Failed to refresh events:", error)
        }
    }

    private func setupTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(EventPaymentCardCell.self, forCellReuseIdentifier: "EventPaymentCardCell")
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

extension PaymentsEventsListViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ t: UITableView, numberOfRowsInSection section: Int) -> Int {
        return events.count
    }

    func tableView(_ t: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = t.dequeueReusableCell(withIdentifier: "EventPaymentCardCell", for: indexPath) as! EventPaymentCardCell
        cell.configure(with: events[indexPath.row])
        return cell
    }

    func tableView(_ t: UITableView, didSelectRowAt indexPath: IndexPath) {
        let event = events[indexPath.row]
        let vc = PaymentListViewController(event: event)
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
}


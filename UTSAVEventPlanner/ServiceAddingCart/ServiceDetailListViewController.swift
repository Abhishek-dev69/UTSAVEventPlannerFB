//
// ServiceDetailListViewController.swift
//

import UIKit

final class ServiceDetailListViewController: UIViewController {

    private let service: Service
    private var filteredSubservices: [Subservice]

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let searchField = UISearchBar()

    init(service: Service) {
        self.service = service
        self.filteredSubservices = service.subservices
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        title = service.name
        setupSearch()
        setupTable()
        CartManager.shared.addObserver(self)
    }

    deinit { CartManager.shared.removeObserver(self) }

    private func setupSearch() {
        searchField.placeholder = "Search \(service.name)..."
        searchField.delegate = self
        searchField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchField)

        NSLayoutConstraint.activate([
            searchField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchField.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchField.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    private func setupTable() {
        tableView.register(SubserviceCell.self, forCellReuseIdentifier: SubserviceCell.reuseID)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.estimatedRowHeight = 84
        tableView.rowHeight = UITableView.automaticDimension
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

extension ServiceDetailListViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filteredSubservices.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let sub = filteredSubservices[indexPath.row]
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SubserviceCell.reuseID, for: indexPath) as? SubserviceCell else {
            return UITableViewCell()
        }

        let existingQty = CartManager.shared.items.first(where: { $0.serviceName == service.name && $0.subserviceName == sub.name })?.quantity ?? 0

        cell.configure(parentService: service.name, sub: sub, initialQuantity: existingQty)

        // cell handles add itself; controller updates UI when cell signals
        cell.onAddTapped = { [weak self] in
            print("🟢 ServiceDetailVC → Add tapped for \(sub.name)")
            self?.tableView.reloadRows(at: [indexPath], with: .automatic)
        }

        cell.onQuantityChanged = { [weak self] _ in
            self?.tableView.reloadRows(at: [indexPath], with: .none)
        }

        return cell
    }
}

extension ServiceDetailListViewController: UITableViewDelegate {}

extension ServiceDetailListViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let term = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if term.isEmpty { filteredSubservices = service.subservices }
        else { filteredSubservices = service.subservices.filter { $0.name.localizedCaseInsensitiveContains(term) } }
        tableView.reloadData()
    }
}

extension ServiceDetailListViewController: CartObserver {
    func cartDidChange() { tableView.reloadData() }
}


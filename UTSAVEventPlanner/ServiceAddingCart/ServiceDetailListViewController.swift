//
//  ServiceDetailListViewController.swift
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
        view.backgroundColor = UIColor(white: 0.97, alpha: 1)
        title = service.name
        setupSearch()
        setupTable()
        CartManager.shared.addObserver(self)
    }

    deinit { CartManager.shared.removeObserver(self) }

    private func setupSearch() {
        searchField.placeholder = "Search \(service.name)…"
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
        tableView.estimatedRowHeight = 80
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

// MARK: - UITableViewDataSource
extension ServiceDetailListViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filteredSubservices.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let sub = filteredSubservices[indexPath.row]

        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: SubserviceCell.reuseID,
            for: indexPath
        ) as? SubserviceCell else {
            return UITableViewCell()
        }

        // FIX — service.id is optional in your model, unwrap safely
        guard let serviceId = service.id else {
            print("❌ ERROR: service.id is nil for service \(service.name)")
            return cell
        }

        // Load existing quantity from CartManager
        let existingQty = CartManager.shared.items.first(where: {
            $0.serviceName == service.name && $0.subserviceName == sub.name
        })?.quantity ?? 0

        // FIXED CONFIGURATION SIGNATURE
        cell.configure(
            parentServiceId: serviceId,
            parentService: service.name,
            sub: sub,
            quantity: existingQty
        )

        return cell
    }
}

// MARK: - UISearchBarDelegate
extension ServiceDetailListViewController: UISearchBarDelegate {

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let term = searchText.trimmed

        if term.isEmpty {
            filteredSubservices = service.subservices
        } else {
            filteredSubservices = service.subservices.filter {
                $0.name.localizedCaseInsensitiveContains(term)
            }
        }

        tableView.reloadData()
    }
}

// MARK: - TableView Delegate
extension ServiceDetailListViewController: UITableViewDelegate {}

// MARK: - Cart Observer
extension ServiceDetailListViewController: CartObserver {
    func cartDidChange() {
        tableView.reloadData()
    }
}

// MARK: - Helper
extension String {
    var trimmed: String {
        self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

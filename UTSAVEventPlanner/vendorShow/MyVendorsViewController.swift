//
// MyVendorsViewController.swift
// EventPlanner - My Vendors list (persistent + real vendor fetch)
//

import UIKit

final class MyVendorsViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let searchBar = UISearchBar()

    // runtime vendor records
    private var vendorRecords: [VendorRecord] = []
    private var filteredRecords: [VendorRecord] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "My Vendors"
        view.backgroundColor = .systemBackground

        setupSearchBar()
        setupTableView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadMyVendors()
    }

    private func setupSearchBar() {
        searchBar.placeholder = "Search vendors"
        searchBar.delegate = self
        searchBar.searchBarStyle = .minimal
        searchBar.sizeToFit()
    }

    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.tableHeaderView = searchBar
        tableView.rowHeight = 90

        tableView.register(MyVendorCell.self,
                           forCellReuseIdentifier: MyVendorCell.reuseIdentifier)

        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // Load vendor records for stored vendor IDs
    fileprivate func loadMyVendors() {
        let ids = MyVendorsStore.shared.allVendorIds()
        vendorRecords = []
        filteredRecords = []
        guard !ids.isEmpty else {
            tableView.reloadData()
            return
        }

        // fetch each vendor (concurrently)
        Task {
            await withTaskGroup(of: VendorRecord?.self) { group in
                for id in ids {
                    group.addTask {
                        return try? await VendorManager.shared.fetchVendorById(id)
                    }
                }

                var results: [VendorRecord] = []
                for await r in group {
                    if let v = r {
                        results.append(v)
                    }
                }

                // maintain order as stored in MyVendorsStore
                let idToVendor = Dictionary(uniqueKeysWithValues: results.map { ($0.id, $0) })
                let ordered = ids.compactMap { idToVendor[$0] }

                await MainActor.run {
                    self.vendorRecords = ordered
                    self.filteredRecords = ordered
                    self.tableView.reloadData()
                }
            }
        }
    }
}

// MARK: - UITableViewDataSource

extension MyVendorsViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredRecords.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: MyVendorCell.reuseIdentifier,
            for: indexPath
        ) as? MyVendorCell else {
            return UITableViewCell()
        }

        let vendor = filteredRecords[indexPath.row]
        cell.configure(with: vendor)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension MyVendorsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let vendor = filteredRecords[indexPath.row]
        // navigate to vendor detail screen
        let vc = VendorDetailViewController(vendorId: vendor.id)
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - Swipe to delete
    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
        -> UISwipeActionsConfiguration? {

        let vendor = filteredRecords[indexPath.row]

        let deleteAction = UIContextualAction(style: .destructive, title: "Remove") { [weak self] _, _, completion in
            guard let self = self else {
                completion(false)
                return
            }

            // 1) Remove from store
            MyVendorsStore.shared.remove(vendorId: vendor.id)

            // 2) Reload current list (preserves ordering)
            self.loadMyVendors()

            // optional: small UI feedback
            completion(true)
        }

        deleteAction.backgroundColor = .systemRed
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}

// MARK: - UISearchBarDelegate

extension MyVendorsViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            filteredRecords = vendorRecords
        } else {
            filteredRecords = vendorRecords.filter {
                ($0.fullName ?? $0.businessName ?? "").lowercased().contains(searchText.lowercased())
            }
        }
        tableView.reloadData()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

// MARK: - MyVendorCell (shows avatar + name)

final class MyVendorCell: UITableViewCell {

    static let reuseIdentifier = "MyVendorCell"

    private let cardView = UIView()
    private let nameLabel = UILabel()
    private let thumbnailImageView = UIImageView()
    private var imageTask: URLSessionDataTask?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        thumbnailImageView.image = nil
        imageTask?.cancel()
        imageTask = nil
    }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear

        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 12
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.08
        cardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        cardView.layer.shadowRadius = 4

        contentView.addSubview(cardView)

        thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false
        thumbnailImageView.contentMode = .scaleAspectFill
        thumbnailImageView.layer.cornerRadius = 10
        thumbnailImageView.clipsToBounds = true
        thumbnailImageView.backgroundColor = .secondarySystemBackground

        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        nameLabel.numberOfLines = 2

        cardView.addSubview(thumbnailImageView)
        cardView.addSubview(nameLabel)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            thumbnailImageView.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            thumbnailImageView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            thumbnailImageView.widthAnchor.constraint(equalToConstant: 60),
            thumbnailImageView.heightAnchor.constraint(equalToConstant: 60),

            nameLabel.leadingAnchor.constraint(equalTo: thumbnailImageView.trailingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            nameLabel.centerYAnchor.constraint(equalTo: cardView.centerYAnchor)
        ])
    }

    func configure(with vendor: VendorRecord) {
        nameLabel.text = vendor.fullName ?? vendor.businessName ?? "Vendor"
        thumbnailImageView.image = UIImage(systemName: "person.crop.circle.fill")
        if let urlStr = VendorManager.shared.resolvedAvatarURLString(for: vendor),
           let url = URL(string: urlStr) {
            // simple image load
            imageTask = URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                guard let data = data, let img = UIImage(data: data) else { return }
                DispatchQueue.main.async {
                    self?.thumbnailImageView.image = img
                }
            }
            imageTask?.resume()
        }
    }
}


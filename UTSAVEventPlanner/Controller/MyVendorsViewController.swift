import UIKit

final class MyVendorsViewController: UIViewController {

    struct Vendor {
        let name: String
        let imageName: String
    }

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let searchBar = UISearchBar()

    private var vendors: [Vendor] = [
        Vendor(name: "Event Decorators Inc.", imageName: "my_vendor_decor"),
        Vendor(name: "Catering Masters", imageName: "my_vendor_catering"),
        Vendor(name: "DJ Beats Unlimited", imageName: "my_vendor_dj"),
        Vendor(name: "Photography Experts", imageName: "my_vendor_photo"),
        Vendor(name: "Venue Solutions", imageName: "my_vendor_venue")
    ]

    private var filteredVendors: [Vendor] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "My Vendors"
        view.backgroundColor = .systemBackground

        filteredVendors = vendors

        setupSearchBar()
        setupTableView()
    }

    // MARK: - UI Setup

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
}

// MARK: - UITableViewDataSource

extension MyVendorsViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredVendors.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: MyVendorCell.reuseIdentifier,
            for: indexPath
        ) as? MyVendorCell else {
            return UITableViewCell()
        }

        cell.configure(with: filteredVendors[indexPath.row])
        return cell
    }
}

// MARK: - UITableViewDelegate

extension MyVendorsViewController: UITableViewDelegate {
    // Add didSelectRowAt here if you want navigation later
}

// MARK: - UISearchBarDelegate

extension MyVendorsViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            filteredVendors = vendors
        } else {
            filteredVendors = vendors.filter {
                $0.name.lowercased().contains(searchText.lowercased())
            }
        }
        tableView.reloadData()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

// MARK: - Simple Vendor Cell (no rating)

final class MyVendorCell: UITableViewCell {

    static let reuseIdentifier = "MyVendorCell"

    private let cardView = UIView()
    private let nameLabel = UILabel()
    private let thumbnailImageView = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
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

    func configure(with vendor: MyVendorsViewController.Vendor) {
        nameLabel.text = vendor.name
        thumbnailImageView.image = UIImage(named: vendor.imageName)
    }
}

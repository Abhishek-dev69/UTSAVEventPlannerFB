import UIKit

final class VendorMarketplaceViewController: UIViewController {

    struct Vendor {
        let name: String
        let category: String
        let rating: Double
        let imageName: String
    }

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let searchBar = UISearchBar()

    private var vendors: [Vendor] = [
        Vendor(name: "Cuisine Catering", category: "Catering", rating: 4.5, imageName: "vendor_catering"),
        Vendor(name: "Capture Moments Photography", category: "Photography", rating: 4.8, imageName: "vendor_photography"),
        Vendor(name: "Vikash Decoration", category: "Decoration", rating: 4.8, imageName: "vendor_decoration")
    ]

    private var filteredVendors: [Vendor] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Vendor Marketplace"
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
        tableView.rowHeight = 110

        tableView.register(VendorMarketplaceCell.self,
                           forCellReuseIdentifier: VendorMarketplaceCell.reuseIdentifier)

        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

// MARK: - UITableViewDataSource

extension VendorMarketplaceViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredVendors.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: VendorMarketplaceCell.reuseIdentifier,
            for: indexPath
        ) as? VendorMarketplaceCell else {
            return UITableViewCell()
        }

        cell.configure(with: filteredVendors[indexPath.row])
        return cell
    }
}

// MARK: - UITableViewDelegate

extension VendorMarketplaceViewController: UITableViewDelegate {
    // Add didSelectRowAt if you need navigation on tap later
}

// MARK: - UISearchBarDelegate

extension VendorMarketplaceViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            filteredVendors = vendors
        } else {
            filteredVendors = vendors.filter {
                $0.name.lowercased().contains(searchText.lowercased()) ||
                $0.category.lowercased().contains(searchText.lowercased())
            }
        }
        tableView.reloadData()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

// MARK: - Custom Cell with Rating

final class VendorMarketplaceCell: UITableViewCell {

    static let reuseIdentifier = "VendorMarketplaceCell"

    private let cardView = UIView()
    private let nameLabel = UILabel()
    private let categoryLabel = UILabel()
    private let thumbnailImageView = UIImageView()
    private let ratingContainerView = UIView()
    private let ratingLabel = UILabel()

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
        cardView.layer.shadowOpacity = 0.1
        cardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        cardView.layer.shadowRadius = 4

        contentView.addSubview(cardView)

        thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false
        thumbnailImageView.contentMode = .scaleAspectFill
        thumbnailImageView.layer.cornerRadius = 10
        thumbnailImageView.clipsToBounds = true

        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = UIFont.boldSystemFont(ofSize: 15)
        nameLabel.numberOfLines = 2

        categoryLabel.translatesAutoresizingMaskIntoConstraints = false
        categoryLabel.font = UIFont.systemFont(ofSize: 13)
        categoryLabel.textColor = .secondaryLabel

        ratingContainerView.translatesAutoresizingMaskIntoConstraints = false
        ratingContainerView.layer.cornerRadius = 10
        ratingContainerView.clipsToBounds = true
        ratingContainerView.backgroundColor = UIColor.systemPurple

        ratingLabel.translatesAutoresizingMaskIntoConstraints = false
        ratingLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        ratingLabel.textColor = .white
        ratingLabel.textAlignment = .center

        cardView.addSubview(thumbnailImageView)
        cardView.addSubview(nameLabel)
        cardView.addSubview(categoryLabel)
        cardView.addSubview(ratingContainerView)
        ratingContainerView.addSubview(ratingLabel)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            thumbnailImageView.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            thumbnailImageView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            thumbnailImageView.widthAnchor.constraint(equalToConstant: 80),
            thumbnailImageView.heightAnchor.constraint(equalToConstant: 70),

            nameLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 14),
            nameLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: thumbnailImageView.leadingAnchor, constant: -12),

            categoryLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            categoryLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            categoryLabel.trailingAnchor.constraint(lessThanOrEqualTo: thumbnailImageView.leadingAnchor, constant: -12),

            ratingContainerView.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            ratingContainerView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -10),
            ratingContainerView.widthAnchor.constraint(greaterThanOrEqualToConstant: 60),
            ratingContainerView.heightAnchor.constraint(equalToConstant: 20),

            ratingLabel.leadingAnchor.constraint(equalTo: ratingContainerView.leadingAnchor, constant: 8),
            ratingLabel.trailingAnchor.constraint(equalTo: ratingContainerView.trailingAnchor, constant: -8),
            ratingLabel.topAnchor.constraint(equalTo: ratingContainerView.topAnchor, constant: 2),
            ratingLabel.bottomAnchor.constraint(equalTo: ratingContainerView.bottomAnchor, constant: -2)
        ])
    }

    func configure(with vendor: VendorMarketplaceViewController.Vendor) {
        nameLabel.text = vendor.name
        categoryLabel.text = vendor.category
        ratingLabel.text = String(format: "%.1f ★", vendor.rating)
        thumbnailImageView.image = UIImage(named: vendor.imageName)
    }
}

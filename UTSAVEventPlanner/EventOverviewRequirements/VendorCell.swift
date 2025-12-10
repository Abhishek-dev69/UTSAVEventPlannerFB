//
//  VendorCell.swift
//  UTSAV
//
//  Updated to accept VendorRecord and show avatar, role, rating.
//

import UIKit

final class VendorCell: UITableViewCell {

    var onSelect: (() -> Void)?

    private let avatarImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let ratingLabel = UILabel()
    private let selectButton = UIButton(type: .system)

    // simple in-memory cache to avoid flicker (app-level cache is better)
    private static let imageCache = NSCache<NSString, UIImage>()
    private var currentImageURL: URL?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        selectionStyle = .none

        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.layer.cornerRadius = 28
        avatarImageView.clipsToBounds = true
        avatarImageView.widthAnchor.constraint(equalToConstant: 56).isActive = true
        avatarImageView.heightAnchor.constraint(equalToConstant: 56).isActive = true
        avatarImageView.image = UIImage(systemName: "person.crop.square")

        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        subtitleLabel.font = .systemFont(ofSize: 13)
        subtitleLabel.textColor = .secondaryLabel

        ratingLabel.font = .systemFont(ofSize: 13)
        ratingLabel.textColor = .systemPurple

        selectButton.setTitle("Select", for: .normal)
        selectButton.layer.cornerRadius = 14
        selectButton.clipsToBounds = true
        selectButton.backgroundColor = UIColor.systemPurple
        selectButton.setTitleColor(.white, for: .normal)
        selectButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        selectButton.addTarget(self, action: #selector(selectTapped), for: .touchUpInside)

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 4
        textStack.alignment = .leading

        let rightStack = UIStackView(arrangedSubviews: [ratingLabel, selectButton])
        rightStack.axis = .vertical
        rightStack.spacing = 8
        rightStack.alignment = .trailing

        let row = UIStackView(arrangedSubviews: [avatarImageView, textStack, UIView(), rightStack])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 12
        row.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            row.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            row.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            row.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }

    @objc private func selectTapped() {
        onSelect?()
    }

    func configure(with record: VendorRecord) {
        titleLabel.text = record.fullName ?? record.businessName ?? "Vendor"
        subtitleLabel.text = record.role ?? (record.businessName ?? "")
        ratingLabel.text = "⭐ 4.5" // placeholder rating (store actual rating if you have one)

        // avatar handling: prefer public URL, else build from avatarPath using VendorManager
        avatarImageView.image = UIImage(systemName: "person.crop.square")
        currentImageURL = nil

        if let urlString = VendorManager.shared.resolvedAvatarURLString(for: record),
           let url = URL(string: urlString) {
            currentImageURL = url
            let key = NSString(string: url.absoluteString)
            if let cached = Self.imageCache.object(forKey: key) {
                avatarImageView.image = cached
            } else {
                // async load
                let req = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 30)
                URLSession.shared.dataTask(with: req) { [weak self] data, _, _ in
                    guard let self = self, let data = data, let img = UIImage(data: data) else { return }
                    DispatchQueue.main.async {
                        // ensure cell still wants this image
                        if self.currentImageURL == url {
                            self.avatarImageView.image = img
                        }
                        Self.imageCache.setObject(img, forKey: key)
                    }
                }.resume()
            }
        }
    }
}


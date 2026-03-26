//
//  VendorCell.swift
//  UTSAV
//

import UIKit

final class VendorCell: UITableViewCell {

    var onSelect: (() -> Void)?

    private let cardView = UIView()
    private let avatarImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let selectButton = UIButton(type: .system)

    // simple in-memory cache
    private static let imageCache = NSCache<NSString, UIImage>()
    private var currentImageURL: URL?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        backgroundColor = .clear
        selectionStyle = .none

        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.backgroundColor = UIColor(white: 1.0, alpha: 0.85)
        cardView.layer.cornerRadius = 18
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.08
        cardView.layer.shadowOffset = CGSize(width: 0, height: 3)
        cardView.layer.shadowRadius = 5
        contentView.addSubview(cardView)

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

        selectButton.setTitle("Select", for: .normal)
        selectButton.layer.cornerRadius = 14
        selectButton.clipsToBounds = true
        selectButton.backgroundColor = UIColor(red: 138/255, green: 73/255, blue: 246/255, alpha: 1)
        selectButton.setTitleColor(.white, for: .normal)
        selectButton.titleLabel?.font = .systemFont(ofSize: 13, weight: .bold)
        selectButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        selectButton.addTarget(self, action: #selector(selectTapped), for: .touchUpInside)

        // text stack
        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 4
        textStack.alignment = .leading

        // right side only contains the select button now
        let rightStack = UIStackView(arrangedSubviews: [selectButton])
        rightStack.axis = .vertical
        rightStack.spacing = 8
        rightStack.alignment = .trailing

        let row = UIStackView(arrangedSubviews: [avatarImageView, textStack, UIView(), rightStack])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 12
        row.translatesAutoresizingMaskIntoConstraints = false

        cardView.addSubview(row)
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            row.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 14),
            row.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -14),
            row.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 14),
            row.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -14)
        ])
    }

    @objc private func selectTapped() {
        onSelect?()
    }

    func configure(with record: VendorRecord) {

        titleLabel.text = record.fullName ?? record.businessName ?? "Vendor"
        subtitleLabel.text = record.role ?? (record.businessName ?? "")

        avatarImageView.image = UIImage(systemName: "person.crop.square")
        currentImageURL = nil

        // Load avatar
        if let urlString = VendorManager.shared.resolvedAvatarURLString(for: record),
           let url = URL(string: urlString) {

            currentImageURL = url
            let key = NSString(string: url.absoluteString)

            if let cached = Self.imageCache.object(forKey: key) {
                avatarImageView.image = cached
                return
            }

            let req = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 30)
            URLSession.shared.dataTask(with: req) { [weak self] data, _, _ in
                guard let self = self,
                      let data = data,
                      let img = UIImage(data: data)
                else { return }

                DispatchQueue.main.async {
                    if self.currentImageURL == url {
                        self.avatarImageView.image = img
                    }
                    Self.imageCache.setObject(img, forKey: key)
                }
            }.resume()
        }
    }
}

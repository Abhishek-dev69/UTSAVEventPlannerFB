// EventDetailsViewController.swift
import UIKit
import MapKit

// MARK: - Model
struct EventDetails {
    let eventName: String
    let clientName: String
    let location: String
    let guestCount: Int
    let budgetInPaise: Int
    let startDate: Date
    let endDate: Date
}

final class EventDetailsViewController: UIViewController {

    // MARK: Selected Event Type (from EventType flow / picker)
    var selectedEventType: EventTypeItem?

    // Local event type list (same items as EventTypeViewController)
    private let eventTypes: [EventTypeItem] = [
        .init(title: "Wedding",          imageName: "event_wedding"),
        .init(title: "Birthday Party",   imageName: "event_birthday"),
        .init(title: "Corporate Event",  imageName: "event_corporate"),
        .init(title: "Baby Shower",      imageName: "event_babyshower"),
        .init(title: "Engagement Party", imageName: "event_engagement"),
        .init(title: "Anniversary",      imageName: "event_anniversary"),
        .init(title: "Schools",          imageName: "event_schools"),
        .init(title: "Holiday Party",    imageName: "event_holiday")
    ]

    // MARK: UI
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let formStack = UIStackView()

    private let continueButton: UIButton = {
        var cfg = UIButton.Configuration.filled()
        cfg.title = "Continue"
        cfg.baseBackgroundColor = UIColor(red: 0.55, green: 0.22, blue: 0.94, alpha: 1)
        cfg.baseForegroundColor = .white
        cfg.cornerStyle = .large
        cfg.contentInsets = .init(top: 16, leading: 24, bottom: 16, trailing: 24)
        let b = UIButton(configuration: cfg)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.layer.cornerRadius = 28
        b.layer.masksToBounds = true
        return b
    }()

    // MARK: Fields
    // NEW: Event Type field (picker)
    private let eventTypeField: RoundedTextField = {
        let tf = RoundedTextField(placeholder: "Select Event Type")
        tf.setRightIcon(systemName: "chevron.down")
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    private let eventName = RoundedTextField(placeholder: "Enter The Event Name")
    private let clientName = RoundedTextField(placeholder: "Enter the Client Name")
    private let locationField: RoundedTextField = {
        let tf = RoundedTextField(placeholder: "Search for Location")
        tf.setRightIcon(systemName: "paperplane")
        return tf
    }()
    private let guestCountField: RoundedTextField = {
        let tf = RoundedTextField(placeholder: "Enter the Number of Guests")
        tf.keyboardType = .numberPad
        return tf
    }()
    private let budgetField: RoundedTextField = {
        let tf = RoundedTextField(placeholder: "₹1,00,000")
        tf.keyboardType = .numberPad
        return tf
    }()
    private let startDateField: RoundedTextField = {
        let tf = RoundedTextField(placeholder: "Select Date")
        tf.setRightIcon(systemName: "calendar")
        return tf
    }()
    private let endDateField: RoundedTextField = {
        let tf = RoundedTextField(placeholder: "Select Date")
        tf.setRightIcon(systemName: "calendar")
        return tf
    }()

    // MARK: Date Pickers (native wheels)
    private let startPicker: UIDatePicker = {
        let p = UIDatePicker()
        p.datePickerMode = .date
        p.minimumDate = Date()
        if #available(iOS 13.4, *) {
            p.preferredDatePickerStyle = .wheels
        }
        return p
    }()
    private let endPicker: UIDatePicker = {
        let p = UIDatePicker()
        p.datePickerMode = .date
        p.minimumDate = Date()
        if #available(iOS 13.4, *) {
            p.preferredDatePickerStyle = .wheels
        }
        return p
    }()

    // MARK: Event type picker
    private let eventTypePicker = UIPickerView()

    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        return df
    }()

    let indianFormatter: NumberFormatter = {
        let nf = NumberFormatter()
        nf.numberStyle = .currency
        nf.currencyCode = "INR"
        nf.locale = Locale(identifier: "en_IN")
        nf.maximumFractionDigits = 0
        return nf
    }()

    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        navigationItem.title = "Event Details"
        navigationItem.largeTitleDisplayMode = .never

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(didTapBack)
        )

        setupLayout()
        setupDatePickers()
        setupBudgetFormatting()
        setupKeyboardHandling()
        hookRightIconTaps()
        setupFieldPlaceholdersForExistingDates()
        setupEventTypePicker()

        continueButton.addTarget(self, action: #selector(didTapContinue), for: .touchUpInside)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: Layout
    private func setupLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        formStack.translatesAutoresizingMaskIntoConstraints = false

        formStack.axis = .vertical
        formStack.spacing = 22

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(formStack)
        view.addSubview(continueButton)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: continueButton.topAnchor, constant: -20),

            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            formStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            formStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            formStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            formStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40),

            continueButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            continueButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            continueButton.heightAnchor.constraint(equalToConstant: 56)
        ])

        // Add fields in desired order: Event Type first
        formStack.addArrangedSubview(labeled("Event Type", eventTypeField))
        formStack.addArrangedSubview(labeled("Event Name", eventName))
        formStack.addArrangedSubview(labeled("Client Name", clientName))
        formStack.addArrangedSubview(labeled("Location", locationField))
        formStack.addArrangedSubview(labeled("Guest Count", guestCountField))
        formStack.addArrangedSubview(labeled("Budget", budgetField))

        let dateRow = UIStackView()
        dateRow.axis = .horizontal
        dateRow.spacing = 16
        dateRow.distribution = .fillEqually
        dateRow.addArrangedSubview(labeled("Start Date", startDateField))
        dateRow.addArrangedSubview(labeled("End Date", endDateField))

        formStack.addArrangedSubview(dateRow)
    }

    private func sectionLabel(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = .systemFont(ofSize: 16, weight: .semibold)
        return l
    }

    private func labeled(_ title: String, _ field: UIView) -> UIStackView {
        let s = UIStackView(arrangedSubviews: [sectionLabel(title), field])
        s.axis = .vertical
        s.spacing = 8
        return s
    }

    // MARK: Event type picker setup
    private func setupEventTypePicker() {
        eventTypePicker.delegate = self
        eventTypePicker.dataSource = self

        // Use picker as inputView for the eventTypeField
        eventTypeField.inputView = eventTypePicker
        eventTypeField.inputAccessoryView = makeToolbar(done: #selector(doneEventTypePicker), cancel: #selector(cancelEventTypePicker))

        // If there's a preselected type, show it
        if let pre = selectedEventType,
           let idx = eventTypes.firstIndex(where: { $0.title == pre.title }) {
            eventTypePicker.selectRow(idx, inComponent: 0, animated: false)
            eventTypeField.text = pre.title
        }
    }

    @objc private func doneEventTypePicker() {
        // ensure text matches current selection
        let row = eventTypePicker.selectedRow(inComponent: 0)
        selectEventType(at: row)
        eventTypeField.resignFirstResponder()
    }

    @objc private func cancelEventTypePicker() {
        // if cancel, just dismiss
        eventTypeField.resignFirstResponder()
    }

    private func selectEventType(at row: Int) {
        guard row >= 0 && row < eventTypes.count else { return }
        selectedEventType = eventTypes[row]
        eventTypeField.text = selectedEventType?.title
    }

    // MARK: Date pickers + accessory toolbar
    private func setupDatePickers() {
        // Attach as inputView so the picker is displayed when user taps the text field
        startDateField.inputView = startPicker
        endDateField.inputView = endPicker

        // Attach toolbar with Cancel / Done buttons
        startDateField.inputAccessoryView = makeToolbar(done: #selector(doneStart), cancel: #selector(cancelPicker))
        endDateField.inputAccessoryView = makeToolbar(done: #selector(doneEnd), cancel: #selector(cancelPicker))

        startPicker.addTarget(self, action: #selector(startDateChanged), for: .valueChanged)
        endPicker.addTarget(self, action: #selector(endDateChanged), for: .valueChanged)

        startDateField.addTarget(self, action: #selector(startEditingBegan), for: .editingDidBegin)
        endDateField.addTarget(self, action: #selector(endEditingBegan), for: .editingDidBegin)
    }

    private func makeToolbar(done: Selector, cancel: Selector) -> UIToolbar {
        let tb = UIToolbar()
        tb.translatesAutoresizingMaskIntoConstraints = false
        let cancelItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: cancel)
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: done)
        tb.items = [cancelItem, flex, doneItem]
        tb.sizeToFit()
        return tb
    }

    @objc private func startEditingBegan() {
        startDateChanged()
    }
    @objc private func endEditingBegan() {
        endDateChanged()
    }

    @objc private func startDateChanged() {
        let d = startPicker.date
        endPicker.minimumDate = d
        startDateField.text = dateFormatter.string(from: d)
        if endPicker.date < d {
            endPicker.date = d
            endDateChanged()
        }
    }

    @objc private func endDateChanged() {
        let d = max(endPicker.date, startPicker.date)
        endPicker.date = d
        endDateField.text = dateFormatter.string(from: d)
    }

    @objc private func doneStart() {
        startDateChanged()
        startDateField.resignFirstResponder()
    }
    @objc private func doneEnd() {
        endDateChanged()
        endDateField.resignFirstResponder()
    }
    @objc private func cancelPicker() {
        startDateField.resignFirstResponder()
        endDateField.resignFirstResponder()
    }

    // MARK: Budget formatting
    private func setupBudgetFormatting() {
        budgetField.addTarget(self, action: #selector(formatBudget), for: .editingChanged)
    }

    @objc private func formatBudget() {
        let digits = budgetField.text?.filter(\.isNumber) ?? ""
        guard let n = Int(digits) else { budgetField.text = nil; return }
        budgetField.text = indianFormatter.string(from: NSNumber(value: n))
    }

    // MARK: Keyboard handling
    private func setupKeyboardHandling() {
        NotificationCenter.default.addObserver(self, selector: #selector(kbChanged(_:)),
                                               name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(kbHidden(_:)),
                                               name: UIResponder.keyboardWillHideNotification, object: nil)

        let tap = UITapGestureRecognizer(target: self, action: #selector(endEditingNow))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc private func kbChanged(_ n: Notification) {
        guard
            let ui = n.userInfo,
            let frame = ui[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
            let dur = ui[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval
        else { return }

        let bottom = view.convert(frame, from: nil).intersection(view.bounds).height
        UIView.animate(withDuration: dur) {
            self.scrollView.contentInset.bottom = bottom + 56 + 12
            self.scrollView.verticalScrollIndicatorInsets.bottom = bottom + 56 + 12
        }
    }

    @objc private func kbHidden(_ n: Notification) {
        let dur = (n.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval) ?? 0.25
        UIView.animate(withDuration: dur) {
            self.scrollView.contentInset.bottom = 0
            self.scrollView.verticalScrollIndicatorInsets.bottom = 0
        }
    }

    @objc private func endEditingNow() { view.endEditing(true) }

    // MARK: Right icon taps (RoundedTextField helper expected)
    private func hookRightIconTaps() {
        // eventTypeField right icon should also open the picker
        eventTypeField.onRightIconTap(target: self, action: #selector(openEventTypePicker))
        startDateField.onRightIconTap(target: self, action: #selector(focusStartDate))
        endDateField.onRightIconTap(target: self, action: #selector(focusEndDate))
        locationField.onRightIconTap(target: self, action: #selector(openLocationSearch))
    }

    @objc private func openEventTypePicker() {
        eventTypeField.becomeFirstResponder()
    }

    @objc private func focusStartDate() { startDateField.becomeFirstResponder() }
    @objc private func focusEndDate() { endDateField.becomeFirstResponder() }

    // MARK: Location search
    @objc private func openLocationSearch() {
        let vc = LocationSearchViewController()
        vc.onSelect = { [weak self] sel in
            self?.locationField.text = sel.displayName
        }
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        vc.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "xmark"),
                                                              style: .plain,
                                                              target: self,
                                                              action: #selector(dismissPresented))
        present(nav, animated: true)
    }
    @objc private func dismissPresented() { presentedViewController?.dismiss(animated: true) }

    // MARK: Validation / Read form
    private func parseINR(_ text: String?) -> Int? {
        guard let t = text, !t.isEmpty else { return nil }
        let digits = t.filter(\.isNumber)
        guard let rupees = Int(digits) else { return nil }
        return rupees * 100 // paise
    }

    private func readForm() throws -> EventDetails {
        enum FError: LocalizedError {
            case missing(String)
            case logical(String)

            var errorDescription: String? {
                switch self {
                case .missing(let f): return "\(f) is required."
                case .logical(let m): return m
                }
            }
        }

        // Event Type optional? If you want to require it, uncomment the guard below.
        /*
        guard let _ = selectedEventType else {
            throw FError.missing("Event Type")
        }
        */

        guard let name = eventName.text?.trimmingCharacters(in: .whitespaces), !name.isEmpty else {
            throw FError.missing("Event Name")
        }
        guard let client = clientName.text?.trimmingCharacters(in: .whitespaces), !client.isEmpty else {
            throw FError.missing("Client Name")
        }
        guard let loc = locationField.text?.trimmingCharacters(in: .whitespaces), !loc.isEmpty else {
            throw FError.missing("Location")
        }
        guard let gcText = guestCountField.text?.filter(\.isNumber), let gc = Int(gcText), gc > 0 else {
            throw FError.missing("Guest Count")
        }
        guard let budget = parseINR(budgetField.text), budget > 0 else {
            throw FError.missing("Budget")
        }

        let s = startPicker.date
        let e = endPicker.date
        if e < s { throw FError.logical("End date cannot be before start date.") }

        return EventDetails(eventName: name, clientName: client, location: loc,
                            guestCount: gc, budgetInPaise: budget,
                            startDate: s, endDate: e)
    }

    // MARK: Insert Event (Continue)
    @objc private func didTapContinue() {
        do {
            let details = try readForm()

            // HUD
            let hud = UIActivityIndicatorView(style: .large)
            hud.translatesAutoresizingMaskIntoConstraints = false
            hud.startAnimating()
            view.addSubview(hud)
            NSLayoutConstraint.activate([
                hud.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                hud.centerYAnchor.constraint(equalTo: view.centerYAnchor)
            ])

            Task {
                do {
                    let metadata = ["eventTypeImage": selectedEventType?.imageName ?? ""]
                    let record = try await EventSupabaseManager.shared.insertEvent(details: details, metadata: metadata)

                    EventSession.shared.currentEventId = record.id

                    await MainActor.run {
                        hud.removeFromSuperview()
                        let vc = ConfirmationViewController(details: details,
                                                            currencyFormatter: indianFormatter,
                                                            dateFormatter: dateFormatter)
                        if let nav = self.navigationController {
                            nav.pushViewController(vc, animated: true)
                        } else {
                            let nav = UINavigationController(rootViewController: vc)
                            nav.modalPresentationStyle = .fullScreen
                            self.present(nav, animated: true)
                        }
                    }

                } catch {
                    await MainActor.run {
                        hud.removeFromSuperview()
                        let alert = UIAlertController(title: "Failed to save", message: error.localizedDescription, preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(alert, animated: true)
                    }
                }
            }
        } catch {
            let alert = UIAlertController(title: "Hold on", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }

    // MARK: Helpers
    @objc private func didTapBack() {
        navigationController?.popViewController(animated: true)
    }

    private func setupFieldPlaceholdersForExistingDates() {
        startDateField.text = dateFormatter.string(from: startPicker.date)
        endDateField.text = dateFormatter.string(from: endPicker.date)
    }
}

// MARK: - UIPickerView DataSource/Delegate for Event Type
extension EventDetailsViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        eventTypes.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        eventTypes[row].title
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectEventType(at: row)
    }
}


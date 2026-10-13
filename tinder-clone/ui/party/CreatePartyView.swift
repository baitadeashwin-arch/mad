import SwiftUI
import CoreLocation

struct CreatePartyView: View {
    var onCreated: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var description = ""
    @State private var date = Date().addingTimeInterval(86400)
    @State private var category: PartyCategory = .collegeParty
    @State private var maxParticipants = 50
    @State private var approximateLocation = ""
    @State private var privateLocation = ""
    @State private var visibility: PartyVisibility = .public
    @State private var isEvent = true
    @State private var errorMessage: String?
    @State private var isSaving = false

    var body: some View {
        Form {
            Section("Basics") {
                TextField("Party name", text: $name)
                TextEditor(text: $description)
                    .frame(minHeight: 80)
                DatePicker("Date", selection: $date, in: Date()..., displayedComponents: [.date])
                DatePicker("Time", selection: $date, displayedComponents: [.hourAndMinute])
                Picker("Category", selection: $category) {
                    ForEach(PartyCategory.allCases) { item in
                        Text(item.title).tag(item)
                    }
                }
                Stepper("Max participants: \(maxParticipants)", value: $maxParticipants, in: 2...500)
                Toggle("List as event", isOn: $isEvent)
            }
            Section("Location") {
                TextField("Approximate location (e.g. Near RIT)", text: $approximateLocation)
                if visibility != .public {
                    TextField("Private location note (members only)", text: $privateLocation)
                }
                Text("Exact addresses stay hidden from the public feed.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            Section("Visibility") {
                Picker("Who can see this", selection: $visibility) {
                    ForEach(PartyVisibility.allCases) { item in
                        Text(item.title).tag(item)
                    }
                }
            }
        }
        .navigationTitle("Create Party")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Publish") { Task { await save() } }
                    .disabled(isSaving || !isValid)
            }
        }
        .alert("Couldn't create party", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        ), actions: { Button("OK", role: .cancel) {} }, message: {
            Text(errorMessage ?? "")
        })
        .overlay { if isSaving { ProgressView() } }
    }

    private var isValid: Bool {
        name.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3 &&
        description.trimmingCharacters(in: .whitespacesAndNewlines).count >= 8 &&
        approximateLocation.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3 &&
        date > Date()
    }

    private func save() async {
        isSaving = true
        do {
            var coordinate: CLLocationCoordinate2D?
            if LocationService.shared.permissionState == .authorized {
                coordinate = try? await LocationService.shared.requestOneShotLocation()
            }
            _ = try await SocialRepository.shared.createParty(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                description: description.trimmingCharacters(in: .whitespacesAndNewlines),
                date: date,
                category: category,
                maxParticipants: maxParticipants,
                approximateLocation: approximateLocation.trimmingCharacters(in: .whitespacesAndNewlines),
                visibility: visibility,
                isEvent: isEvent,
                privateLocation: visibility == .public ? nil : privateLocation,
                coordinate: coordinate.map { LocationPrivacy.coarsen(coordinate: $0) }
            )
            onCreated()
            dismiss()
        } catch {
            errorMessage = UserFacingError.message(from: error)
        }
        isSaving = false
    }
}

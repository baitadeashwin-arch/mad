import SwiftUI

struct BlockedUsersView: View {
    @State private var ids: [String] = []
    @State private var errorMessage: String?

    var body: some View {
        List {
            if ids.isEmpty {
                Text("You haven't blocked anyone.")
                    .foregroundColor(.secondary)
            } else {
                ForEach(ids, id: \.self) { id in
                    HStack {
                        Text("Blocked user")
                        Spacer()
                        Button("Unblock") {
                            Task {
                                try? await SocialRepository.shared.unblock(userId: id)
                                await load()
                            }
                        }
                    }
                    .accessibilityLabel("Blocked user")
                }
            }
        }
        .navigationTitle("Blocked Users")
        .task { await load() }
    }

    private func load() async {
        do {
            ids = Array(try await SocialRepository.shared.blockedIds())
        } catch {
            errorMessage = UserFacingError.message(from: error)
        }
    }
}

struct ReportUserView: View {
    let userId: String
    @Environment(\.dismiss) private var dismiss
    @State private var reason: ReportReason = .spam
    @State private var details = ""
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Picker("Reason", selection: $reason) {
                ForEach(ReportReason.allCases) { item in
                    Text(item.title).tag(item)
                }
            }
            TextField("Details", text: $details)
            Button("Submit report") {
                Task {
                    do {
                        try await SocialRepository.shared.report(userId: userId, reason: reason, details: details)
                        dismiss()
                    } catch {
                        errorMessage = UserFacingError.message(from: error)
                    }
                }
            }
        }
        .navigationTitle("Report")
        .alert("Couldn't send report", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        ), actions: { Button("OK", role: .cancel) {} }, message: {
            Text(errorMessage ?? "")
        })
    }
}

//
//  DatabaseHealthView.swift
//  AntiSocial
//
//  Created to check Firebase database connection status and seed collections.
//

import SwiftUI

struct DatabaseHealthView: View {
    @StateObject private var dbManager = FirebaseDatabaseManager.shared

    var body: some View {
        List {
            // Status Section
            Section(header: Text("Firebase Connection Status")) {
                HStack(spacing: 12) {
                    Image(systemName: dbManager.isConnected ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(dbManager.isConnected ? .green : .orange)
                        .font(.title2)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(dbManager.isConnected ? "Connected to Firestore" : "Status")
                            .font(.headline)
                        Text(dbManager.connectionStatus)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)

                if let lastChecked = dbManager.lastChecked {
                    HStack {
                        Text("Last Checked")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(lastChecked, style: .time)
                            .font(.footnote)
                    }
                }

                if dbManager.lastPingDurationMs > 0 {
                    HStack {
                        Text("Latency")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(String(format: "%.0f ms", dbManager.lastPingDurationMs))
                            .font(.footnote.monospacedDigit())
                            .foregroundColor(.green)
                    }
                }

                Button(action: {
                    Task {
                        await dbManager.checkDatabaseConnection()
                    }
                }) {
                    HStack {
                        if dbManager.isChecking {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .padding(.trailing, 6)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text("Test Connection Now")
                    }
                }
                .disabled(dbManager.isChecking)
            }

            // Collections Summary Section
            Section(header: Text("Database Collections")) {
                let collections = [
                    ("users", "Users & Profiles", "person.2.fill"),
                    ("parties", "Parties & Gatherings", "sparkles"),
                    ("events", "Campus Events", "calendar"),
                    ("matches", "Mutual Matches", "heart.fill"),
                    ("userLocations", "User Locations (Nearby)", "location.fill"),
                    ("partyInvitations", "Party Invitations", "envelope.fill")
                ]

                ForEach(collections, id: \.0) { col in
                    HStack {
                        Label(col.1, systemImage: col.2)
                        Spacer()
                        let count = dbManager.collectionCounts[col.0] ?? 0
                        Text("\(count)")
                            .font(.subheadline.bold())
                            .foregroundColor(count > 0 ? .primary : .secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color(UIColor.secondarySystemFill))
                            .cornerRadius(6)
                    }
                }

                Button(action: {
                    Task {
                        await dbManager.seedInitialCollections()
                    }
                }) {
                    HStack {
                        if dbManager.isSeeding {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .padding(.trailing, 6)
                        } else {
                            Image(systemName: "plus.square.on.square")
                        }
                        Text("Add Sample Collections According to Data")
                    }
                }
                .disabled(dbManager.isSeeding)
            }

            // Setup Guide
            Section(header: Text("Firebase Configuration Guide")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("1. Place `GoogleService-Info.plist` inside `tinder-clone/`.")
                        .font(.caption)
                    Text("2. Add it to the Xcode Target membership.")
                        .font(.caption)
                    Text("3. Enable Firestore in Firebase Console (Test or Production mode).")
                        .font(.caption)
                    Text("4. Deploy rules using `firebase deploy --only firestore:rules`.")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
                .padding(.vertical, 4)
            }

            // Live Activity Logs
            if !dbManager.logMessages.isEmpty {
                Section(header: Text("Connection Logs")) {
                    ForEach(dbManager.logMessages.suffix(6), id: \.self) { msg in
                        Text(msg)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Database & Firebase")
        .task {
            if !dbManager.isConnected && !dbManager.isChecking {
                await dbManager.checkDatabaseConnection()
            }
        }
    }
}

struct DatabaseHealthView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DatabaseHealthView()
        }
    }
}

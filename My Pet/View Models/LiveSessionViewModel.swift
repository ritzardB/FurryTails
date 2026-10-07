//
//  LiveSessionViewModel.swift
//  My Pet
//
//  Created by Richard Balabarcon on 07/10/2026.
//

import Foundation
import Combine
import FirebaseAuth

@MainActor
final class LiveSessionViewModel: ObservableObject {

    // MARK: - Published State

    @Published private(set) var liveSessions: [LiveSession] = []
    @Published private(set) var myLiveSession: LiveSession?

    @Published var selectedSession: LiveSession?

    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    // MARK: - Services

    private let service = LiveSessionService.shared

    // MARK: - Computed Properties

    var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }

    var hasLiveSessions: Bool {
        !liveSessions.isEmpty
    }

    // MARK: - Load Live Sessions

    func loadLiveSessions() async {
        isLoading = true
        errorMessage = nil

        do {
            let sessions = try await service.fetchActiveSessions()

            liveSessions = sessions

            // Find the current user's active session.
            if let uid = currentUserId {
                myLiveSession = sessions.first {
                    $0.hostId == uid
                }
            } else {
                myLiveSession = nil
            }

            // Select the current user's session by default.
            // If the current user is not live, select the first
            // available live session.
            if let mySession = myLiveSession {
                selectedSession = mySession
            } else {
                selectedSession = sessions.first
            }

            isLoading = false

            print("🔴 Live sessions loaded: \(sessions.count)")

            if let selectedSession {
                print("▶️ Selected live session: \(selectedSession.hostUsername)")
            }

        } catch {
            isLoading = false
            errorMessage = error.localizedDescription

            print("❌ Failed to load live sessions:")
            print(error.localizedDescription)
        }
    }

    // MARK: - Select Session

    func selectSession(_ session: LiveSession) {
        selectedSession = session

        print("▶️ Selected live session:")
        print("   Host: \(session.hostUsername)")
        print("   Session ID: \(session.id ?? "Unknown")")
    }

    // MARK: - Start Live Session

    func startLiveSession(title: String) async {
        errorMessage = nil

        do {
            let session = try await service.startLiveSession(title: title)

            myLiveSession = session

            // Refresh the complete Live Now list so everyone,
            // including the current user, appears together.
            await loadLiveSessions()

            // Explicitly select the newly created session.
            if let createdSession = liveSessions.first(where: {
                $0.id == session.id
            }) {
                selectedSession = createdSession
            }

        } catch {
            errorMessage = error.localizedDescription

            print("❌ Failed to start live session:")
            print(error.localizedDescription)
        }
    }

    // MARK: - End Live Session

    func endLiveSession() async {
        guard let session = myLiveSession,
              let sessionId = session.id else {
            return
        }

        errorMessage = nil

        do {
            try await service.endLiveSession(sessionId: sessionId)

            myLiveSession = nil

            // Remove the ended session from the current list.
            liveSessions.removeAll {
                $0.id == sessionId
            }

            // If the ended session was selected,
            // select another live session if one exists.
            if selectedSession?.id == sessionId {
                selectedSession = liveSessions.first
            }

            print("⏹️ My live session ended")

        } catch {
            errorMessage = error.localizedDescription

            print("❌ Failed to end live session:")
            print(error.localizedDescription)
        }
    }

    // MARK: - Viewer Count

    func incrementViewerCount(for session: LiveSession) async {
        guard let sessionId = session.id else {
            return
        }

        do {
            try await service.updateViewerCount(
                sessionId: sessionId,
                increment: 1
            )

            await loadLiveSessions()

        } catch {
            print("❌ Failed to increment viewer count:")
            print(error.localizedDescription)
        }
    }

    func decrementViewerCount(for session: LiveSession) async {
        guard let sessionId = session.id else {
            return
        }

        do {
            try await service.updateViewerCount(
                sessionId: sessionId,
                increment: -1
            )

            await loadLiveSessions()

        } catch {
            print("❌ Failed to decrement viewer count:")
            print(error.localizedDescription)
        }
    }

    // MARK: - Refresh

    func refresh() async {
        await loadLiveSessions()
    }
}

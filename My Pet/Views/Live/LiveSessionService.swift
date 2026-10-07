//
//  LiveSessionService.swift
//  My Pet
//
//  Created by Richard Balabarcon on 07/10/2026.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreCombineSwift

final class LiveSessionService {

    static let shared = LiveSessionService()

    private let db = Firestore.firestore()

    private init() {}

    // MARK: - Start Live Session
    func startLiveSession(title: String) async throws -> LiveSession {

        guard let user = Auth.auth().currentUser else {
            throw liveSessionError(
                "You must be signed in to start a live session."
            )
        }

        let userId = user.uid

        // MARK: Prevent Duplicate Active Sessions

        // A user can only have one active live session at a time.
        if let existingSession = try await fetchMyActiveSession() {

            print("⚠️ User already has an active live session.")
            print("   Session ID: \(existingSession.id ?? "Unknown")")
            print("   Host: \(existingSession.hostUsername)")

            throw liveSessionError(
                "You already have an active live session."
            )
        }

        // MARK: Load Current User

        let currentUser = try await AuthService.loadUser(uid: userId)

        // MARK: Create New Session

        let sessionRef = db
            .collection("liveSessions")
            .document()

        let session = LiveSession(
            id: sessionRef.documentID,
            hostId: userId,
            hostUsername: currentUser.username,
            hostProfileImageURL: currentUser.profileImageURL,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            status: "live",
            startedAt: nil,
            endedAt: nil,
            viewerCount: 0,
            streamId: nil
        )

        _ = sessionRef.setData(from: session)

        print("🔴 Live session started")
        print("   Session ID: \(sessionRef.documentID)")
        print("   Host: \(currentUser.username)")

        return session
    }
    
    // MARK: - End Live Session

    func endLiveSession(
        sessionId: String
    ) async throws {

        guard !sessionId.isEmpty else {
            return
        }

        try await db
            .collection("liveSessions")
            .document(sessionId)
            .updateData([
                "status": "ended",
                "endedAt":
                    FieldValue.serverTimestamp()
            ])

        print(
            "⏹️ Live session ended:",
            sessionId
        )
    }

    // MARK: - Fetch Active Sessions

    func fetchActiveSessions()
        async throws -> [LiveSession] {

        let snapshot =
            try await db
                .collection("liveSessions")
                .whereField(
                    "status",
                    isEqualTo: "live"
                )
                .order(
                    by: "startedAt",
                    descending: true
                )
                .getDocuments()

        return snapshot.documents.compactMap { document in

            try? document.data(
                as: LiveSession.self
            )
        }
    }

    // MARK: - Fetch My Active Session

    func fetchMyActiveSession()
        async throws -> LiveSession? {

        guard let uid =
                Auth.auth()
                    .currentUser?
                    .uid
        else {
            return nil
        }

        let snapshot =
            try await db
                .collection("liveSessions")
                .whereField(
                    "hostId",
                    isEqualTo: uid
                )
                .whereField(
                    "status",
                    isEqualTo: "live"
                )
                .limit(to: 1)
                .getDocuments()

        guard let document =
                snapshot.documents.first
        else {
            return nil
        }

        return try document.data(
            as: LiveSession.self
        )
    }

    // MARK: - Update Viewer Count

    func updateViewerCount(
        sessionId: String,
        increment: Int
    ) async throws {

        guard !sessionId.isEmpty else {
            return
        }

        try await db
            .collection("liveSessions")
            .document(sessionId)
            .updateData([
                "viewerCount":
                    FieldValue.increment(
                        Int64(increment)
                    )
            ])
    }

    // MARK: - Error

    private func liveSessionError(
        _ message: String
    ) -> NSError {

        NSError(
            domain: "LiveSessionService",
            code: 2001,
            userInfo: [
                NSLocalizedDescriptionKey:
                    message
            ]
        )
    }
}

import FirebaseFirestore
import FirebaseFirestoreCombineSwift
import FirebaseAuth
import Combine

final class FeedService {
    private let db = Firestore.firestore()

    // 1️⃣ Fetch all posts from top-level /posts
    func fetchPosts() async throws -> [Post] {
        print("📡 Fetching posts from /posts ...")

        let snapshot = try await db.collection("posts")
            .order(by: "createdAt", descending: true)
            .getDocuments()

        print("📦 Firestore returned \(snapshot.documents.count) post documents")

        var posts: [Post] = []

        for document in snapshot.documents {
            do {
                let post = try document.data(as: Post.self)

                posts.append(post)

                print("✅ Decoded post: \(post.id ?? "NO-ID")")
                print("   Caption: \(post.caption)")
                print("   Owner: \(post.ownerId)")

            } catch {
                print("❌ FAILED TO DECODE POST")
                print("📄 Document ID: \(document.documentID)")
                print("❌ Error: \(error)")
                print("📄 Firestore data:")
                print(document.data())
            }
        }

        print("✅ FeedService loaded \(posts.count) posts")

        return posts
    }

    // 2️⃣ Fetch all users
    func fetchUsers() async throws -> [UserModel] {
        print("📡 Fetching users ...")

        let snapshot = try await db.collection("users")
            .getDocuments()

        let users = snapshot.documents.compactMap {
            try? $0.data(as: UserModel.self)
        }

        print("✅ FeedService loaded \(users.count) users")

        return users
    }

    // 3️⃣ Fetch pets
    func fetchPets() async throws -> [Pet] {
        print("📡 Fetching pets ...")

        let snapshot = try await db.collection("pets")
            .getDocuments()

        let pets = snapshot.documents.compactMap {
            try? $0.data(as: Pet.self)
        }

        print("✅ FeedService loaded \(pets.count) pets")

        return pets
    }
}

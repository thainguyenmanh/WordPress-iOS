import Foundation

struct EditPostManager {
    func upload(_ post: AbstractPost, completion: ((_ post: AbstractPost?, _ error: Error?) -> Void)?) {
        let managedObjectContext = ContextManager.sharedInstance().mainContext
        let postService = PostService(managedObjectContext: managedObjectContext)
        postService.uploadPost(post, success: { uploadedPost in
            completion?(uploadedPost, nil)
        }) { error in
            completion?(nil, error)
        }
    }

    func update(_ post: AbstractPost, with action: PostEditorAction) {
        if action == .saveAsDraft {
            post.status = .draft
        } else if action == .publish {
            if post.date_created_gmt == nil {
                post.date_created_gmt = Date()
            }

            if post.status != .publishPrivate {
                post.status = .publish
            }
        } else if action == .publishNow {
            post.date_created_gmt = Date()

            if post.status != .publishPrivate {
                post.status = .publish
            }
        }
    }
}

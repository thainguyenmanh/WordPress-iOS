import UIKit
import React
import WPMediaPicker

class GutenbergController: UIViewController, PostEditor {

    var onClose: ((Bool, Bool) -> Void)?

    var isOpenedDirectlyForPhotoPost: Bool = false

    let post: AbstractPost
    let gutenberg: Gutenberg
    let editPostManager = EditPostManager()
    let navBarManager = PostEditorNavigationBarManager()

    lazy var mediaPickerHelper: GutenbergMediaPickerHelper = {
        return GutenbergMediaPickerHelper(context: self, post: post)
    }()

    /// Maintainer of state for editor - like for post button
    ///
    fileprivate lazy var postEditorStateContext: PostEditorStateContext = {
        return createEditorStateContext(for: post)
    }()

    var mainContext: NSManagedObjectContext {
        return ContextManager.sharedInstance().mainContext
    }

    var currentBlogCount: Int {
        let service = BlogService(managedObjectContext: mainContext)
        return service.blogCountForAllAccounts()
    }

    var isSingleSiteMode: Bool {
        return currentBlogCount <= 1 || post.hasRemote()
    }

    required init(post: AbstractPost) {
        guard let post = post as? Post else {
            fatalError()
        }
        self.post = post.createRevision()
        self.gutenberg = Gutenberg(props: ["initialData": post.content ?? ""])
        super.init(nibName: nil, bundle: nil)

        navBarManager.delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    deinit {
        gutenberg.invalidate()
    }

    override func loadView() {
        view = gutenberg.rootView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBar()
        reloadBlogPickerButton()
        gutenberg.delegate = self
    }

    func configureNavigationBar() {
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.accessibilityIdentifier = "Gutenberg Editor Navigation Bar"
        navigationItem.leftBarButtonItems = navBarManager.leftBarButtonItems
        navigationItem.rightBarButtonItems = navBarManager.rightBarButtonItems
    }

    func reloadBlogPickerButton() {
        var pickerTitle = post.blog.url ?? String()
        if let blogName = post.blog.settings?.name, blogName.isEmpty == false {
            pickerTitle = blogName
        }

        navBarManager.reloadBlogPickerButton(with: pickerTitle, enabled: !isSingleSiteMode)
    }

    @objc private func close(sender: UIBarButtonItem) {
        close(didSave: false)
    }

    private func close(didSave: Bool) {
        onClose?(didSave, false)
    }
}

extension GutenbergController {
    func closeButtonPressed() {
        close(didSave: false)
    }

    func saveButtonPressed(with content: String) {
        post.content = content
        let postAction = postEditorStateContext.action
        editPostManager.update(post, with: postAction)
        editPostManager.upload(post) { [weak self] (uploadedPost, error) in
            self?.postEditorStateContext.updated(isBeingPublished: false)
            DispatchQueue.main.async { [weak self] in
                self?.close(didSave: true)
            }
        }
    }
}

extension GutenbergController: GutenbergBridgeDelegate {
    func gutenbergDidRequestMediaPicker(callback: @escaping MediaPickerDidPickMediaCallback) {
        mediaPickerHelper.presentMediaPickerFullScreen(animated: true,
                                                       dataSourceType: .mediaLibrary,
                                                       callback: callback)
    }

    func gutenbergDidProvideHTML(_ html: String, changed: Bool) {
        saveButtonPressed(with: html)
    }
}

extension GutenbergController: PostEditorNavigationBarManagerDelegate {
    var publishButtonText: String {
        return postEditorStateContext.publishButtonText
    }

    var isPublishButtonEnabled: Bool {
        return postEditorStateContext.isPublishButtonEnabled
    }

    var uploadingButtonSize: CGSize {
        return AztecPostViewController.Constants.uploadingButtonSize
    }

    func navigationBarManager(_ manager: PostEditorNavigationBarManager, closeWasPressed sender: UIButton) {
        close(didSave: false)
    }

    func navigationBarManager(_ manager: PostEditorNavigationBarManager, moreWasPressed sender: UIButton) {

    }

    func navigationBarManager(_ manager: PostEditorNavigationBarManager, blogPickerWasPressed sender: UIButton) {

    }

    func navigationBarManager(_ manager: PostEditorNavigationBarManager, publishButtonWasPressed sender: UIButton) {
        postEditorStateContext.updated(isBeingPublished: true)
        gutenberg.requestHTML()
    }

    func navigationBarManager(_ manager: PostEditorNavigationBarManager, displayCancelMediaUploads sender: UIButton) {

    }
}

extension GutenbergController: PostEditorStateContextDelegate {
    func context(_ context: PostEditorStateContext, didChangeAction: PostEditorAction) {
        navBarManager.reloadPublishButton()
    }

    func context(_ context: PostEditorStateContext, didChangeActionAllowed: Bool) {
        navBarManager.reloadPublishButton()
    }
}

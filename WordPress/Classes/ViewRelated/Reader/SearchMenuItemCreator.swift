import Gridicons

final class SearchMenuItemCreator {
    func menuItem() -> ReaderMenuItem {
        let title = NSLocalizedString("Search", comment: "Title of the reader's Search menu item.")
        var item =  ReaderMenuItem(title: title, type: .search)
        item.order = ReaderDefaultMenuItemOrder.search.rawValue
        item.icon = Gridicon.iconOfType(.search)

        return item
    }
}

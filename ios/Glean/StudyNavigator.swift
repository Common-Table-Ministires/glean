import Foundation
import SwiftUI

/// Shared “open this passage in Study” bus between Feed and the Study tab.
final class StudyNavigator: ObservableObject {
    enum Tab: Int, Hashable {
        case feed = 0
        case study = 1
        case stories = 2
        case settings = 3
    }

    @Published var selectedTab: Tab = .feed

    /// Bumps so Study reloads even if book/chapter/verse values are unchanged.
    @Published private(set) var jumpToken: Int = 0

    @Published private(set) var bookOrder: Int = UserDefaults.standard.object(forKey: "study.bookOrder") as? Int ?? 1
    @Published private(set) var chapter: Int = UserDefaults.standard.object(forKey: "study.chapter") as? Int ?? 1
    @Published private(set) var verse: Int = UserDefaults.standard.object(forKey: "study.verse") as? Int ?? 1

    func openStudy(bookOrder: Int, chapter: Int, verse: Int) {
        self.bookOrder = max(1, bookOrder)
        self.chapter = max(1, chapter)
        self.verse = max(1, verse)
        // Keep Study’s AppStorage in sync for persistence across launches.
        UserDefaults.standard.set(self.bookOrder, forKey: "study.bookOrder")
        UserDefaults.standard.set(self.chapter, forKey: "study.chapter")
        UserDefaults.standard.set(self.verse, forKey: "study.verse")
        jumpToken &+= 1
        selectedTab = .study
    }
}

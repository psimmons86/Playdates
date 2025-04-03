import SwiftUI
import Combine

class MainContainerViewModel: ObservableObject {
    @Published var selectedView: AppView = .home
    @Published var isShowingSideMenu = false
    
    static let shared = MainContainerViewModel()
    
    private init() {}
}

import SwiftUI

// MARK: - RootTabView

struct RootTabView: View {
    var body: some View {
        TabView {
            Tab("菜品", systemImage: "book.fill") {
                NavigationStack { DishBookView() }
            }

            Tab("点餐", systemImage: "fork.knife") {
                NavigationStack { MenuHubView() }
            }

            Tab("冰箱", systemImage: "refrigerator") {
                NavigationStack { FridgeView() }
            }

            Tab("我的", systemImage: "person.fill") {
                NavigationStack { ProfileView() }
            }
        }
    }
}

#Preview { RootTabView() }

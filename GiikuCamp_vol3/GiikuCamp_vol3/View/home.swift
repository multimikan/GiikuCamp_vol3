import SwiftUI

struct Home: View {
    var body: some View {
        NavigationStack {
            List {
                Text("harubou")
            }
            .navigationTitle("Home")
        }
    }
}




#Preview {
    Home()
}

import SwiftUI

struct Home: View {
    
    init() {
    @StateObject var cloudViewModel = CloudViewModel()
        
    // ViewModelの初期化
    let cloudVM = CloudViewModel()
    _cloudViewModel = StateObject(wrappedValue: cloudVM)
}
    
    var body: some View {
        CameraView()
    }
}




#Preview {
    Home()
}

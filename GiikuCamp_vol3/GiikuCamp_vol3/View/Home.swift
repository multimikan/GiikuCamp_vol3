import SwiftUI

struct Home: View {
    init() {
    @StateObject var cloudViewModel = CloudViewModel()
        
    // ViewModelの初期化
    let cloudVM = CloudViewModel()
    _cloudViewModel = StateObject(wrappedValue: cloudVM)
}
    
    var body: some View {
        // 直接HumburgerMenuSampleViewを表示
        // CameraViewはすでにHumburgerMenuSampleView内に含まれている
        HumburgerMenuSampleView()
    }
}

#Preview {
    Home()
}

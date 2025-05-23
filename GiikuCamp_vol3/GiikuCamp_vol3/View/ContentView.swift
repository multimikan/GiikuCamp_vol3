//
//  ContentView.swift
//  GiikuCamp_vol3
//
//  Created by tknooa on 2025/05/16.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var cloudViewModel = CloudViewModel()
    
    var body: some View {
        if cloudViewModel.data.isAgree {
            SampleCameraView()
        }
        else{
            TermsAgreementView(onAgree: {SignInOptionsView()})
        }
    }
}

#Preview {
    ContentView()
}

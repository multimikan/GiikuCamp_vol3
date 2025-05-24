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
        NavigationView{
            if !cloudViewModel.data.isAgree {
                TermsAgreementView(onAgree:{})
            }
            else if !authViewModel.isAuthenticated{
                SignInOptionsView()
            }
            else{
                Home()
            }
        }.onAppear {
            // 既存のユーザーがいるか確認
            if authViewModel.getCurrentUser() != nil {
                authViewModel.isAuthenticated = true
            }
        }
    }
}

#Preview {
    ContentView()
}

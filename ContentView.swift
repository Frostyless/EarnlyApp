//
//  ContentView.swift
//  Earnly V2
//
//  Created by Ivan Lam on 7/6/25.
//

import SwiftUI

// MARK: - Content View (Navigation Controller)
struct ContentView: View {
    @StateObject private var appState = AppState()
    
    var body: some View {
        NavigationView {
            switch appState.currentView {
            case .loading:
                LoadingView()
            case .dashboard:
                DashboardView()
            case .accounts:
                AccountsView()
            case .jobEdit:
                JobEditView()
            case .addJob:
                AddJobView()
            }
        }
        .environmentObject(appState)
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

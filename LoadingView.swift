//
//  LoadingView.swift
//  Earnly V2
//
//  Created by Ivan Lam on 7/6/25.
//

import SwiftUI

// MARK: - Loading/Welcome Screen
struct LoadingView: View {
    @EnvironmentObject var appState: AppState
    @State private var logoOpacity = 0.0
    
    var body: some View {
        ZStack {
            AppBackground()
            
            VStack {
                Spacer()
                
                Text("Earnly")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.6))
                    .opacity(logoOpacity)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1.0)) {
                            logoOpacity = 1.0
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation(.easeInOut(duration: 0.8)) {
                                appState.currentView = .dashboard
                            }
                        }
                    }
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
    }
}


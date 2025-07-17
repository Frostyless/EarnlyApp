//
//  AccountsView.swift
//  Earnly V2
//
//  Created by Ivan Lam on 7/6/25.
//

import SwiftUI
// MARK: - Accounts View
struct AccountsView: View {
    @EnvironmentObject var appState: AppState
    @State private var isVisible = false
    @State private var contentOpacity = 0.0
    
    var body: some View {
        ZStack {
            AppBackground()
            
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            appState.currentView = .dashboard
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Text("Account")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Invisible spacer for centering
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .opacity(0)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Section
                        VStack(spacing: 16) {
                            Circle()
                                .fill(Color(red: 0.4, green: 0.8, blue: 0.6))
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Text("JD")
                                        .font(.title)
                                        .foregroundColor(.white)
                                        .fontWeight(.bold)
                                )
                                .scaleEffect(isVisible ? 1.0 : 0.8)
                                .animation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0), value: isVisible)
                            
                            Text(appState.userName)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                        .padding(.top, 20)
                        
                        // Your Jobs Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Your Jobs")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Button(action: {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        appState.currentView = .addJob
                                    }
                                }) {
                                    Image(systemName: "plus")
                                        .font(.title3)
                                        .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.6))
                                        .scaleEffect(isVisible ? 1.0 : 0.5)
                                        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2), value: isVisible)
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            VStack(spacing: 12) {
                                ForEach(Array(appState.jobs.enumerated()), id: \.element.id) { index, job in
                                    JobCard(job: job, isActive: appState.activeJob?.id == job.id)
                                        .offset(x: isVisible ? 0 : 50)
                                        .opacity(isVisible ? 1.0 : 0)
                                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double(index) * 0.1), value: isVisible)
                                        .onTapGesture {
                                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                                appState.selectedJob = job
                                                appState.currentView = .jobEdit
                                            }
                                        }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        Spacer(minLength: 100)
                    }
                }
                .opacity(contentOpacity)
            }
        }
        .offset(x: isVisible ? 0 : -UIScreen.main.bounds.width)
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.6)) {
                        isVisible = true
                    }
                    
                    withAnimation(.easeOut(duration: 0.4).delay(0.2)) {
                        contentOpacity = 1.0
                    }
                }
                .onDisappear {
                    isVisible = false
                    contentOpacity = 0.0
                }
            }
        }

// MARK: - Job Card Component
struct JobCard: View {
    let job: Job
    let isActive: Bool
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(job.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    if isActive {
                        Text("Active Job")
                            .font(.caption)
                            .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.6))
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    if !isActive {
                        Button("Set Active") {
                            appState.setActiveJob(job)
                        }
                        .font(.caption)
                        .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.6))
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            VStack(spacing: 12) {
                HStack {
                    Text("Hourly Rate")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Spacer()
                    
                    Text("$\(String(format: "%.2f", job.hourlyRate))")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.6))
                }
                
                HStack {
                    Text("Hours Worked Today")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Spacer()
                    
                    Text("\(String(format: "%.1f", job.hoursWorkedToday)) hrs")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
                
                HStack {
                    Text("Total Lifetime Hours")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Spacer()
                    
                    Text("\(String(format: "%.1f", job.lifetimeHours)) hrs")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
                
                HStack {
                    Text("Schedule")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Spacer()
                    
                    Text("\(job.workStartTime) - \(job.workEndTime)")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(isActive ? 0.15 : 0.1))
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isActive ? Color(red: 0.4, green: 0.8, blue: 0.6).opacity(0.5) : Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}


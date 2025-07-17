//
//  DashboardView.swift
//  Earnly V2
//
//  Created by Ivan Lam on 7/6/25.
//

import SwiftUI

// MARK: - Dashboard Screen
struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    @State private var animateElements = false
    @State private var currentTime = Date()
    @State private var isRefreshing = false


    var body: some View {
        ZStack {
            AppBackground()
            
            VStack(spacing: 0) {
                // Top Bar
                HStack {
                    Button(action: {
                        appState.currentView = .accounts
                    }) {
                        Circle()
                            .fill(Color(red: 0.4, green: 0.8, blue: 0.6))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Text("JD")
                                    .foregroundColor(.white)
                                    .fontWeight(.semibold)
                            )
                    }
                    
                    Spacer()
                    
                    // Current time display
                    Text(currentTime, formatter: timeFormatter)
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
                            currentTime = Date()
                            // Recalculate earnings every minute
                            if Calendar.current.component(.second, from: currentTime) == 0 {
                                appState.calculateTodaysEarnings()
                            }
                        }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .offset(y: animateElements ? 0 : 100)
                .opacity(animateElements ? 1 : 0)
                
                ScrollView {
                    VStack(spacing: 24) {
                        if isRefreshing {
                                    HStack {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                            .tint(Color(red: 0.4, green: 0.8, blue: 0.6))
                                    }
                                    .padding(.bottom, 8)
                                }
                        // Active Job Status
                        if let activeJob = appState.activeJob {
                            ActiveJobCard(job: activeJob)
                                .padding(.horizontal, 20)
                                .offset(y: animateElements ? 0 : 100)
                                .opacity(animateElements ? 1 : 0)
                                .animation(.easeOut(duration: 0.6).delay(0.05), value: animateElements)
                        }
                        
                        // Lifetime Earnings Section
                        VStack(spacing: 8) {
                            Text("Lifetime Earnings")
                                .font(.title3)
                                .fontWeight(.medium)
                                .foregroundColor(.white.opacity(0.7))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Text("$\(String(format: "%.2f", appState.lifetimeEarnings))")
                                .font(.system(size: 42, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal, 20)
                        .offset(y: animateElements ? 0 : 100)
                        .opacity(animateElements ? 1 : 0)
                        .animation(.easeOut(duration: 0.6).delay(0.1), value: animateElements)
                        
                        // Today's Earnings Card
                        EarningsCard(
                            title: "Today",
                            amount: appState.todaysEarnings,
                            isToday: true,
                            progress: appState.getTodaysWorkProgress()
                        )
                        .padding(.horizontal, 20)
                        .offset(y: animateElements ? 0 : 100)
                        .opacity(animateElements ? 1 : 0)
                        .animation(.easeOut(duration: 0.6).delay(0.2), value: animateElements)
                        
                        // Past Earnings Section
                        PastEarningsSection()
                            .padding(.horizontal, 20)
                            .offset(y: animateElements ? 0 : 100)
                            .opacity(animateElements ? 1 : 0)
                            .animation(.easeOut(duration: 0.6).delay(0.3), value: animateElements)
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.top, 20)
                }
                .refreshable {
                    isRefreshing = true
                    await appState.refreshData()
                    isRefreshing = false
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation {
                animateElements = true
            }
        }
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
}

// MARK: - Active Job Card
struct ActiveJobCard: View {
    let job: Job
    @State private var isWorking = false
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Currently Active")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text(job.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(isWorking ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                        
                        Text(isWorking ? "Working" : "Off Hours")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Text("$\(String(format: "%.2f", job.hourlyRate))/hr")
                        .font(.caption)
                        .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.6))
                }
            }
            
            // Work schedule display
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Work Hours")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    Text("\(job.workStartTime) - \(job.workEndTime)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Lunch Break")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    Text("\(job.lunchStartTime) - \(job.lunchEndTime)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.08))
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isWorking ? Color.green.opacity(0.5) : Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
        .onAppear {
            updateWorkingStatus()
        }
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { _ in
            updateWorkingStatus()
        }
    }
    
    private func updateWorkingStatus() {
        isWorking = job.isCurrentlyWorkingTime()
    }
}

// MARK: - Earnings Card Component
struct EarningsCard: View {
    let title: String
    let amount: Double
    let isToday: Bool
    let progress: Double
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    if isToday {
                        Text("Keep it up!")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                Spacer()
                
                Text("+$\(String(format: "%.2f", amount))")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.6))
            }
            
            if isToday {
                // Progress indicator for today
                GeometryReader { geometry in
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(Color(red: 0.4, green: 0.8, blue: 0.6))
                            .frame(width: geometry.size.width * progress, height: 4)
                            .cornerRadius(2)
                        
                        Rectangle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: geometry.size.width * (1 - progress), height: 4)
                            .cornerRadius(2)
                    }
                }
                .frame(height: 4)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Past Earnings Section
struct PastEarningsSection: View {
    @EnvironmentObject var appState: AppState
    
    var displayedEarnings: [DailyEarning] {
        if appState.showAllPastEarnings {
            return appState.pastEarnings
        } else {
            return Array(appState.pastEarnings.prefix(3))
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Past Earnings")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                ForEach(displayedEarnings) { earning in
                    HStack {
                        Text(appState.formatDateForDisplay(earning.date))
                            .font(.body)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text("+$\(String(format: "%.2f", earning.amount))")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.6))
                    }
                    .padding(.vertical, 8)
                    
                    if earning.id != displayedEarnings.last?.id {
                        Divider()
                            .background(Color.white.opacity(0.2))
                    }
                }
                
                if !appState.showAllPastEarnings {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            appState.showAllPastEarnings = true
                        }
                    }) {
                        HStack {
                            Text("View past earnings")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.6))
                            
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.6))
                        }
                        .padding(.top, 8)
                    }
                } else {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            appState.showAllPastEarnings = false
                        }
                    }) {
                        HStack {
                            Text("Show less")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.6))
                            
                            Image(systemName: "chevron.up")
                                .font(.caption)
                                .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.6))
                        }
                        .padding(.top, 8)
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.1))
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
        }
    }
}

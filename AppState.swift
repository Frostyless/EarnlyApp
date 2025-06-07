//
//  AppState.swift
//  Earnly V2
//
//  Created by Ivan Lam on 7/6/25.
//

import Foundation

// MARK: - App State
class AppState: ObservableObject {
    @Published var currentView: AppView = .loading
    @Published var userName: String = "John Doe"
    @Published var currentEarnings: Double = 0.0
    @Published var lifetimeEarnings: Double = 5847.23
    @Published var todaysEarnings: Double = 0.0
    @Published var hoursWorked: Double = 0.0
    @Published var showAllPastEarnings: Bool = false
    @Published var jobs: [Job] = []
    @Published var selectedJob: Job?
    @Published var activeJob: Job?
    @Published var pastEarnings: [DailyEarning] = [
        DailyEarning(date: "Yesterday", amount: 118.75),
        DailyEarning(date: "12 May", amount: 135.25),
        DailyEarning(date: "11 May", amount: 142.80),
        DailyEarning(date: "10 May", amount: 128.60),
        DailyEarning(date: "9 May", amount: 156.90),
        DailyEarning(date: "8 May", amount: 125.40),
        DailyEarning(date: "7 May", amount: 145.20),
        DailyEarning(date: "6 May", amount: 132.85),
        DailyEarning(date: "5 May", amount: 149.30),
        DailyEarning(date: "4 May", amount: 127.65)
    ]
    
    enum AppView {
        case loading, dashboard, accounts, jobEdit, addJob
    }
    
    init() {
        // Load sample jobs
        jobs = [
            Job(title: "Software Developer",
                monthlySalary: 5000.0,
                workStartTime: "08:00",
                workEndTime: "18:00",
                lunchStartTime: "12:00",
                lunchEndTime: "13:00",
                hoursWorkedToday: 0.0,
                lifetimeHours: 1847.5,
                workingDays: 22),
            Job(title: "Freelance Designer",
                monthlySalary: 3200.0,
                workStartTime: "09:00",
                workEndTime: "17:00",
                lunchStartTime: "12:30",
                lunchEndTime: "13:30",
                hoursWorkedToday: 0.0,
                lifetimeHours: 892.0,
                workingDays: 20)
        ]
        
        // Set first job as active by default
        activeJob = jobs.first
        
        // Calculate today's earnings using lazy load
        calculateTodaysEarnings()
    }
    
    func calculateTodaysEarnings() {
        guard let job = activeJob else {
            todaysEarnings = 0.0
            return
        }
        
        let now = Date()
        let calendar = Calendar.current
        
        // Check if it's a weekday
        let weekday = calendar.component(.weekday, from: now)
        guard weekday >= 2 && weekday <= 6 else {
            todaysEarnings = 0.0
            return
        }
        
        // Get work times in minutes
        let workStartMinutes = timeToMinutes(job.workStartTime)
        let workEndMinutes = timeToMinutes(job.workEndTime)
        let lunchStartMinutes = timeToMinutes(job.lunchStartTime)
        let lunchEndMinutes = timeToMinutes(job.lunchEndTime)
        
        // Current time in minutes
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        let currentTimeMinutes = currentHour * 60 + currentMinute
        
        // Calculate worked minutes so far today
        var workedMinutes = 0
        
        if currentTimeMinutes > workStartMinutes {
            let endTime = min(currentTimeMinutes, workEndMinutes)
            workedMinutes = endTime - workStartMinutes
            
            // Subtract lunch time if applicable
            if currentTimeMinutes > lunchEndMinutes {
                // Full lunch break taken
                workedMinutes -= (lunchEndMinutes - lunchStartMinutes)
            } else if currentTimeMinutes > lunchStartMinutes {
                // Currently in lunch break
                workedMinutes -= (currentTimeMinutes - lunchStartMinutes)
            }
            
            // Ensure we don't have negative minutes
            workedMinutes = max(0, workedMinutes)
        }
        
        // Calculate today's earnings
        let hoursWorked = Double(workedMinutes) / 60.0
        todaysEarnings = hoursWorked * job.hourlyRate
        
        // Update hours worked today in the job
        if let index = jobs.firstIndex(where: { $0.id == job.id }) {
            jobs[index].hoursWorkedToday = hoursWorked
        }
    }
    
    func getTodaysWorkProgress() -> Double {
        guard let job = activeJob else { return 0.0 }
        
        let now = Date()
        let calendar = Calendar.current
        
        // Check if it's a weekday
        let weekday = calendar.component(.weekday, from: now)
        guard weekday >= 2 && weekday <= 6 else { return 0.0 }
        
        let workStartMinutes = timeToMinutes(job.workStartTime)
        let workEndMinutes = timeToMinutes(job.workEndTime)
        let lunchStartMinutes = timeToMinutes(job.lunchStartTime)
        let lunchEndMinutes = timeToMinutes(job.lunchEndTime)
        
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        let currentTimeMinutes = currentHour * 60 + currentMinute
        
        // Total work minutes in a day (excluding lunch)
        let totalWorkMinutes = (workEndMinutes - workStartMinutes) - (lunchEndMinutes - lunchStartMinutes)
        
        // Calculate worked minutes so far
        var workedMinutes = 0
        
        if currentTimeMinutes > workStartMinutes {
            let endTime = min(currentTimeMinutes, workEndMinutes)
            workedMinutes = endTime - workStartMinutes
            
            // Subtract lunch time if applicable
            if currentTimeMinutes > lunchEndMinutes {
                workedMinutes -= (lunchEndMinutes - lunchStartMinutes)
            } else if currentTimeMinutes > lunchStartMinutes {
                workedMinutes -= (currentTimeMinutes - lunchStartMinutes)
            }
            
            workedMinutes = max(0, workedMinutes)
        }
        
        return min(Double(workedMinutes) / Double(totalWorkMinutes), 1.0)
    }
    
    private func timeToMinutes(_ timeString: String) -> Int {
        let components = timeString.split(separator: ":")
        guard components.count == 2,
              let hours = Int(components[0]),
              let minutes = Int(components[1]) else {
            return 0
        }
        return hours * 60 + minutes
    }
    
    func setActiveJob(_ job: Job) {
        activeJob = job
        calculateTodaysEarnings() // Recalculate when active job changes
    }
    
    func addJob(_ job: Job) {
        jobs.append(job)
        if activeJob == nil {
            activeJob = job
            calculateTodaysEarnings()
        }
    }
    
    func updateJob(_ updatedJob: Job) {
        if let index = jobs.firstIndex(where: { $0.id == updatedJob.id }) {
            jobs[index] = updatedJob
            if activeJob?.id == updatedJob.id {
                activeJob = updatedJob
                calculateTodaysEarnings()
            }
        }
    }
}

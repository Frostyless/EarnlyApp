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
    @Published var userName: String = "John Doe" {
        didSet {
            saveUserData()
        }
    }
    @Published var currentEarnings: Double = 0.0
    @Published var lifetimeEarnings: Double = 5847.23 {
        didSet {
            saveUserData()
        }
    }
    @Published var todaysEarnings: Double = 0.0
    @Published var hoursWorked: Double = 0.0
    @Published var showAllPastEarnings: Bool = false
    @Published var jobs: [Job] = [] {
        didSet {
            saveJobs()
        }
    }
    @Published var selectedJob: Job?
    @Published var activeJob: Job? {
        didSet {
            saveActiveJobID()
        }
    }
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
    ] {
        didSet {
            savePastEarnings()
        }
    }
    
    enum AppView {
        case loading, dashboard, accounts, jobEdit, addJob
    }
    
    init() {
        loadUserData()
        loadJobs()
        loadPastEarnings()
        loadActiveJob()
        
        // If no saved jobs, create sample jobs
        if jobs.isEmpty {
            createSampleJobs()
        }
        
        // Set active job if none is set
        if activeJob == nil && !jobs.isEmpty {
            activeJob = jobs.first
        }
        
        // Calculate today's earnings
        calculateTodaysEarnings()
    }
    
    // MARK: - Sample Data Creation
    private func createSampleJobs() {
        jobs = [
            Job(title: "Software Developer",
                monthlySalary: 5000.0,
                workStartTime: "08:00",
                workEndTime: "18:00",
                lunchStartTime: "12:00",
                lunchEndTime: "13:00",
                hoursWorkedToday: 0.0,
                lifetimeHours: 1847.5,
                ),
            Job(title: "Freelance Designer",
                monthlySalary: 3200.0,
                workStartTime: "09:00",
                workEndTime: "17:00",
                lunchStartTime: "12:30",
                lunchEndTime: "13:30",
                hoursWorkedToday: 0.0,
                lifetimeHours: 892.0,
              )
        ]
    }
    
    // MARK: - Persistence Methods
    private func saveJobs() {
        do {
            let encoded = try JSONEncoder().encode(jobs)
            UserDefaults.standard.set(encoded, forKey: "SavedJobs")
            print("✅ Jobs saved successfully")
        } catch {
            print("❌ Failed to save jobs: \(error)")
        }
    }
    
    private func loadJobs() {
        guard let data = UserDefaults.standard.data(forKey: "SavedJobs"),
              let decoded = try? JSONDecoder().decode([Job].self, from: data) else {
            print("📝 No saved jobs found")
            return
        }
        jobs = decoded
        print("✅ Loaded \(jobs.count) jobs")
    }
    
    private func saveUserData() {
        UserDefaults.standard.set(userName, forKey: "UserName")
        UserDefaults.standard.set(lifetimeEarnings, forKey: "LifetimeEarnings")
    }
    
    private func loadUserData() {
        userName = UserDefaults.standard.string(forKey: "UserName") ?? "John Doe"
        lifetimeEarnings = UserDefaults.standard.double(forKey: "LifetimeEarnings")
        if lifetimeEarnings == 0 {
            lifetimeEarnings = 5847.23 // Default value
        }
    }
    
    private func saveActiveJobID() {
        if let activeJob = activeJob {
            UserDefaults.standard.set(activeJob.id.uuidString, forKey: "ActiveJobID")
        } else {
            UserDefaults.standard.removeObject(forKey: "ActiveJobID")
        }
    }
    
    private func loadActiveJob() {
        guard let activeJobIDString = UserDefaults.standard.string(forKey: "ActiveJobID"),
              let activeJobID = UUID(uuidString: activeJobIDString) else {
            return
        }
        
        activeJob = jobs.first { $0.id == activeJobID }
    }
    
    private func savePastEarnings() {
        do {
            let encoded = try JSONEncoder().encode(pastEarnings)
            UserDefaults.standard.set(encoded, forKey: "PastEarnings")
        } catch {
            print("❌ Failed to save past earnings: \(error)")
        }
    }
    
    private func loadPastEarnings() {
        guard let data = UserDefaults.standard.data(forKey: "PastEarnings"),
              let decoded = try? JSONDecoder().decode([DailyEarning].self, from: data) else {
            return // Keep default values
        }
        pastEarnings = decoded
    }
    
    // MARK: - Existing Methods (unchanged)
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
    }
    
    func addJob(_ job: Job) {
        jobs.append(job)
        if activeJob == nil {
            activeJob = job
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
    
    // MARK: - Clear Data (for testing)
    func clearAllData() {
        UserDefaults.standard.removeObject(forKey: "SavedJobs")
        UserDefaults.standard.removeObject(forKey: "UserName")
        UserDefaults.standard.removeObject(forKey: "LifetimeEarnings")
        UserDefaults.standard.removeObject(forKey: "ActiveJobID")
        UserDefaults.standard.removeObject(forKey: "PastEarnings")
        print("🗑️ All data cleared")
    }
}

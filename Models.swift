//
//  Models.swift
//  Earnly V2
//
//  Created by Ivan Lam on 7/6/25.
//

import Foundation

// MARK: - Job Model
struct Job: Identifiable {
    let id = UUID()
    var title: String
    var monthlySalary: Double
    var workStartTime: String // Format: "HH:mm"
    var workEndTime: String   // Format: "HH:mm"
    var lunchStartTime: String // Format: "HH:mm"
    var lunchEndTime: String   // Format: "HH:mm"
    var hoursWorkedToday: Double
    var lifetimeHours: Double
    var workingDays: Int // Working days per month
    var customHourlyRate: Double? // Optional custom rate
    
    var hourlyRate: Double {
        if let customRate = customHourlyRate {
            return customRate
        }
        let dailyHours = calculateDailyWorkingHours()
        return monthlySalary / (dailyHours * Double(workingDays))
    }
    
    var earningsPerMinute: Double {
        return hourlyRate / 60.0
    }
    
    func calculateDailyWorkingHours() -> Double {
        let workStart = timeToMinutes(workStartTime)
        let workEnd = timeToMinutes(workEndTime)
        let lunchStart = timeToMinutes(lunchStartTime)
        let lunchEnd = timeToMinutes(lunchEndTime)
        
        let totalWorkMinutes = workEnd - workStart
        let lunchMinutes = lunchEnd - lunchStart
        let actualWorkMinutes = totalWorkMinutes - lunchMinutes
        
        return Double(actualWorkMinutes) / 60.0
    }
    
    func isCurrentlyWorkingTime() -> Bool {
        let now = Date()
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        let currentTimeInMinutes = currentHour * 60 + currentMinute
        
        let workStart = timeToMinutes(workStartTime)
        let workEnd = timeToMinutes(workEndTime)
        let lunchStart = timeToMinutes(lunchStartTime)
        let lunchEnd = timeToMinutes(lunchEndTime)
        
        // Check if within work hours
        let isWithinWorkHours = currentTimeInMinutes >= workStart && currentTimeInMinutes <= workEnd
        
        // Check if not during lunch
        let isNotLunchTime = !(currentTimeInMinutes >= lunchStart && currentTimeInMinutes <= lunchEnd)
        
        // Check if it's a weekday (Monday = 2, Friday = 6 in Calendar.current)
        let weekday = calendar.component(.weekday, from: now)
        let isWeekday = weekday >= 2 && weekday <= 6
        
        return isWithinWorkHours && isNotLunchTime && isWeekday
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
}

// MARK: - Daily Earning Model
struct DailyEarning: Identifiable {
    let id = UUID()
    let date: String
    let amount: Double
}

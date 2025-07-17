import Foundation

// MARK: - Work Session Model
struct WorkSession: Codable {
    let date: Date
    let hoursWorked: Double
    let earnings: Double
    let jobId: UUID
    
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}


// MARK: - Add to your AppState class
extension AppState {
    
    // MARK: - Refresh Function
    @MainActor
    func refreshData() async {
        print("🔄 Starting data refresh...")
        
        // Show loading state briefly for user feedback
        await withCheckedContinuation { continuation in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                continuation.resume()
            }
        }
        
        // Recalculate missed work sessions
        calculateMissedWorkSessions()
        
        // Recalculate today's earnings
        calculateTodaysEarnings()
        
        // Force update of computed properties
        objectWillChange.send()
        
        print("✅ Data refresh completed")
        print("💎 Updated lifetime earnings: $\(String(format: "%.2f", lifetimeEarnings))")
    }
    
    // MARK: - Manual Refresh (for debugging)
    func manualRefresh() {
        print("🔄 Manual refresh triggered")
        calculateMissedWorkSessions()
        calculateTodaysEarnings()
        objectWillChange.send()
    }
}
// MARK: - App State
class AppState: ObservableObject {
    @Published var currentView: AppView = .loading
    @Published var userName: String = "John Doe" {
        didSet {
            saveUserData()
        }
    }
    
    // NEW: Separated earnings tracking
    @Published var workSessionEarnings: Double = 0.0 {
        didSet {
            saveUserData()
            print("💰 Work session earnings updated: $\(workSessionEarnings)")
            print("💎 New lifetime earnings: $\(lifetimeEarnings)")
        }
    }
    @Published var todaysEarnings: Double = 0.0 {
        didSet {
            print("📅 Today's earnings updated: $\(todaysEarnings)")
            print("💎 Current lifetime earnings: $\(lifetimeEarnings)")
        }
    }
    
    // COMPUTED: Lifetime earnings = past work + today's work
    var lifetimeEarnings: Double {
        let total = workSessionEarnings + todaysEarnings
        return total
    }
    
    @Published var hoursWorked: Double = 0.0
    @Published var showAllPastEarnings: Bool = false
    
    // NEW: Work session tracking
    @Published var workSessions: [WorkSession] = [] {
        didSet {
            saveWorkSessions()
        }
    }
    @Published var lastWorkSessionDate: Date? {
        didSet {
            saveLastWorkSessionDate()
        }
    }
    
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
    @Published var pastEarnings: [DailyEarning] = [] {
        didSet {
            savePastEarnings()
        }
    }
    
    enum AppView {
        case loading, dashboard, accounts, jobEdit, addJob
    }
    
    init() {
        // Load data first
        loadUserData()
        loadJobs()
        loadPastEarnings()
        loadActiveJob()
        loadWorkSessions()
        loadLastWorkSessionDate()
        
        print("🚀 Initial data loaded:")
        print("💰 Loaded work session earnings: $\(workSessionEarnings)")
        print("📊 Loaded \(workSessions.count) work sessions")
        
        // Set active job if none is set
        if activeJob == nil && !jobs.isEmpty {
            activeJob = jobs.first
        }
        
        // Calculate missed work sessions since last app open
        calculateMissedWorkSessions()
        
        // Calculate today's earnings AFTER missed work sessions
        calculateTodaysEarnings()
        
        printAppStateDebugInfo()
    }
    
    // MARK: - Work Session Calculation (FIXED)
    private func calculateMissedWorkSessions() {
        guard let activeJob = activeJob else {
            print("⚠️ No active job found, skipping missed work session calculation")
            return
        }
        
        let today = Calendar.current.startOfDay(for: Date())
        
        // FIXED: Handle first launch case
        let lastSessionDate: Date
        if let savedLastSessionDate = lastWorkSessionDate {
            lastSessionDate = savedLastSessionDate
            print("📅 Using saved last session date: \(savedLastSessionDate)")
        } else {
            // First launch - calculate from a reasonable start date
            lastSessionDate = Calendar.current.date(byAdding: .day, value: -7, to: today) ?? today
            print("📅 First launch detected. Starting calculation from: \(lastSessionDate)")
        }
        
        // Don't process if we already processed today
        if Calendar.current.isDate(lastSessionDate, inSameDayAs: today) {
            print("📅 Already processed today, skipping")
            return
        }
        
        print("📅 Calculating missed work sessions from \(lastSessionDate) to \(today)")
        print("💰 Current work session earnings before calculation: $\(workSessionEarnings)")
        
        var currentDate = Calendar.current.date(byAdding: .day, value: 1, to: lastSessionDate) ?? today
        var totalMissedEarnings: Double = 0.0
        var newPastEarnings: [DailyEarning] = []
        var addedSessionsCount = 0
        
        while currentDate < today {
            if isWorkday(currentDate) {
                let dailyEarnings = calculateFullDayEarnings(for: activeJob)
                let dailyHours = calculateFullDayHours(for: activeJob)
                
                let workSession = WorkSession(
                    date: currentDate,
                    hoursWorked: dailyHours,
                    earnings: dailyEarnings,
                    jobId: activeJob.id
                )
                
                workSessions.append(workSession)
                totalMissedEarnings += dailyEarnings
                addedSessionsCount += 1
                
                // Add to past earnings for UI display
                let dateString = formatDateForPastEarnings(currentDate)
                let dailyEarning = DailyEarning(date: dateString, amount: dailyEarnings)
                newPastEarnings.append(dailyEarning)
                
                print("💰 Added work session for \(formatDateForPastEarnings(currentDate)): $\(String(format: "%.2f", dailyEarnings))")
            }
            
            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) ?? today
        }
        
        // Add new past earnings to the beginning of the array (most recent first)
        if !newPastEarnings.isEmpty {
            // Sort new earnings by date (most recent first)
            newPastEarnings.sort { first, second in
                let firstDate = parseDateFromPastEarnings(first.date)
                let secondDate = parseDateFromPastEarnings(second.date)
                return firstDate > secondDate
            }
            
            // Insert at the beginning of past earnings
            pastEarnings.insert(contentsOf: newPastEarnings, at: 0)
            
            print("📊 Added \(newPastEarnings.count) entries to past earnings")
        }
        
        // CRITICAL FIX: Update work session earnings EXPLICITLY
        if totalMissedEarnings > 0 {
            let previousWorkSessionEarnings = workSessionEarnings
            workSessionEarnings += totalMissedEarnings
            
            print("✅ MISSED WORK SESSIONS SUMMARY:")
            print("   📊 Sessions added: \(addedSessionsCount)")
            print("   💰 Previous work session earnings: $\(String(format: "%.2f", previousWorkSessionEarnings))")
            print("   💰 Total missed earnings: $\(String(format: "%.2f", totalMissedEarnings))")
            print("   💰 New work session earnings: $\(String(format: "%.2f", workSessionEarnings))")
            print("   💎 New lifetime earnings: $\(String(format: "%.2f", lifetimeEarnings))")
        } else {
            print("📅 No missed work sessions to add")
        }
        
        // Update last work session date to yesterday
        lastWorkSessionDate = Calendar.current.date(byAdding: .day, value: -1, to: today)
    }
    
    // MARK: - Date Formatting Helpers (FIXED)
    private func formatDateForPastEarnings(_ date: Date) -> String {
        // NEVER store "Yesterday" - always store the actual date
        // The UI will determine if it should display "Yesterday" dynamically
        
        let calendar = Calendar.current
        let now = Date()
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        
        // Check if it's the current year
        let currentYear = calendar.component(.year, from: now)
        let dateYear = calendar.component(.year, from: date)
        
        if dateYear == currentYear {
            // Same year - just show day and month
            formatter.dateFormat = "d MMM"
        } else {
            // Different year - include the year
            formatter.dateFormat = "d MMM yyyy"
        }
        
        let formattedDate = formatter.string(from: date)
        print("📅 Formatted date \(date) as '\(formattedDate)'")
        return formattedDate
    }

    // MARK: - Dynamic Display Formatting (NEW)
    // Use this function when DISPLAYING past earnings in the UI
    func formatDateForDisplay(_ dateString: String) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        // Parse the stored date string back to a Date
        let storedDate = parseDateFromPastEarnings(dateString)
        
        // Check if it's actually yesterday relative to NOW
        if calendar.isDate(storedDate, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: now) ?? now) {
            return "Yesterday"
        }
        
        // Check if it's today
        if calendar.isDate(storedDate, inSameDayAs: now) {
            return "Today"
        }
        
        // Otherwise return the original stored date string
        return dateString
    }

    
    private func parseDateFromPastEarnings(_ dateString: String) -> Date {
        if dateString == "Yesterday" {
            return Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        
        // Add current year if not present
        var fullDateString = dateString
        if !dateString.contains("2024") && !dateString.contains("2025") {
            fullDateString = "\(dateString) \(Calendar.current.component(.year, from: Date()))"
            formatter.dateFormat = "d MMM yyyy"
        }
        
        return formatter.date(from: fullDateString) ?? Date()
    }
    
    private func isWorkday(_ date: Date) -> Bool {
        let weekday = Calendar.current.component(.weekday, from: date)
        return weekday >= 2 && weekday <= 6 // Monday to Friday
    }
    
    private func calculateFullDayEarnings(for job: Job) -> Double {
        let dailyHours = calculateFullDayHours(for: job)
        return dailyHours * job.hourlyRate
    }
    
    private func calculateFullDayHours(for job: Job) -> Double {
        let workStartMinutes = timeToMinutes(job.workStartTime)
        let workEndMinutes = timeToMinutes(job.workEndTime)
        let lunchStartMinutes = timeToMinutes(job.lunchStartTime)
        let lunchEndMinutes = timeToMinutes(job.lunchEndTime)
        
        let totalWorkMinutes = (workEndMinutes - workStartMinutes) - (lunchEndMinutes - lunchStartMinutes)
        return Double(totalWorkMinutes) / 60.0
    }
    
    // MARK: - End Work Day Function
    func endWorkDay() {
        guard let activeJob = activeJob, todaysEarnings > 0 else { return }
        
        let today = Date()
        let workSession = WorkSession(
            date: today,
            hoursWorked: hoursWorked,
            earnings: todaysEarnings,
            jobId: activeJob.id
        )
        
        // Add today's work session
        workSessions.append(workSession)
        
        // Move today's earnings to work session earnings
        workSessionEarnings += todaysEarnings
        
        // Add to past earnings for UI display using the same formatting as missed sessions
        let dateString = formatDateForPastEarnings(today)
        pastEarnings.insert(DailyEarning(date: dateString, amount: todaysEarnings), at: 0)
        
        // Reset today's values
        todaysEarnings = 0.0
        hoursWorked = 0.0
        
        // Update last work session date
        lastWorkSessionDate = today
        
        print("🎯 Work day ended. Added $\(workSession.earnings) to lifetime earnings")
        print("💎 New lifetime earnings: $\(lifetimeEarnings)")
    }
    
    // MARK: - Persistence Methods
    private func saveWorkSessions() {
        do {
            let encoded = try JSONEncoder().encode(workSessions)
            UserDefaults.standard.set(encoded, forKey: "WorkSessions")
        } catch {
            print("❌ Failed to save work sessions: \(error)")
        }
    }
    
    private func loadWorkSessions() {
        guard let data = UserDefaults.standard.data(forKey: "WorkSessions"),
              let decoded = try? JSONDecoder().decode([WorkSession].self, from: data) else {
            print("📝 No saved work sessions found")
            return
        }
        workSessions = decoded
        
        // Recalculate work session earnings from loaded sessions to ensure consistency
        let calculatedEarnings = workSessions.reduce(0) { total, session in
            total + session.earnings
        }
        print("✅ Loaded \(workSessions.count) work sessions")
        print("💰 Calculated earnings from sessions: $\(String(format: "%.2f", calculatedEarnings))")
        print("💰 Stored work session earnings: $\(String(format: "%.2f", workSessionEarnings))")
        
        // Optional: Sync if there's a discrepancy
        if abs(calculatedEarnings - workSessionEarnings) > 0.01 {
            print("⚠️ Earnings mismatch detected. Syncing to calculated value.")
            workSessionEarnings = calculatedEarnings
        }
    }
    
    private func saveLastWorkSessionDate() {
        if let date = lastWorkSessionDate {
            UserDefaults.standard.set(date, forKey: "LastWorkSessionDate")
        } else {
            UserDefaults.standard.removeObject(forKey: "LastWorkSessionDate")
        }
    }
    
    private func loadLastWorkSessionDate() {
        lastWorkSessionDate = UserDefaults.standard.object(forKey: "LastWorkSessionDate") as? Date
    }
    
    private func saveUserData() {
        UserDefaults.standard.set(userName, forKey: "UserName")
        UserDefaults.standard.set(workSessionEarnings, forKey: "WorkSessionEarnings")
    }
    
    private func loadUserData() {
        userName = UserDefaults.standard.string(forKey: "UserName") ?? "John Doe"
        workSessionEarnings = UserDefaults.standard.double(forKey: "WorkSessionEarnings")
        print("📂 Loaded user data - Work session earnings: $\(workSessionEarnings)")
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
        self.hoursWorked = hoursWorked
        
        // Update hours worked today in the job
        if let index = jobs.firstIndex(where: { $0.id == job.id }) {
            jobs[index].hoursWorkedToday = hoursWorked
        }
        
        print("📊 Today's earnings calculated: $\(String(format: "%.2f", todaysEarnings)) (Hours: \(String(format: "%.2f", hoursWorked)))")
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
        // If this is the first job, set lastWorkSessionDate to today
            if lastWorkSessionDate == nil {
                lastWorkSessionDate = Calendar.current.startOfDay(for: Date())
                print("📅 First job created. Set lastWorkSessionDate to today: \(lastWorkSessionDate!)")
            }

    }
    
    // MARK: - Delete Job Function
    func deleteJob(_ jobToDelete: Job) {
        // Remove from jobs array
        jobs.removeAll { $0.id == jobToDelete.id }
        
        // Handle active job logic
        if activeJob?.id == jobToDelete.id {
            // Set new active job or nil if no jobs left
            activeJob = jobs.first
            
            // Recalculate today's earnings with new active job
            calculateTodaysEarnings()
            
            print("🔄 Active job was deleted. New active job: \(activeJob?.title ?? "None")")
        }
        
        // Remove related work sessions
        let originalSessionCount = workSessions.count
        workSessions = workSessions.filter { $0.jobId != jobToDelete.id }
        let removedSessions = originalSessionCount - workSessions.count
        
        // Recalculate work session earnings after removing sessions
        recalculateWorkSessionEarnings()
        
        print("🗑️ Deleted job: \(jobToDelete.title)")
        print("📊 Removed \(removedSessions) work sessions")
    }
    
    // MARK: - Helper function to recalculate work session earnings
    private func recalculateWorkSessionEarnings() {
        let previousEarnings = workSessionEarnings
        workSessionEarnings = workSessions.reduce(0) { total, session in
            total + session.earnings
        }
        print("💰 Recalculated work session earnings: $\(workSessionEarnings) (was $\(previousEarnings))")
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
    
    // MARK: - Additional persistence methods
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
    
    // MARK: - Clear Data (for testing)
    func clearAllData() {
        UserDefaults.standard.removeObject(forKey: "SavedJobs")
        UserDefaults.standard.removeObject(forKey: "UserName")
        UserDefaults.standard.removeObject(forKey: "WorkSessionEarnings")
        UserDefaults.standard.removeObject(forKey: "ActiveJobID")
        UserDefaults.standard.removeObject(forKey: "PastEarnings")
        UserDefaults.standard.removeObject(forKey: "WorkSessions")
        UserDefaults.standard.removeObject(forKey: "LastWorkSessionDate")
        print("🗑️ All data cleared")
    }
    
    private func printAppStateDebugInfo() {
        print("🔍 === AppState Debug Info ===")
        print("👤 User Name: \(userName)")
        print("💰 Work Session Earnings: $\(String(format: "%.2f", workSessionEarnings))")
        print("📅 Today's Earnings: $\(String(format: "%.2f", todaysEarnings))")
        print("💎 Lifetime Earnings: $\(String(format: "%.2f", lifetimeEarnings))")
        print("⏰ Hours Worked Today: \(String(format: "%.2f", hoursWorked))")
        print("🏢 Total Jobs: \(jobs.count)")
        print("🎯 Active Job: \(activeJob?.title ?? "None")")
        print("📊 Work Sessions: \(workSessions.count)")
        print("📈 Past Earnings: \(pastEarnings.count) entries")
        print("📅 Last Work Session Date: \(lastWorkSessionDate?.description ?? "None")")
        print("👁️ Show All Past Earnings: \(showAllPastEarnings)")
        print("🔍 === End Debug Info ===\n")
    }
}

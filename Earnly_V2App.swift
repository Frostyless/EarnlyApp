import SwiftUI
import Foundation

// MARK: - Add Job View
struct AddJobView: View {
    @EnvironmentObject var appState: AppState
    @State private var jobTitle = ""
    @State private var monthlySalary = ""
    @State private var workStartTime = "08:00"
    @State private var workEndTime = "18:00"
    @State private var lunchStartTime = "12:00"
    @State private var lunchEndTime = "13:00"
    @State private var workingDays = 22
    @State private var customHourlyRate = ""
    @State private var useCustomRate = false
    
    var body: some View {
        ZStack {
            AppBackground()
            
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        appState.currentView = .accounts
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Text("Add Job")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button("Save") {
                        saveJob()
                    }
                    .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.6))
                    .fontWeight(.semibold)
                    .disabled(jobTitle.isEmpty || monthlySalary.isEmpty)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Job Information Section
                        EditSection(title: "Job Information") {
                            VStack(spacing: 16) {
                                EditInputField(
                                    title: "Job Title",
                                    text: $jobTitle
                                )
                                
                                EditInputField(
                                    title: "Monthly Salary ($)",
                                    text: $monthlySalary,
                                    keyboardType: .decimalPad
                                )
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Working Days per Month")
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                    
                                    Picker("Working Days", selection: $workingDays) {
                                        ForEach(15...30, id: \.self) { day in
                                            Text("\(day) days").tag(day)
                                        }
                                    }
                                    .pickerStyle(MenuPickerStyle())
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.white.opacity(0.1))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                            )
                                    )
                                    .foregroundColor(.white)
                                }
                            }
                        }
                        
                        // Work Schedule Section
                        EditSection(title: "Work Schedule") {
                            VStack(spacing: 16) {
                                HStack(spacing: 16) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Start Time")
                                            .font(.body)
                                            .fontWeight(.medium)
                                            .foregroundColor(.white)
                                        
                                        TimeInputField(time: $workStartTime)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("End Time")
                                            .font(.body)
                                            .fontWeight(.medium)
                                            .foregroundColor(.white)
                                        
                                        TimeInputField(time: $workEndTime)
                                    }
                                }
                                
                                HStack(spacing: 16) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Lunch Start")
                                            .font(.body)
                                            .fontWeight(.medium)
                                            .foregroundColor(.white)
                                        
                                        TimeInputField(time: $lunchStartTime)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Lunch End")
                                            .font(.body)
                                            .fontWeight(.medium)
                                            .foregroundColor(.white)
                                        
                                        TimeInputField(time: $lunchEndTime)
                                    }
                                }
                            }
                        }
                        
                        // Hourly Rate Section
                        EditSection(title: "Hourly Rate") {
                            VStack(spacing: 16) {
                                Toggle("Use Custom Hourly Rate", isOn: $useCustomRate)
                                    .foregroundColor(.white)
                                    .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.4, green: 0.8, blue: 0.6)))
                                
                                if useCustomRate {
                                    EditInputField(
                                        title: "Custom Hourly Rate ($)",
                                        text: $customHourlyRate,
                                        keyboardType: .decimalPad
                                    )
                                } else {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Calculated Hourly Rate")
                                            .font(.body)
                                            .fontWeight(.medium)
                                            .foregroundColor(.white)
                                        
                                        Text("$\(calculatedHourlyRate, specifier: "%.2f")")
                                            .font(.title3)
                                            .fontWeight(.semibold)
                                            .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.6))
                                    }
                                }
                            }
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    private var calculatedHourlyRate: Double {
        guard let salary = Double(monthlySalary), salary > 0 else { return 0.0 }
        
        let workStart = timeToMinutes(workStartTime)
        let workEnd = timeToMinutes(workEndTime)
        let lunchStart = timeToMinutes(lunchStartTime)
        let lunchEnd = timeToMinutes(lunchEndTime)
        
        let totalWorkMinutes = workEnd - workStart
        let lunchMinutes = lunchEnd - lunchStart
        let actualWorkMinutes = totalWorkMinutes - lunchMinutes
        let dailyHours = Double(actualWorkMinutes) / 60.0
        
        return salary / (dailyHours * Double(workingDays))
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
    
    private func saveJob() {
        guard let salary = Double(monthlySalary) else { return }
        
        let job = Job(
            title: jobTitle,
            monthlySalary: salary,
            workStartTime: workStartTime,
            workEndTime: workEndTime,
            lunchStartTime: lunchStartTime,
            lunchEndTime: lunchEndTime,
            hoursWorkedToday: 0.0,
            lifetimeHours: 0.0,
            workingDays: workingDays,
            customHourlyRate: useCustomRate ? Double(customHourlyRate) : nil
        )
        
        appState.addJob(job)
        appState.currentView = .accounts
    }
}

// MARK: - Time Input Field Component
struct TimeInputField: View {
    @Binding var time: String
    @State private var showingTimePicker = false
    @State private var selectedTime = Date()
    
    var body: some View {
        Button(action: {
            showingTimePicker = true
            selectedTime = timeStringToDate(time)
        }) {
            Text(time)
                .font(.body)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                )
        }
        .sheet(isPresented: $showingTimePicker) {
            TimePickerView(selectedTime: $selectedTime, time: $time)
        }
    }
    
    private func timeStringToDate(_ timeString: String) -> Date {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateFormat = "HH:mm"
        return formatter.date(from: timeString) ?? Date()
    }
}

// MARK: - Time Picker View
struct TimePickerView: View {
    @Binding var selectedTime: Date
    @Binding var time: String
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker("Select Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(WheelDatePickerStyle())
                    .labelsHidden()
                
                Spacer()
            }
            .navigationTitle("Select Time")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Done") {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "HH:mm"
                    time = formatter.string(from: selectedTime)
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

// MARK: - Job Edit View
struct JobEditView: View {
    @EnvironmentObject var appState: AppState
    @State private var tempJob: Job
    
    init() {
        _tempJob = State(initialValue: Job(title: "", monthlySalary: 0, workStartTime: "08:00", workEndTime: "18:00", lunchStartTime: "12:00", lunchEndTime: "13:00", hoursWorkedToday: 0, lifetimeHours: 0, workingDays: 22, customHourlyRate: nil))
    }
    
    var body: some View {
        ZStack {
            AppBackground()
            
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        appState.currentView = .accounts
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Text("Edit Job")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button("Save") {
                        appState.updateJob(tempJob)
                        appState.currentView = .accounts
                    }
                    .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.6))
                    .fontWeight(.semibold)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Job Information Section
                        EditSection(title: "Job Information") {
                            VStack(spacing: 16) {
                                EditInputField(
                                    title: "Job Title",
                                    text: $tempJob.title
                                )
                                
                                EditNumberField(
                                    title: "Monthly Salary",
                                    value: $tempJob.monthlySalary,
                                    formatter: NumberFormatter.currency
                                )
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Working Days per Month")
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                    
                                    Picker("Working Days", selection: $tempJob.workingDays) {
                                        ForEach(15...30, id: \.self) { day in
                                            Text("\(day) days").tag(day)
                                        }
                                    }
                                    .pickerStyle(MenuPickerStyle())
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.white.opacity(0.1))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                            )
                                    )
                                    .foregroundColor(.white)
                                }
                            }
                        }
                        
                        // Work Schedule Section
                        EditSection(title: "Work Schedule") {
                            VStack(spacing: 16) {
                                HStack(spacing: 16) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Start Time")
                                            .font(.body)
                                            .fontWeight(.medium)
                                            .foregroundColor(.white)
                                        
                                        TimeInputField(time: $tempJob.workStartTime)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("End Time")
                                            .font(.body)
                                            .fontWeight(.medium)
                                            .foregroundColor(.white)
                                        
                                        TimeInputField(time: $tempJob.workEndTime)
                                    }
                                }
                                
                                HStack(spacing: 16) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Lunch Start")
                                            .font(.body)
                                            .fontWeight(.medium)
                                            .foregroundColor(.white)
                                        
                                        TimeInputField(time: $tempJob.lunchStartTime)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Lunch End")
                                            .font(.body)
                                            .fontWeight(.medium)
                                            .foregroundColor(.white)
                                        
                                        TimeInputField(time: $tempJob.lunchEndTime)
                                    }
                                }
                            }
                        }
                        
                        // Hourly Rate Section
                        EditSection(title: "Hourly Rate") {
                            VStack(spacing: 16) {
                                Toggle("Use Custom Hourly Rate", isOn: Binding(
                                    get: { tempJob.customHourlyRate != nil },
                                    set: { useCustom in
                                        if useCustom {
                                            tempJob.customHourlyRate = tempJob.hourlyRate
                                        } else {
                                            tempJob.customHourlyRate = nil
                                        }
                                    }
                                ))
                                .foregroundColor(.white)
                                .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.4, green: 0.8, blue: 0.6)))
                                
                                if tempJob.customHourlyRate != nil {
                                    EditNumberField(
                                        title: "Custom Hourly Rate",
                                        value: Binding(
                                            get: { tempJob.customHourlyRate ?? 0.0 },
                                            set: { tempJob.customHourlyRate = $0 }
                                        ),
                                        formatter: NumberFormatter.currency
                                    )
                                } else {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Calculated Hourly Rate")
                                            .font(.body)
                                            .fontWeight(.medium)
                                            .foregroundColor(.white)
                                        
                                        Text("$\(tempJob.hourlyRate, specifier: "%.2f")")
                                            .font(.title3)
                                            .fontWeight(.semibold)
                                            .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.6))
                                    }
                                }
                            }
                        }
                        
                        // Statistics Section
                        EditSection(title: "Statistics") {
                            VStack(spacing: 16) {
                                StatisticRow(
                                    title: "Daily Working Hours",
                                    value: String(format: "%.1f hrs", tempJob.calculateDailyWorkingHours())
                                )
                                
                                StatisticRow(
                                    title: "Earnings per Minute",
                                    value: String(format: "$%.4f", tempJob.earningsPerMinute)
                                )
                                
                                StatisticRow(
                                    title: "Hours Worked Today",
                                    value: String(format: "%.1f hrs", tempJob.hoursWorkedToday)
                                )
                                
                                StatisticRow(
                                    title: "Total Lifetime Hours",
                                    value: String(format: "%.1f hrs", tempJob.lifetimeHours)
                                )
                            }
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            if let selectedJob = appState.selectedJob {
                tempJob = selectedJob
            }
        }
    }
}

// MARK: - Edit Section Component
struct EditSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            VStack(spacing: 16) {
                content
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

// MARK: - Edit Input Field Component
struct EditInputField: View {
    let title: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.white)
            
            TextField("Enter \(title.lowercased())", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                )
                .foregroundColor(.white)
                .keyboardType(keyboardType)
        }
    }
}

// MARK: - Edit Number Field Component
struct EditNumberField: View {
    let title: String
    @Binding var value: Double
    let formatter: NumberFormatter
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.white)
            
            TextField("Enter amount", value: $value, formatter: formatter)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                )
                .foregroundColor(.white)
                .keyboardType(.decimalPad)
        }
    }
}

// MARK: - Statistic Row Component
struct StatisticRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.body)
                .foregroundColor(.white.opacity(0.7))
            
            Spacer()
            
            Text(value)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.6))
        }
    }
}

// MARK: - Number Formatter Extensions
extension NumberFormatter {
    static let currency: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter
    }()
    
    static let decimal: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        return formatter
    }()
}

// MARK: - Main App
@main
struct EarnlyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

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
    
    private var timer: Timer?
    private var lastUpdateDate: Date?
    
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
        
        startEarningsTimer()
    }
    
    func startEarningsTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
            self.updateEarnings()
        }
    }
    
    func stopEarningsTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateEarnings() {
        guard let job = activeJob else { return }
        
        let now = Date()
        let calendar = Calendar.current
        
        // Check if it's a new day
        if let lastDate = lastUpdateDate,
           !calendar.isDate(now, inSameDayAs: lastDate) {
            // New day started, reset today's earnings
            todaysEarnings = 0.0
            if let index = jobs.firstIndex(where: { $0.id == job.id }) {
                jobs[index].hoursWorkedToday = 0.0
            }
        }
        
        lastUpdateDate = now
        
        // Check if current time is within working hours and not lunch
        if job.isCurrentlyWorkingTime() {
            let earningsPerMinute = job.earningsPerMinute
            todaysEarnings += earningsPerMinute
            lifetimeEarnings += earningsPerMinute
            
            // Update hours worked (1 minute = 1/60 hour)
            if let index = jobs.firstIndex(where: { $0.id == job.id }) {
                jobs[index].hoursWorkedToday += 1.0/60.0
                jobs[index].lifetimeHours += 1.0/60.0
            }
        }
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
            }
        }
    }
    
    deinit {
        stopEarningsTimer()
    }
}

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

// MARK: - Background Gradient
struct AppBackground: View {
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.black,
                Color(red: 0.1, green: 0.1, blue: 0.3),
                Color(red: 0.2, green: 0.1, blue: 0.4)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

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

// MARK: - Dashboard Screen
struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    @State private var animateElements = false
    @State private var currentTime = Date()
    
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
                        }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .offset(y: animateElements ? 0 : 100)
                .opacity(animateElements ? 1 : 0)
                
                ScrollView {
                    VStack(spacing: 24) {
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
                            isToday: true
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
                HStack {
                    Rectangle()
                        .fill(Color(red: 0.4, green: 0.8, blue: 0.6))
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    Rectangle()
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 4)
                        .cornerRadius(2)
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
                        Text(earning.date)
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

// MARK: - Accounts View
struct AccountsView: View {
    @EnvironmentObject var appState: AppState
    @State private var slideInOffset: CGFloat = -UIScreen.main.bounds.width
    
    var body: some View {
        ZStack {
            AppBackground()
            
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
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
                                    appState.currentView = .addJob
                                }) {
                                    Image(systemName: "plus")
                                        .font(.title3)
                                        .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.6))
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            VStack(spacing: 12) {
                                ForEach(appState.jobs) { job in
                                    JobCard(job: job, isActive: appState.activeJob?.id == job.id)
                                        .onTapGesture {
                                            appState.selectedJob = job
                                            appState.currentView = .jobEdit
                                        }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        Spacer(minLength: 100)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .offset(x: slideInOffset)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                slideInOffset = 0
            }
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

// MARK

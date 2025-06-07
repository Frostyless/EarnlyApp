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
            workingDays: 22,
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

struct TimePickerView: View {
    @Binding var selectedTime: Date
    @Binding var time: String
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Select Time")
                .font(.headline)
                .padding(.top)
            
            DatePicker("Select Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                .datePickerStyle(WheelDatePickerStyle())
                .labelsHidden()
            
            HStack {
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(.red)
                
                Spacer()
                
                Button("Done") {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "HH:mm"
                    time = formatter.string(from: selectedTime)
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(.blue)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .frame(height: 300) // Fixed height
        .background(Color(.systemBackground))
        .cornerRadius(12)
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
                                    formatter: NumberFormatter.salary
                                )
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
                                        formatter: NumberFormatter.salary
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
    static let salary: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        formatter.groupingSeparator = ","
        formatter.usesGroupingSeparator = true
        return formatter
    }()
    
    static let decimal: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        return formatter
    }()
}

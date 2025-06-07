import SwiftUI

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
    @Published var todaysEarnings: Double = 124.50
    @Published var hoursWorked: Double = 0.0
    @Published var showAllPastEarnings: Bool = false
    @Published var jobs: [Job] = [
        Job(title: "Software Developer", monthlySalary: 5000.0, hoursPerDay: 8.0, hoursWorkedToday: 6.5, lifetimeHours: 1847.5),
        Job(title: "Freelance Designer", monthlySalary: 3200.0, hoursPerDay: 6.0, hoursWorkedToday: 4.0, lifetimeHours: 892.0)
    ]
    @Published var selectedJob: Job?
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
        case loading, dashboard, accounts, jobEdit
    }
}

// MARK: - Job Model
struct Job: Identifiable {
    let id = UUID()
    var title: String
    var monthlySalary: Double
    var hoursPerDay: Double
    var hoursWorkedToday: Double
    var lifetimeHours: Double
    
    var hourlyRate: Double {
        return monthlySalary / (hoursPerDay * 22) // Assuming 22 working days per month
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
    @State private var showingAccounts = false
    
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
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .offset(y: animateElements ? 0 : 100)
                .opacity(animateElements ? 1 : 0)
                
                ScrollView {
                    VStack(spacing: 24) {
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
                            Text("Your Jobs")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                            
                            VStack(spacing: 12) {
                                ForEach(appState.jobs) { job in
                                    JobCard(job: job)
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
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text(job.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
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

// MARK: - Job Edit View
struct JobEditView: View {
    @EnvironmentObject var appState: AppState
    @State private var tempJob: Job
    
    init() {
        _tempJob = State(initialValue: Job(title: "", monthlySalary: 0, hoursPerDay: 0, hoursWorkedToday: 0, lifetimeHours: 0))
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
                        if let index = appState.jobs.firstIndex(where: { $0.id == tempJob.id }) {
                            appState.jobs[index] = tempJob
                        }
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
                                
                                EditNumberField(
                                    title: "Working Hours per Day",
                                    value: $tempJob.hoursPerDay,
                                    formatter: NumberFormatter.decimal
                                )
                            }
                        }
                        
                        // Statistics Section
                        EditSection(title: "Statistics") {
                            VStack(spacing: 16) {
                                StatisticRow(
                                    title: "Hourly Rate",
                                    value: "$\(String(format: "%.2f", tempJob.hourlyRate))"
                                )
                                
                                StatisticRow(
                                    title: "Hours Worked Today",
                                    value: "\(String(format: "%.1f", tempJob.hoursWorkedToday)) hrs"
                                )
                                
                                StatisticRow(
                                    title: "Total Lifetime Hours",
                                    value: "\(String(format: "%.1f", tempJob.lifetimeHours)) hrs"
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

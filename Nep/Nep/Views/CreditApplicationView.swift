import SwiftUI

struct CreditApplicationView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var creditService = CreditService.shared
    
    @State private var personalInfo = CreditApplication.PersonalInfo(
        firstName: "",
        lastName: "",
        dateOfBirth: "",
        ssn: "",
        address: CreditApplication.Address(
            street: "",
            city: "",
            state: "",
            zipCode: "",
            country: "US"
        ),
        phone: "",
        email: ""
    )
    
    @State private var financialInfo = CreditApplication.FinancialInfo(
        monthlyIncome: 0,
        monthlyExpenses: 0,
        currentDebt: 0,
        creditUtilization: 0,
        savings: 0,
        investments: 0
    )
    
    @State private var employmentInfo = CreditApplication.EmploymentInfo(
        employer: "",
        jobTitle: "",
        employmentLength: 0,
        employmentType: "full-time",
        incomeStability: "stable"
    )
    
    @State private var currentStep = 0
    @State private var isSubmitting = false
    @State private var showingSuccess = false
    
    private let steps = ["Personal", "Financial", "Employment", "Review"]
    
    var body: some View {
        NavigationView {
            VStack {
                // Progress indicator
                progressIndicator
                
                // Form content
                TabView(selection: $currentStep) {
                    personalInfoStep
                        .tag(0)
                    
                    financialInfoStep
                        .tag(1)
                    
                    employmentInfoStep
                        .tag(2)
                    
                    reviewStep
                        .tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                // Navigation buttons
                navigationButtons
            }
            .navigationTitle("Credit Application")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Application Submitted", isPresented: $showingSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your credit application has been submitted successfully. You will receive a response within 2-3 business days.")
            }
        }
    }
    
    // MARK: - Progress Indicator
    private var progressIndicator: some View {
        HStack {
            ForEach(0..<steps.count, id: \.self) { index in
                HStack {
                    Circle()
                        .fill(index <= currentStep ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 20, height: 20)
                        .overlay(
                            Text("\(index + 1)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(index <= currentStep ? .white : .gray)
                        )
                    
                    if index < steps.count - 1 {
                        Rectangle()
                            .fill(index < currentStep ? Color.blue : Color.gray.opacity(0.3))
                            .frame(height: 2)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 20)
    }
    
    // MARK: - Personal Info Step
    private var personalInfoStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Personal Information")
                    .font(.title2)
                    .fontWeight(.bold)
                
                VStack(spacing: 16) {
                    HStack {
                        TextField("First Name", text: $personalInfo.firstName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        TextField("Last Name", text: $personalInfo.lastName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    TextField("Date of Birth (MM/DD/YYYY)", text: $personalInfo.dateOfBirth)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("SSN (XXX-XX-XXXX)", text: $personalInfo.ssn)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Phone Number", text: $personalInfo.phone)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.phonePad)
                    
                    TextField("Email Address", text: $personalInfo.email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
                
                Text("Address")
                    .font(.headline)
                    .padding(.top)
                
                VStack(spacing: 16) {
                    TextField("Street Address", text: $personalInfo.address.street)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    HStack {
                        TextField("City", text: $personalInfo.address.city)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        TextField("State", text: $personalInfo.address.state)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(maxWidth: 100)
                    }
                    
                    HStack {
                        TextField("ZIP Code", text: $personalInfo.address.zipCode)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(maxWidth: 120)
                        
                        Spacer()
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Financial Info Step
    private var financialInfoStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Financial Information")
                    .font(.title2)
                    .fontWeight(.bold)
                
                VStack(spacing: 16) {
                    TextField("Monthly Income", value: $financialInfo.monthlyIncome, format: .currency(code: "USD"))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad)
                    
                    TextField("Monthly Expenses", value: $financialInfo.monthlyExpenses, format: .currency(code: "USD"))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad)
                    
                    TextField("Current Debt", value: $financialInfo.currentDebt, format: .currency(code: "USD"))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad)
                    
                    TextField("Credit Utilization (%)", value: $financialInfo.creditUtilization, format: .percent)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad)
                    
                    TextField("Savings", value: $financialInfo.savings, format: .currency(code: "USD"))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad)
                    
                    TextField("Investments", value: $financialInfo.investments, format: .currency(code: "USD"))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad)
                }
            }
            .padding()
        }
    }
    
    // MARK: - Employment Info Step
    private var employmentInfoStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Employment Information")
                    .font(.title2)
                    .fontWeight(.bold)
                
                VStack(spacing: 16) {
                    TextField("Employer", text: $employmentInfo.employer)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Job Title", text: $employmentInfo.jobTitle)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Employment Length (months)", value: $employmentInfo.employmentLength, format: .number)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                    
                    Picker("Employment Type", selection: $employmentInfo.employmentType) {
                        Text("Full-time").tag("full-time")
                        Text("Part-time").tag("part-time")
                        Text("Self-employed").tag("self-employed")
                        Text("Contract").tag("contract")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    Picker("Income Stability", selection: $employmentInfo.incomeStability) {
                        Text("Stable").tag("stable")
                        Text("Variable").tag("variable")
                        Text("Seasonal").tag("seasonal")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
            .padding()
        }
    }
    
    // MARK: - Review Step
    private var reviewStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Review Application")
                    .font(.title2)
                    .fontWeight(.bold)
                
                VStack(alignment: .leading, spacing: 16) {
                    reviewSection("Personal Information") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Name: \(personalInfo.firstName) \(personalInfo.lastName)")
                            Text("DOB: \(personalInfo.dateOfBirth)")
                            Text("Phone: \(personalInfo.phone)")
                            Text("Email: \(personalInfo.email)")
                            Text("Address: \(personalInfo.address.street), \(personalInfo.address.city), \(personalInfo.address.state) \(personalInfo.address.zipCode)")
                        }
                    }
                    
                    reviewSection("Financial Information") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Monthly Income: $\(Int(financialInfo.monthlyIncome))")
                            Text("Monthly Expenses: $\(Int(financialInfo.monthlyExpenses))")
                            Text("Current Debt: $\(Int(financialInfo.currentDebt))")
                            Text("Credit Utilization: \(Int(financialInfo.creditUtilization * 100))%")
                            Text("Savings: $\(Int(financialInfo.savings))")
                            Text("Investments: $\(Int(financialInfo.investments))")
                        }
                    }
                    
                    reviewSection("Employment Information") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Employer: \(employmentInfo.employer)")
                            Text("Job Title: \(employmentInfo.jobTitle)")
                            Text("Employment Length: \(employmentInfo.employmentLength) months")
                            Text("Employment Type: \(employmentInfo.employmentType.capitalized)")
                            Text("Income Stability: \(employmentInfo.incomeStability.capitalized)")
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    private func reviewSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            content()
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Navigation Buttons
    private var navigationButtons: some View {
        HStack {
            if currentStep > 0 {
                Button("Previous") {
                    withAnimation {
                        currentStep -= 1
                    }
                }
                .buttonStyle(.bordered)
            }
            
            Spacer()
            
            if currentStep < steps.count - 1 {
                Button("Next") {
                    withAnimation {
                        currentStep += 1
                    }
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button("Submit Application") {
                    submitApplication()
                }
                .buttonStyle(.borderedProminent)
                .disabled(isSubmitting)
            }
        }
        .padding()
    }
    
    // MARK: - Helper Methods
    private func submitApplication() {
        isSubmitting = true
        
        let application = CreditApplication(
            personalInfo: personalInfo,
            financialInfo: financialInfo,
            employmentInfo: employmentInfo
        )
        
        Task {
            do {
                let applicationId = try await creditService.submitCreditApplication(application)
                DispatchQueue.main.async {
                    isSubmitting = false
                    showingSuccess = true
                }
            } catch {
                DispatchQueue.main.async {
                    isSubmitting = false
                    // Handle error
                }
            }
        }
    }
}

#Preview {
    CreditApplicationView()
}

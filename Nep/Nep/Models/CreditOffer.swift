import Foundation

// MARK: - Credit Offer Models
struct CreditOffer: Codable, Identifiable {
    let id = UUID()
    let customerId: String
    let pd90Score: Double  // Probability of default in 90 days
    let riskTier: String   // Prime, Near Prime, Subprime, High Risk
    let creditLimit: Double
    let apr: Double        // Annual Percentage Rate
    let msiEligible: Bool  // Meses sin intereses
    let msiMonths: Int
    let explanation: String
    let confidence: Double
    let generatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case customerId = "customer_id"
        case pd90Score = "pd90_score"
        case riskTier = "risk_tier"
        case creditLimit = "credit_limit"
        case apr
        case msiEligible = "msi_eligible"
        case msiMonths = "msi_months"
        case explanation
        case confidence
        case generatedAt = "generated_at"
    }
    
    // Computed properties for UI
    var riskTierColor: String {
        switch riskTier.lowercased() {
        case "prime":
            return "green"
        case "near prime":
            return "blue"
        case "subprime":
            return "orange"
        case "high risk":
            return "red"
        default:
            return "gray"
        }
    }
    
    var riskTierIcon: String {
        switch riskTier.lowercased() {
        case "prime":
            return "star.fill"
        case "near prime":
            return "star"
        case "subprime":
            return "exclamationmark.triangle"
        case "high risk":
            return "xmark.circle"
        default:
            return "questionmark.circle"
        }
    }
    
    var formattedCreditLimit: String {
        return String(format: "$%.0f", creditLimit)
    }
    
    var formattedAPR: String {
        return String(format: "%.1f%%", apr * 100)
    }
    
    var formattedPD90: String {
        return String(format: "%.1f%%", pd90Score * 100)
    }
    
    var formattedConfidence: String {
        return String(format: "%.0f%%", confidence * 100)
    }
}

// MARK: - Credit Score Request
struct CreditScoreRequest: Codable {
    let age: Int
    let incomeMonthly: Double
    
    // Financial behavior
    let payrollStreak: Int
    let payrollVariance: Double
    let spendingMonthly: Double
    let spendingVar6m: Double
    let currentDebt: Double
    let dti: Double  // debt-to-income ratio
    let utilization: Double  // credit utilization
    
    // Optional advanced features
    let zone: String?
    let savingsRate: Double?
    let financialHealthScore: Double?
    
    enum CodingKeys: String, CodingKey {
        case age
        case incomeMonthly = "income_monthly"
        case payrollStreak = "payroll_streak"
        case payrollVariance = "payroll_variance"
        case spendingMonthly = "spending_monthly"
        case spendingVar6m = "spending_var_6m"
        case currentDebt = "current_debt"
        case dti
        case utilization
        case zone
        case savingsRate = "savings_rate"
        case financialHealthScore = "financial_health_score"
    }
}

// MARK: - Credit Score Response
struct CreditScoreResponse: Codable {
    let success: Bool
    let offer: CreditOffer?
    let errorMessage: String?
    let modelVersion: String
    
    enum CodingKeys: String, CodingKey {
        case success
        case offer
        case errorMessage = "error_message"
        case modelVersion = "model_version"
    }
}

// MARK: - Credit Application Form
struct CreditApplication: Codable {
    let personalInfo: PersonalInfo
    let financialInfo: FinancialInfo
    let employmentInfo: EmploymentInfo
    
    struct PersonalInfo: Codable {
        var firstName: String
        var lastName: String
        var dateOfBirth: String
        var ssn: String
        var address: Address
        var phone: String
        var email: String
    }
    
    struct FinancialInfo: Codable {
        var monthlyIncome: Double
        var monthlyExpenses: Double
        var currentDebt: Double
        var creditUtilization: Double
        var savings: Double
        var investments: Double
    }
    
    struct EmploymentInfo: Codable {
        var employer: String
        var jobTitle: String
        var employmentLength: Int  // months
        var employmentType: String  // full-time, part-time, self-employed
        var incomeStability: String  // stable, variable, seasonal
    }
    
    struct Address: Codable {
        var street: String
        var city: String
        var state: String
        var zipCode: String
        var country: String
    }
}

// MARK: - Credit Application Status
enum CreditApplicationStatus: String, CaseIterable, Codable {
    case pending = "pending"
    case approved = "approved"
    case rejected = "rejected"
    case underReview = "under_review"
    case requiresDocuments = "requires_documents"
    
    var displayName: String {
        switch self {
        case .pending:
            return "Pending Review"
        case .approved:
            return "Approved"
        case .rejected:
            return "Rejected"
        case .underReview:
            return "Under Review"
        case .requiresDocuments:
            return "Documents Required"
        }
    }
    
    var color: String {
        switch self {
        case .pending:
            return "orange"
        case .approved:
            return "green"
        case .rejected:
            return "red"
        case .underReview:
            return "blue"
        case .requiresDocuments:
            return "yellow"
        }
    }
}

// MARK: - Credit History
struct CreditHistory: Codable, Identifiable {
    let id = UUID()
    let applicationId: String
    let appliedDate: String
    let status: CreditApplicationStatus
    let creditLimit: Double?
    let apr: Double?
    let riskTier: String?
    let notes: String?
    
    enum CodingKeys: String, CodingKey {
        case applicationId = "application_id"
        case appliedDate = "applied_date"
        case status
        case creditLimit = "credit_limit"
        case apr
        case riskTier = "risk_tier"
        case notes
    }
}

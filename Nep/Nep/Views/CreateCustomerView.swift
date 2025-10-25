import SwiftUI

struct CreateCustomerView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var bridge = QuantumNessieBridge.shared
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var streetNumber = ""
    @State private var streetName = ""
    @State private var city = ""
    @State private var state = ""
    @State private var zip = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    
    var body: some View {
        NavigationView {
            Form {
                Section("Personal Information") {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                }
                
                Section("Address") {
                    TextField("Street Number", text: $streetNumber)
                    TextField("Street Name", text: $streetName)
                    TextField("City", text: $city)
                    TextField("State", text: $state)
                    TextField("ZIP Code", text: $zip)
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                if let success = successMessage {
                    Section {
                        Text(success)
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Create Customer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        Task {
                            await createCustomer()
                        }
                    }
                    .disabled(isLoading || !isFormValid)
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !firstName.isEmpty &&
        !lastName.isEmpty &&
        !streetNumber.isEmpty &&
        !streetName.isEmpty &&
        !city.isEmpty &&
        !state.isEmpty &&
        !zip.isEmpty
    }
    
    private func createCustomer() async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        let address = NessieAddress(
            streetNumber: streetNumber,
            streetName: streetName,
            city: city,
            state: state,
            zip: zip
        )
        
        do {
            let customer = try await bridge.createNessieCustomer(
                firstName: firstName,
                lastName: lastName,
                address: address
            )
            
            successMessage = "Customer created successfully! ID: \(customer.id)"
            
            // Auto-dismiss after success
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                dismiss()
            }
            
        } catch {
            errorMessage = "Failed to create customer: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

#Preview {
    CreateCustomerView()
}

# Supabase Setup Guide

This guide will help you set up Supabase integration for the Nep banking app.

## Prerequisites

1. A Supabase account and project
2. Xcode with Swift Package Manager support

## Setup Steps

### 1. Add Supabase Dependency

1. Open your project in Xcode
2. Go to File → Add Package Dependencies
3. Enter the Supabase Swift package URL: `https://github.com/supabase/supabase-swift`
4. Click "Add Package"
5. Select "Supabase" and click "Add Package"

### 2. Configure Supabase Credentials

1. Open `Nep/Nep/Utils/AppConfig.swift`
2. Update the Supabase configuration with your actual credentials:
   ```swift
   struct Supabase {
       static let url = "https://your-actual-project-id.supabase.co"
       static let anonKey = "your-actual-anon-key-here"
   }
   ```

3. **Important**: Make sure to never commit your actual API keys to version control!

### 3. Create Supabase Tables

Run the following SQL in your Supabase SQL editor:

```sql
-- Users table
CREATE TABLE users (
    id TEXT PRIMARY KEY,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    phone TEXT,
    address JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Accounts table
CREATE TABLE accounts (
    id TEXT PRIMARY KEY,
    nickname TEXT NOT NULL,
    rewards INTEGER DEFAULT 0,
    balance DECIMAL(15,2) DEFAULT 0.00,
    account_number TEXT,
    type TEXT NOT NULL,
    customer_id TEXT REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Cards table
CREATE TABLE cards (
    id TEXT PRIMARY KEY,
    nickname TEXT NOT NULL,
    type TEXT NOT NULL,
    account_id TEXT REFERENCES accounts(id) ON DELETE CASCADE,
    customer_id TEXT REFERENCES users(id) ON DELETE CASCADE,
    card_number TEXT NOT NULL,
    expiration_date TEXT NOT NULL,
    cvc TEXT NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Transactions table
CREATE TABLE transactions (
    id TEXT PRIMARY KEY,
    type TEXT NOT NULL,
    transaction_date TEXT NOT NULL,
    status TEXT NOT NULL,
    payer JSONB NOT NULL,
    payee JSONB NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    medium TEXT NOT NULL,
    description TEXT,
    account_id TEXT REFERENCES accounts(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Credit offers table
CREATE TABLE credit_offers (
    id TEXT PRIMARY KEY,
    customer_id TEXT REFERENCES users(id) ON DELETE CASCADE,
    pd90_score DECIMAL(5,4) NOT NULL,
    risk_tier TEXT NOT NULL,
    credit_limit DECIMAL(15,2) NOT NULL,
    apr DECIMAL(5,4) NOT NULL,
    msi_eligible BOOLEAN DEFAULT false,
    msi_months INTEGER DEFAULT 0,
    explanation TEXT,
    confidence DECIMAL(3,2) NOT NULL,
    generated_at TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security (RLS)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE cards ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE credit_offers ENABLE ROW LEVEL SECURITY;

-- Create policies (adjust based on your auth requirements)
-- For now, allow all operations (you should implement proper auth later)
CREATE POLICY "Allow all operations" ON users FOR ALL USING (true);
CREATE POLICY "Allow all operations" ON accounts FOR ALL USING (true);
CREATE POLICY "Allow all operations" ON cards FOR ALL USING (true);
CREATE POLICY "Allow all operations" ON transactions FOR ALL USING (true);
CREATE POLICY "Allow all operations" ON credit_offers FOR ALL USING (true);
```

### 4. Test the Connection

1. Build and run the app
2. Navigate to the SupabaseTestView (you can add this to your main navigation)
3. Verify the connection status shows "Connected successfully!"

### 5. Next Steps

Once the connection is working:

1. Replace MockData usage with SupabaseService calls
2. Implement proper authentication
3. Add proper RLS policies
4. Set up real-time subscriptions if needed

## File Structure

```
Nep/
├── Utils/
│   ├── SupabaseConfig.swift      # Supabase client configuration
│   ├── Config.swift              # Legacy configuration (backward compatibility)
│   ├── AppConfig.swift           # Main configuration file
│   └── MockData.swift            # (To be replaced)
├── Services/
│   └── SupabaseService.swift     # Supabase data operations
└── Views/
    └── SupabaseTestView.swift    # Connection test view
```

## Troubleshooting

### Common Issues

1. **"Failed to initialize Supabase client"**
   - Check that your `AppConfig.swift` has the correct Supabase URL and anon key
   - Verify your Supabase URL and anon key are correct

2. **"Connection failed"**
   - Check your internet connection
   - Verify your Supabase project is active
   - Check that the tables exist in your database

3. **Build errors**
   - Make sure you've added the Supabase package dependency
   - Clean and rebuild your project

4. **Configuration warnings**
   - If you see warnings about missing API keys, update `AppConfig.swift` with your actual keys
   - Optional API keys (Gemini, ElevenLabs) will show warnings but won't break the app

### Getting Supabase Credentials

1. Go to your Supabase dashboard
2. Select your project
3. Go to Settings → API
4. Copy the Project URL and anon/public key

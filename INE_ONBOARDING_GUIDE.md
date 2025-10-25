# INE Onboarding with Gemini AI & ElevenLabs Voice Guide

## 🎯 Overview

This enhanced onboarding system specifically extracts data from INE (Instituto Nacional Electoral) documents and provides intelligent voice guidance using Gemini AI with ElevenLabs voice synthesis.

## 🚀 Features

### ✅ INE-Specific Data Extraction
- **CURP Detection**: 18-character alphanumeric code validation
- **Document Number**: 13-digit INE number extraction
- **Personal Data**: Name, date of birth, sex, nationality
- **Location Data**: State, municipality, locality, electoral section
- **Document Dates**: Issue date and expiration date
- **Address Information**: Complete address from back side

### ✅ Gemini AI Integration
- **Intelligent Analysis**: AI-powered INE document validation
- **Confidence Scoring**: Accuracy assessment of extracted data
- **Missing Field Detection**: Identifies incomplete information
- **Smart Suggestions**: Provides recommendations for data correction
- **Conversational Flow**: Natural language processing for user interactions

### ✅ ElevenLabs Voice Guidance
- **Natural Voice**: High-quality Spanish voice synthesis
- **Step-by-Step Guidance**: Voice instructions for each onboarding step
- **Interactive Conversations**: Two-way voice communication
- **Context-Aware Responses**: Gemini AI generates personalized responses
- **Real-time Processing**: Immediate voice feedback

## 🏗️ Architecture

```
iOS App (SwiftUI)
    ↓
Enhanced OCR Service (INE-specific)
    ↓
Gemini AI Analysis
    ↓
ElevenLabs Voice Synthesis
    ↓
Backend API (Python/FastAPI)
    ↓
Database Storage
```

## 📱 iOS Implementation

### Enhanced OCR Service
```swift
// INE-specific data extraction
struct OCRResults {
    // Standard fields
    let firstName: String
    let lastName: String
    let dateOfBirth: String
    let documentNumber: String
    
    // INE-specific fields
    let curp: String
    let sex: String
    let electoralSection: String
    let locality: String
    let municipality: String
    let state: String
    let expirationDate: String
    let issueDate: String
    
    var isINEValid: Bool {
        return !documentNumber.isEmpty && !curp.isEmpty
    }
}
```

### Gemini AI Service
```swift
class GeminiAIService: ObservableObject {
    // Analyze INE document
    func analyzeINEDocument(_ ocrResults: OCRResults) async -> INEAnalysis
    
    // Generate onboarding guidance
    func generateOnboardingGuidance(step: OnboardingStep, ocrResults: OCRResults) async -> String
    
    // Process user responses
    func processUserResponse(_ userInput: String, context: OnboardingContext) async -> ConversationResponse
}
```

### Enhanced ElevenLabs Service
```swift
class ElevenLabsService: ObservableObject {
    // Gemini-powered conversation
    func startOnboardingConversation(ocrResults: OCRResults) async
    
    // Process user voice input
    func processUserResponse(_ response: String) async -> ConversationResponse
    
    // Advance through onboarding steps
    func advanceToNextStep() async
}
```

## 🔧 Backend Implementation

### INE Processing API
```python
# Endpoints
POST /ine/analyze          # Analyze INE document with Gemini AI
POST /ine/onboarding       # Process complete onboarding
GET  /ine/status/{user_id} # Get onboarding status
POST /ine/verify-document/{doc_number} # Verify INE document
```

### Gemini AI Integration
```python
async def analyze_ine_document(ine_data: INEData) -> INEAnalysis:
    # Create analysis prompt
    prompt = create_ine_analysis_prompt(ine_data)
    
    # Send to Gemini AI
    analysis_result = await send_gemini_request(prompt)
    
    # Parse and return analysis
    return parse_ine_analysis(analysis_result, ine_data)
```

## 🎯 Onboarding Flow

### 1. Welcome & Consent
- User grants camera and data processing permissions
- Gemini AI generates personalized welcome message
- ElevenLabs speaks the welcome message

### 2. Document Capture
- Camera captures INE front and back
- Enhanced OCR extracts INE-specific data
- Real-time validation feedback

### 3. Data Verification
- Gemini AI analyzes extracted data
- Confidence scoring and validation
- User can edit any incorrect information
- Voice guidance for corrections

### 4. Voice Verification
- Gemini AI generates verification questions
- ElevenLabs speaks questions naturally
- User responds via voice
- AI processes responses intelligently

### 5. Additional Information
- Collect occupation and income source
- Voice-guided form completion
- Context-aware assistance

### 6. Final Confirmation
- Review all collected data
- Gemini AI provides final summary
- Voice confirmation of completion

## 🔑 Configuration

### API Keys Required
```swift
// Gemini AI
private let geminiApiKey = "YOUR_GEMINI_API_KEY"

// ElevenLabs
private let elevenLabsApiKey = "YOUR_ELEVENLABS_API_KEY"
```

### Backend Configuration
```python
# Gemini AI
GEMINI_API_KEY = "YOUR_GEMINI_API_KEY"
GEMINI_BASE_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent"

# ElevenLabs
ELEVENLABS_API_KEY = "YOUR_ELEVENLABS_API_KEY"
ELEVENLABS_BASE_URL = "https://api.elevenlabs.io/v1"
```

## 🚀 Getting Started

### 1. Install Dependencies
```bash
# Backend
pip install fastapi uvicorn requests

# iOS (already included)
# Vision framework for OCR
# AVFoundation for camera
# Speech framework for voice recognition
```

### 2. Configure API Keys
- Get Gemini AI API key from Google AI Studio
- Get ElevenLabs API key from ElevenLabs platform
- Update configuration files

### 3. Start Backend
```bash
cd Backend/
python main.py
```

### 4. Run iOS App
- Open Xcode project
- Build and run on device/simulator
- Test with real INE document

## 📊 INE Data Validation

### CURP Validation
- 18-character alphanumeric format
- Pattern: `[A-Z]{4}[0-9]{6}[HM][A-Z]{5}[0-9A-Z][0-9]`
- Real-time format checking

### Document Number Validation
- 13-digit numeric format
- Official INE number verification
- Expiration date checking

### Data Consistency
- Cross-field validation
- Date format verification
- Location data validation

## 🎙️ Voice Features

### Natural Conversations
- Context-aware responses
- Personalized guidance
- Multi-step conversation flow
- Error handling and recovery

### Voice Quality
- High-quality Spanish synthesis
- Natural intonation and pacing
- Clear pronunciation
- Background noise handling

## 🔒 Security & Privacy

### Data Encryption
- AES-GCM encryption for sensitive data
- Secure transmission to backend
- Local data protection

### Privacy Compliance
- GDPR and LFPDPPP compliance
- User consent management
- Data retention policies
- Secure deletion options

## 🧪 Testing

### INE Document Testing
- Test with various INE formats
- Validate extraction accuracy
- Test edge cases and errors

### Voice Testing
- Test conversation flows
- Validate voice recognition
- Test error handling

### Integration Testing
- End-to-end onboarding flow
- Backend API integration
- Real-time processing

## 📈 Performance

### OCR Performance
- Real-time document processing
- High accuracy extraction
- Optimized for mobile devices

### Voice Performance
- Low-latency voice synthesis
- Fast response generation
- Efficient audio processing

### AI Performance
- Quick Gemini AI responses
- Optimized prompts
- Cached responses where appropriate

## 🐛 Troubleshooting

### Common Issues
1. **OCR Accuracy**: Ensure good lighting and document positioning
2. **Voice Recognition**: Check microphone permissions and audio quality
3. **API Errors**: Verify API keys and network connectivity
4. **Backend Issues**: Check server logs and database connections

### Debug Mode
- Enable detailed logging
- Test with mock data
- Use development endpoints

## 🔮 Future Enhancements

### Planned Features
- Multi-language support
- Additional document types
- Advanced fraud detection
- Biometric verification
- Real-time document validation

### AI Improvements
- Better conversation flow
- Enhanced error handling
- Personalized user experience
- Advanced analytics

## 📞 Support

For technical support or questions about the INE onboarding system:
- Check the troubleshooting section
- Review API documentation
- Test with development endpoints
- Contact the development team

---

**Note**: This system is designed specifically for Mexican INE documents and requires proper API keys for Gemini AI and ElevenLabs services to function fully.

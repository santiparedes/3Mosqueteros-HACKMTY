# API Setup Guide for NEP Onboarding

This guide will help you set up the Gemini AI and ElevenLabs APIs for the NEP onboarding process.

## Prerequisites

- Xcode 15.0 or later
- iOS 17.0 or later
- Active internet connection

## Step 1: Get Gemini AI API Key

1. **Visit Google AI Studio**
   - Go to: https://makersuite.google.com/app/apikey
   - Sign in with your Google account

2. **Create API Key**
   - Click "Create API Key"
   - Choose "Create API key in new project" or select existing project
   - Copy the generated API key

3. **Configure in App**
   - Open `APIConfig.swift` in Xcode
   - Replace `YOUR_ACTUAL_GEMINI_API_KEY` with your actual key
   - Or use the API Configuration view in the app

## Step 2: Get ElevenLabs API Key

1. **Visit ElevenLabs**
   - Go to: https://elevenlabs.io/app/settings/api-keys
   - Sign up or log in to your account

2. **Create API Key**
   - Click "Create API Key"
   - Give it a name (e.g., "NEP App")
   - Copy the generated API key

3. **Configure in App**
   - Open `APIConfig.swift` in Xcode
   - Replace `YOUR_ACTUAL_ELEVENLABS_API_KEY` with your actual key
   - Or use the API Configuration view in the app

## Step 3: Test the Integration

1. **Build and Run**
   - Build the project in Xcode
   - Run on simulator or device

2. **Test Onboarding Flow**
   - Navigate to the onboarding process
   - Take a photo of an INE document
   - Verify that:
     - Gemini AI analyzes the document
     - ElevenLabs provides voice feedback
     - The conversation flows naturally

## Step 4: Troubleshooting

### Common Issues

**Gemini API Not Working:**
- Check API key is correct
- Verify internet connection
- Check API quota limits
- Ensure the key has proper permissions

**ElevenLabs Not Working:**
- Check API key is correct
- Verify account has sufficient credits
- Check voice ID is valid
- Ensure microphone permissions are granted

**Fallback Behavior:**
- If APIs are not configured, the app will use fallback methods
- Gemini: Basic validation without AI
- ElevenLabs: System text-to-speech

### Debug Information

Check the Xcode console for debug messages:
- `"Gemini API not configured. Using fallback analysis."`
- `"ElevenLabs API not configured. Using system TTS."`
- `"Error analyzing INE document: [error details]"`

## Step 5: Production Considerations

### Security
- Never commit API keys to version control
- Use environment variables or secure storage
- Implement key rotation policies
- Monitor API usage and costs

### Performance
- Implement caching for repeated requests
- Add retry logic for failed requests
- Monitor API response times
- Set appropriate timeouts

### Cost Management
- Monitor API usage regularly
- Set up billing alerts
- Implement usage limits
- Consider caching strategies

## API Usage in Onboarding Flow

### Gemini AI Integration Points:
1. **Document Analysis** - Analyzes INE documents for validity
2. **Conversation Management** - Generates contextual responses
3. **Data Validation** - Provides intelligent suggestions
4. **Error Handling** - Offers helpful guidance

### ElevenLabs Integration Points:
1. **Welcome Messages** - Personalized greetings
2. **Step Guidance** - Voice instructions for each step
3. **Conversation** - Natural voice interaction
4. **Feedback** - Audio confirmation of actions

## Support

If you encounter issues:
1. Check the troubleshooting section above
2. Review the Xcode console for error messages
3. Verify API keys are correctly configured
4. Test with a simple API call first

## Next Steps

Once APIs are configured:
1. Test the complete onboarding flow
2. Customize voice settings if needed
3. Adjust Gemini prompts for your use case
4. Monitor performance and costs
5. Implement additional features as needed

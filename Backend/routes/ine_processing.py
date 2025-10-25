import requests
import json
import re
from typing import Dict, List, Optional
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from datetime import datetime

# Gemini AI Configuration
GEMINI_API_KEY = "YOUR_GEMINI_API_KEY"  # Replace with actual API key
GEMINI_BASE_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent"

router = APIRouter(prefix="/ine", tags=["INE Processing"])

# Pydantic models for INE data
class INEData(BaseModel):
    firstName: str
    lastName: str
    middleName: str
    dateOfBirth: str
    documentNumber: str
    nationality: str
    address: str
    occupation: str
    incomeSource: str
    curp: str
    sex: str
    electoralSection: str
    locality: str
    municipality: str
    state: str
    expirationDate: str
    issueDate: str

class INEAnalysis(BaseModel):
    isValid: bool
    confidence: float
    missingFields: List[str]
    suggestions: List[str]
    validationErrors: List[str]

class OnboardingRequest(BaseModel):
    userId: str
    ineData: INEData
    timestamp: datetime

class OnboardingResponse(BaseModel):
    success: bool
    message: str
    onboardingId: str
    status: str
    nextSteps: List[str]
    analysis: Optional[INEAnalysis] = None

class GeminiRequest(BaseModel):
    contents: List[Dict]
    generationConfig: Dict

class GeminiResponse(BaseModel):
    candidates: List[Dict]

# INE Processing Endpoints
@router.post("/analyze", response_model=INEAnalysis)
async def analyze_ine_document(ine_data: INEData):
    """Analyze INE document data using Gemini AI"""
    try:
        # Create analysis prompt for Gemini
        prompt = create_ine_analysis_prompt(ine_data)
        
        # Send request to Gemini
        analysis_result = await send_gemini_request(prompt)
        
        # Parse and return analysis
        return parse_ine_analysis(analysis_result, ine_data)
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error analyzing INE: {str(e)}")

@router.post("/onboarding", response_model=OnboardingResponse)
async def process_onboarding(request: OnboardingRequest):
    """Process complete onboarding with INE data"""
    try:
        # Analyze INE data
        analysis = await analyze_ine_document(request.ineData)
        
        # Validate INE data
        if not analysis.isValid:
            return OnboardingResponse(
                success=False,
                message="INE data validation failed",
                onboardingId="",
                status="rejected",
                nextSteps=["Please correct the INE data and try again"],
                analysis=analysis
            )
        
        # Generate onboarding ID
        onboarding_id = generate_onboarding_id(request.userId)
        
        # Store onboarding data (in production, save to database)
        # await store_onboarding_data(onboarding_id, request.ineData, analysis)
        
        # Determine next steps
        next_steps = determine_next_steps(analysis)
        
        return OnboardingResponse(
            success=True,
            message="Onboarding data processed successfully",
            onboardingId=onboarding_id,
            status="pending",
            nextSteps=next_steps,
            analysis=analysis
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error processing onboarding: {str(e)}")

@router.get("/status/{user_id}")
async def get_onboarding_status(user_id: str):
    """Get onboarding status for a user"""
    try:
        # In production, fetch from database
        # For now, return mock data
        return {
            "status": "pending",
            "progress": 75,
            "completedSteps": ["document_capture", "data_verification"],
            "pendingSteps": ["voice_verification", "final_confirmation"],
            "lastUpdated": datetime.utcnow().isoformat()
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching status: {str(e)}")

@router.post("/verify-document/{document_number}")
async def verify_document(document_number: str):
    """Verify INE document number against official records"""
    try:
        # In production, integrate with INE official API or database
        # For now, return mock verification
        
        # Basic validation
        if not document_number or len(document_number) != 13:
            return {
                "isValid": False,
                "documentType": "INE",
                "verificationLevel": "basic",
                "warnings": ["Invalid document number format"]
            }
        
        # Mock verification logic
        is_valid = validate_ine_number(document_number)
        
        return {
            "isValid": is_valid,
            "documentType": "INE",
            "verificationLevel": "basic",
            "warnings": [] if is_valid else ["Document number not found in records"]
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error verifying document: {str(e)}")

# Gemini AI Integration
async def send_gemini_request(prompt: str) -> str:
    """Send request to Gemini AI API"""
    url = f"{GEMINI_BASE_URL}?key={GEMINI_API_KEY}"
    
    request_body = {
        "contents": [
            {
                "parts": [{"text": prompt}]
            }
        ],
        "generationConfig": {
            "temperature": 0.7,
            "topK": 40,
            "topP": 0.95,
            "maxOutputTokens": 1024
        }
    }
    
    headers = {
        "Content-Type": "application/json"
    }
    
    response = requests.post(url, json=request_body, headers=headers)
    
    if response.status_code != 200:
        raise Exception(f"Gemini API error: {response.status_code}")
    
    result = response.json()
    
    if "candidates" not in result or not result["candidates"]:
        raise Exception("No content generated by Gemini")
    
    return result["candidates"][0]["content"]["parts"][0]["text"]

def create_ine_analysis_prompt(ine_data: INEData) -> str:
    """Create analysis prompt for Gemini AI"""
    return f"""
    Analiza los siguientes datos extraídos de una credencial INE (Instituto Nacional Electoral) mexicana:
    
    Nombre: {ine_data.firstName} {ine_data.middleName} {ine_data.lastName}
    CURP: {ine_data.curp}
    Fecha de Nacimiento: {ine_data.dateOfBirth}
    Número de Documento: {ine_data.documentNumber}
    Sexo: {ine_data.sex}
    Sección Electoral: {ine_data.electoralSection}
    Localidad: {ine_data.locality}
    Municipio: {ine_data.municipality}
    Estado: {ine_data.state}
    Fecha de Emisión: {ine_data.issueDate}
    Fecha de Vencimiento: {ine_data.expirationDate}
    Dirección: {ine_data.address}
    
    Por favor, analiza estos datos y responde en formato JSON con la siguiente estructura:
    {{
        "isValid": boolean,
        "confidence": number (0-1),
        "missingFields": ["campo1", "campo2"],
        "suggestions": ["sugerencia1", "sugerencia2"],
        "validationErrors": ["error1", "error2"]
    }}
    
    Considera:
    1. Si el CURP tiene el formato correcto (18 caracteres alfanuméricos)
    2. Si las fechas tienen formato válido
    3. Si los campos obligatorios están presentes
    4. Si la información es consistente
    5. Si el documento no está vencido
    6. Si el número de INE tiene el formato correcto (13 dígitos)
    """

def parse_ine_analysis(gemini_response: str, ine_data: INEData) -> INEAnalysis:
    """Parse Gemini response into INEAnalysis object"""
    try:
        # Extract JSON from response
        json_start = gemini_response.find('{')
        json_end = gemini_response.rfind('}') + 1
        
        if json_start == -1 or json_end == 0:
            raise ValueError("No JSON found in response")
        
        json_str = gemini_response[json_start:json_end]
        analysis_data = json.loads(json_str)
        
        return INEAnalysis(
            isValid=analysis_data.get("isValid", False),
            confidence=analysis_data.get("confidence", 0.0),
            missingFields=analysis_data.get("missingFields", []),
            suggestions=analysis_data.get("suggestions", []),
            validationErrors=analysis_data.get("validationErrors", [])
        )
        
    except Exception as e:
        # Fallback analysis
        return INEAnalysis(
            isValid=False,
            confidence=0.0,
            missingFields=["Error parsing analysis"],
            suggestions=["Please try again"],
            validationErrors=[f"Analysis error: {str(e)}"]
        )

def validate_ine_number(document_number: str) -> bool:
    """Validate INE document number format"""
    if not document_number or len(document_number) != 13:
        return False
    
    # Check if all characters are digits
    if not document_number.isdigit():
        return False
    
    # Additional validation logic can be added here
    # For now, return True for valid format
    return True

def generate_onboarding_id(user_id: str) -> str:
    """Generate unique onboarding ID"""
    import uuid
    return f"onb_{user_id}_{uuid.uuid4().hex[:8]}"

def determine_next_steps(analysis: INEAnalysis) -> List[str]:
    """Determine next steps based on analysis"""
    steps = []
    
    if not analysis.isValid:
        steps.append("Correct INE data")
        return steps
    
    if analysis.missingFields:
        steps.append("Complete missing information")
    
    steps.extend([
        "Voice verification",
        "Additional information collection",
        "Final confirmation"
    ])
    
    return steps

# Utility functions
def validate_curp(curp: str) -> bool:
    """Validate CURP format"""
    if not curp or len(curp) != 18:
        return False
    
    # CURP format: 4 letters + 6 digits + 1 letter + 5 letters + 1 letter + 1 digit
    pattern = r'^[A-Z]{4}[0-9]{6}[HM][A-Z]{5}[0-9A-Z][0-9]$'
    return bool(re.match(pattern, curp))

def validate_date_format(date_str: str) -> bool:
    """Validate date format (DD/MM/YYYY)"""
    if not date_str:
        return False
    
    pattern = r'^[0-9]{2}[/-][0-9]{2}[/-][0-9]{4}$'
    return bool(re.match(pattern, date_str))

def is_document_expired(expiration_date: str) -> bool:
    """Check if INE document is expired"""
    if not expiration_date:
        return True
    
    try:
        # Parse date (assuming DD/MM/YYYY format)
        day, month, year = expiration_date.split('/')
        exp_date = datetime(int(year), int(month), int(day))
        return exp_date < datetime.now()
    except:
        return True

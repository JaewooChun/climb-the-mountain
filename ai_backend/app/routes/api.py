from fastapi import APIRouter, HTTPException
from ..models.schemas import *
from ..services.goal_validator import GoalValidator
from ..services.task_generator import TaskGenerator
from ..services.financial_analyzer import FinancialAnalyzer

router = APIRouter(prefix="/api/v1")

# Initialize services
goal_validator = GoalValidator()
task_generator = TaskGenerator()
financial_analyzer = FinancialAnalyzer()

@router.post("/validate-goal", response_model=GoalValidationResponse)
async def validate_financial_goal(request: GoalValidationRequest):
    """Validate if the user's goal is financially relevant using FinBERT"""
    try:
        is_valid, confidence, suggestions = goal_validator.validate_goal(request.goal_text)
        
        return GoalValidationResponse(
            is_valid=is_valid,
            confidence_score=confidence,
            suggested_improvements=suggestions if suggestions else None,
            processed_goal=request.goal_text if is_valid else None
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Goal validation failed: {str(e)}")

@router.post("/generate-tasks", response_model=TaskGenerationResponse)  
async def generate_daily_tasks(request: TaskGenerationRequest):
    """Generate personalized daily tasks using ChatGPT"""
    try:
        # First analyze the financial profile
        analysis = financial_analyzer.analyze_spending_patterns(request.financial_profile)
        
        # Then generate tasks based on goal and analysis
        task_response = task_generator.generate_daily_tasks(
            request.validated_goal,
            request.financial_profile,
            analysis
        )
        
        return task_response
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Task generation failed: {str(e)}")

@router.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "message": "Financial Peak API is running"}

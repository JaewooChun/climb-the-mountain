from pydantic import BaseModel, Field
from typing import List, Optional, Dict

class GoalValidationRequest(BaseModel):
    goal_text: str = Field(..., min_length=5, max_length=500)
    user_id: Optional[str] = None

class GoalValidationResponse(BaseModel):
    is_valid: bool
    confidence_score: float
    suggestions: Optional[List[str]] = []
    processed_goal: Optional[str] = None

class TaskGenerationRequest(BaseModel):
    validated_goal: str
    target_amount = Optional[float] = None
    timeline_days = Optional[int] = None

class DailyTask(BaseModel):
    id: str
    title: str
    description: str
    estimated_impact: float  # Dollar amount
    difficulty: str  # "easy", "medium", "hard"
    category: str  # "spending", "saving", "earning"
    actionable_steps: List[str]

class TaskGenerationResponse(BaseModel):
    tasks: List[DailyTask]
    total_potential_impact: float
    analysis_summary: str


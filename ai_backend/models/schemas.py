from pydantic import BaseModel, Field
from typing import List, Optional, Dict

class GoalValidationRequest(BaseModel):
    goal_text: str = Field(..., min_length=5, max_length=500)
    user_id: Optional[str] = None
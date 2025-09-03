import openai
import os
import json
from ..models.schemas import DailyTask, TaskGenerationResponse

class TaskGenerator:
    def __init__(self):
        openai.api_key = os.getenv("OPENAI_API_KEY")

    def generate_daily_tasks(self, goal: str, financial_profile, analysis):
        """Generate 1-3 personalized daily tasks using ChatGPT"""
        
        # Prepare context for ChatGPT
        context = self._build_context(goal, financial_profile, analysis)
        
        prompt = f"""
        You are a financial advisor AI. Based on the user's goal and spending analysis, 
        generate 1-3 specific, actionable daily tasks that will help them achieve their goal.
        
        Context:
        {context}
        
        Requirements:
        - Tasks must be specific and actionable today
        - Include realistic dollar impact estimates
        - Vary difficulty levels (easy/medium/hard)
        - Focus on behavioral changes, not just "spend less"
        - Make tasks personal based on their spending patterns
        
        Return ONLY a valid JSON object with this structure:
        {{
            "tasks": [
                {{
                    "title": "Brief task title",
                    "description": "Detailed description of what to do",
                    "estimated_impact": 15.50,
                    "difficulty": "easy",
                    "category": "spending",
                    "actionable_steps": ["Step 1", "Step 2", "Step 3"]
                }}
            ],
            "analysis_summary": "Brief explanation of why these tasks were chosen"
        }}
        """

        try:
            response = openai.ChatCompletion.create(
                model="gpt-4",
                messages=[
                    {"role": "system", "content": "You are a helpful financial advisor."},
                    {"role": "user", "content": prompt}
                ],
                temperature=0.7,
                max_tokens=1000
            )
            
            response_text = response.choices[0].message.content
            parsed_response = json.loads(response_text)
            
            # Convert to proper models
            tasks = []
            total_impact = 0
            
            for task_data in parsed_response["tasks"]:
                task = DailyTask(
                    id=str(uuid.uuid4()),
                    title=task_data["title"],
                    description=task_data["description"],
                    estimated_impact=task_data["estimated_impact"],
                    difficulty=task_data["difficulty"],
                    category=task_data["category"],
                    actionable_steps=task_data["actionable_steps"]
                )
                tasks.append(task)
                total_impact += task.estimated_impact
            
            return TaskGenerationResponse(
                tasks=tasks,
                total_potential_impact=total_impact,
                analysis_summary=parsed_response["analysis_summary"]
            )
            
        except Exception as e:
            # Print error for debugging
            print("Error generating tasks:", e)
    
    def build_context(self, goal, financial_profile, analysis):
        """Build context string for ChatGPT"""
        context = f"""
        User's Goal: {goal}
        
        Spending Analysis:
        - Total monthly spending: ${analysis['total_monthly_spending']:.2f}
        - Top spending categories: {', '.join(analysis['top_categories'])}
        - Average transaction: ${analysis['average_transaction']:.2f}
        
        Savings Opportunities:
        """
        
        for opp in analysis['savings_opportunities']:
            context += f"- {opp['category']}: Currently ${opp['current_spending']:.2f}/month, "
            context += f"potential savings ${opp['potential_savings']:.2f}\n"
        
        return context
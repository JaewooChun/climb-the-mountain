import openai
import json
import uuid
from ..models.schemas import DailyTask, TaskGenerationResponse
from ..config import settings

class TaskGenerator:
    def __init__(self):
        api_key = settings.OPENAI_API_KEY
        self.client = openai.OpenAI(api_key=api_key) if api_key else None

    def generate_daily_tasks(self, goal: str, financial_profile, analysis):
        """Generate 1-3 personalized daily tasks using ChatGPT"""
        
        # Prepare context for ChatGPT
        context = self.build_context(goal, financial_profile, analysis)
        
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

        # If no OpenAI API key, return mock tasks for testing
        if not self.client:
            print("OpenAI API key not found, generating mock tasks for testing...")
            return self._generate_mock_tasks(goal, analysis)
        
        try:
            response = self.client.chat.completions.create(
                model="gpt-4o-mini",
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
            
            # Check if this is a quota/usage limit error
            error_str = str(e).lower()
            if "quota" in error_str or "usage" in error_str or "insufficient_quota" in error_str or "429" in str(e):
                print("⚠️  OpenAI API quota/usage limit reached - using default mock task instead")
                return self._generate_mock_tasks(goal, analysis)
            
            # Return empty response with error message for other errors
            return TaskGenerationResponse(
                tasks=[],
                total_potential_impact=0.0,
                analysis_summary=f"Error generating tasks: {str(e)}"
            )
    
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
    
    def _generate_mock_tasks(self, goal: str, analysis):
        """Generate mock tasks for testing when OpenAI API is not available"""
        print("OpenAI API key not found, generating mock tasks for testing...")
        
        # Extract top spending category for personalized task
        top_category = analysis['top_categories'][0] if analysis['top_categories'] else 'general spending'
        savings_opp = analysis['savings_opportunities'][0] if analysis['savings_opportunities'] else None
        
        mock_tasks = []
        
        # Task 1: Track spending for a day
        task1 = DailyTask(
            id=str(uuid.uuid4()),
            title="Track Your Daily Spending",
            description=f"Write down every purchase you make today, focusing on {top_category} category. Use a notebook or phone app to record amounts and reasons for each purchase.",
            estimated_impact=25.00,
            difficulty="easy",
            category="spending",
            actionable_steps=[
                "Start a spending log when you wake up",
                "Record each purchase with amount and category",
                f"Pay special attention to {top_category} expenses",
                "Review your log before bed"
            ]
        )
        mock_tasks.append(task1)
        
        # Task 2: Based on savings opportunity (if available)
        if savings_opp:
            task2 = DailyTask(
                id=str(uuid.uuid4()),
                title=f"Reduce {savings_opp['category']} Spending",
                description=f"You're currently spending ${savings_opp['current_spending']:.2f}/month on {savings_opp['category']}. Today, find one way to cut this expense.",
                estimated_impact=savings_opp['potential_savings'],
                difficulty="medium", 
                category="savings",
                actionable_steps=[
                    f"Review your {savings_opp['category']} expenses from last week",
                    "Identify the most expensive or unnecessary item",
                    "Find a cheaper alternative or eliminate it for today",
                    f"Calculate how much you'll save monthly if you stick to this change"
                ]
            )
            mock_tasks.append(task2)
        
        # Task 3: Goal-related planning task
        task3 = DailyTask(
            id=str(uuid.uuid4()),
            title="Create Action Plan for Your Goal",
            description=f"Break down your goal '{goal}' into smaller weekly targets and identify what you need to change starting today.",
            estimated_impact=50.00,
            difficulty="medium",
            category="planning",
            actionable_steps=[
                "Write down your specific financial goal",
                "Calculate how much you need to save/reduce spending monthly",
                "Identify 3 changes you can make this week",
                "Set up a weekly check-in reminder on your phone"
            ]
        )
        mock_tasks.append(task3)
        
        total_impact = sum(task.estimated_impact for task in mock_tasks)
        
        return TaskGenerationResponse(
            tasks=mock_tasks,
            total_potential_impact=total_impact,
            analysis_summary=f"Generated 3 personalized tasks based on your goal '{goal}' and spending analysis. Focus on {top_category} expenses which show the most opportunity for improvement."
        )
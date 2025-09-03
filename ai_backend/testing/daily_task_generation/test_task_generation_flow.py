import sys
import os
sys.path.append(os.path.join(os.path.dirname(__file__), '..', '..'))

import unittest
from unittest.mock import patch, MagicMock
from app.services.financial_analyzer import FinancialAnalyzer
from app.services.task_generator import TaskGenerator
from mock_data import create_mock_financial_profile, get_test_goals

class TestTaskGenerationFlow(unittest.TestCase):
    def setUp(self):
        """Set up test fixtures."""
        self.analyzer = FinancialAnalyzer()
        self.task_generator = TaskGenerator()
    
    @patch('app.services.task_generator.openai')
    def test_full_task_generation_flow(self, mock_openai):
        """Test the complete flow: Profile -> Analysis -> Tasks."""
        # Mock OpenAI response
        mock_response = MagicMock()
        mock_response.choices = [MagicMock()]
        mock_response.choices[0].message.content = '''
        {
            "tasks": [
                {
                    "id": "task_1",
                    "title": "Review monthly subscriptions",
                    "description": "Cancel unused subscriptions to save money",
                    "estimated_impact": 50.0,
                    "difficulty": "easy",
                    "category": "spending",
                    "actionable_steps": ["List all subscriptions", "Cancel unused ones"]
                }
            ],
            "total_potential_impact": 50.0,
            "analysis_summary": "You can save money by reducing subscription costs"
        }
        '''
        mock_openai.ChatCompletion.create.return_value = mock_response
        
        # Test different financial profiles
        profiles = ["balanced", "high_spender", "frugal", "struggling"]
        goals = get_test_goals()
        
        for profile_type in profiles:
            for goal in goals[:2]:  # Test with first 2 goals
                with self.subTest(profile=profile_type, goal=goal):
                    # Step 1: Create financial profile
                    profile = create_mock_financial_profile(profile_type)
                    
                    # Step 2: Analyze spending patterns
                    analysis = self.analyzer.analyze_spending_patterns(profile)
                    
                    # Verify analysis structure
                    self.assertIn("total_monthly_spending", analysis)
                    self.assertIn("spending_by_category", analysis)
                    self.assertIn("savings_opportunities", analysis)
                    
                    # Step 3: Generate tasks (mocked)
                    task_response = self.task_generator.generate_daily_tasks(
                        goal, profile, analysis
                    )
                    
                    # Verify task response structure
                    self.assertTrue(hasattr(task_response, 'tasks'))
                    self.assertTrue(hasattr(task_response, 'total_potential_impact'))
                    self.assertTrue(hasattr(task_response, 'analysis_summary'))
    
    def test_spending_analysis_categories(self):
        """Test that spending analysis identifies major expense categories."""
        profile = create_mock_financial_profile("high_spender")
        analysis = self.analyzer.analyze_spending_patterns(profile)
        
        # Should have identifiable categories
        self.assertGreater(len(analysis["spending_by_category"]), 0)
        self.assertGreater(len(analysis["top_categories"]), 0)
        
        # Top categories should be ordered by amount
        spending = analysis["spending_by_category"]
        top_cats = analysis["top_categories"]
        
        if len(top_cats) > 1:
            for i in range(len(top_cats) - 1):
                self.assertGreaterEqual(
                    spending[top_cats[i]], 
                    spending[top_cats[i + 1]]
                )
    
    def test_savings_opportunities_identification(self):
        """Test identification of savings opportunities."""
        profile = create_mock_financial_profile("high_spender")
        analysis = self.analyzer.analyze_spending_patterns(profile)
        
        # High spenders should have savings opportunities
        opportunities = analysis["savings_opportunities"]
        
        for opp in opportunities:
            # Should have required fields
            self.assertIn("category", opp)
            self.assertIn("current_spending", opp)
            self.assertIn("potential_savings", opp)
            
            # Savings should be realistic (20% of current)
            expected = opp["current_spending"] * 0.2
            self.assertAlmostEqual(opp["potential_savings"], expected, places=2)
            
            # Should represent significant spending (>15% of total)
            total = analysis["total_monthly_spending"]
            percentage = opp["current_spending"] / total
            self.assertGreater(percentage, 0.15)
    
    @patch('app.services.task_generator.openai')
    def test_task_generation_with_different_goals(self, mock_openai):
        """Test task generation adapts to different financial goals."""
        # Mock different responses for different goals
        def mock_response_generator(goal_type):
            mock_response = MagicMock()
            mock_response.choices = [MagicMock()]
            
            if "save" in goal_type.lower():
                content = '''
                {
                    "tasks": [
                        {
                            "id": "save_1",
                            "title": "Automate savings transfer",
                            "description": "Set up automatic transfer to savings",
                            "estimated_impact": 100.0,
                            "difficulty": "easy",
                            "category": "saving",
                            "actionable_steps": ["Open banking app", "Set up auto-transfer"]
                        }
                    ],
                    "total_potential_impact": 100.0,
                    "analysis_summary": "Focus on consistent saving habits"
                }
                '''
            elif "debt" in goal_type.lower():
                content = '''
                {
                    "tasks": [
                        {
                            "id": "debt_1",
                            "title": "Make extra debt payment",
                            "description": "Pay extra $50 toward highest interest debt",
                            "estimated_impact": 50.0,
                            "difficulty": "medium",
                            "category": "spending",
                            "actionable_steps": ["Identify highest interest debt", "Make extra payment"]
                        }
                    ],
                    "total_potential_impact": 50.0,
                    "analysis_summary": "Focus on debt reduction strategies"
                }
                '''
            else:
                content = '''
                {
                    "tasks": [
                        {
                            "id": "general_1",
                            "title": "Track expenses",
                            "description": "Monitor daily spending",
                            "estimated_impact": 25.0,
                            "difficulty": "easy",
                            "category": "spending",
                            "actionable_steps": ["Use expense app", "Review daily"]
                        }
                    ],
                    "total_potential_impact": 25.0,
                    "analysis_summary": "Focus on financial awareness"
                }
                '''
            
            mock_response.choices[0].message.content = content
            return mock_response
        
        profile = create_mock_financial_profile("balanced")
        analysis = self.analyzer.analyze_spending_patterns(profile)
        
        goals = [
            "I want to save $5000 for emergency fund",
            "I want to pay off my credit card debt", 
            "I want to invest in retirement"
        ]
        
        for goal in goals:
            mock_openai.ChatCompletion.create.return_value = mock_response_generator(goal)
            
            task_response = self.task_generator.generate_daily_tasks(
                goal, profile, analysis
            )
            
            # Verify response structure
            self.assertTrue(hasattr(task_response, 'tasks'))
            self.assertGreater(len(task_response.tasks), 0)
            
            # Check task structure
            task = task_response.tasks[0]
            required_fields = ["id", "title", "description", "estimated_impact", 
                             "difficulty", "category", "actionable_steps"]
            
            for field in required_fields:
                self.assertTrue(hasattr(task, field))
    
    def test_profile_variations_generate_different_analyses(self):
        """Test that different financial profiles generate different analyses."""
        profiles = {
            "high_spender": create_mock_financial_profile("high_spender"),
            "frugal": create_mock_financial_profile("frugal"),
            "struggling": create_mock_financial_profile("struggling")
        }
        
        analyses = {}
        for name, profile in profiles.items():
            analyses[name] = self.analyzer.analyze_spending_patterns(profile)
        
        # High spender should have higher total spending
        self.assertGreater(
            analyses["high_spender"]["total_monthly_spending"],
            analyses["frugal"]["total_monthly_spending"]
        )

        # High spender should have higher savings opportunities
        self.assertGreaterEqual(
            len(analyses["high_spender"]["savings_opportunities"]),
            len(analyses["frugal"]["savings_opportunities"])
        )

if __name__ == '__main__':
    unittest.main()
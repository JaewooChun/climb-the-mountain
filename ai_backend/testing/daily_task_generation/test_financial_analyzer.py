import sys
import os
sys.path.append(os.path.join(os.path.dirname(__file__), '..', '..'))

import unittest
from app.services.financial_analyzer import FinancialAnalyzer
from mock_data import create_mock_financial_profile

class TestFinancialAnalyzer(unittest.TestCase):
    def setUp(self):
        """Set up test fixtures."""
        self.analyzer = FinancialAnalyzer()
    
    def test_analyze_spending_patterns_balanced(self):
        """Test financial analysis for a balanced spending profile."""
        profile = create_mock_financial_profile("balanced")
        analysis = self.analyzer.analyze_spending_patterns(profile)
        
        # Check that all expected keys are present
        expected_keys = [
            "total_monthly_spending",
            "spending_by_category", 
            "top_categories",
            "savings_opportunities",
            "average_transaction"
        ]
        
        for key in expected_keys:
            self.assertIn(key, analysis, f"Missing key: {key}")
        
        # Check data types and ranges
        self.assertIsInstance(analysis["total_monthly_spending"], float)
        self.assertGreater(analysis["total_monthly_spending"], 0)
        
        self.assertIsInstance(analysis["spending_by_category"], dict)
        self.assertGreater(len(analysis["spending_by_category"]), 0)
        
        self.assertIsInstance(analysis["top_categories"], list)
        self.assertLessEqual(len(analysis["top_categories"]), 5)
        
        self.assertIsInstance(analysis["savings_opportunities"], list)
        
        self.assertIsInstance(analysis["average_transaction"], float)
    
    def test_analyze_spending_patterns_high_spender(self):
        """Test analysis for high spending profile."""
        profile = create_mock_financial_profile("high_spender")
        analysis = self.analyzer.analyze_spending_patterns(profile)
        
        # High spenders should have more savings opportunities
        self.assertGreater(analysis["total_monthly_spending"], 0)
        self.assertGreater(len(analysis["spending_by_category"]), 0)
        
        # Should identify savings opportunities
        for opportunity in analysis["savings_opportunities"]:
            self.assertIn("category", opportunity)
            self.assertIn("current_spending", opportunity)
            self.assertIn("potential_savings", opportunity)
            self.assertGreater(opportunity["current_spending"], 0)
            self.assertGreater(opportunity["potential_savings"], 0)
    
    def test_analyze_spending_patterns_frugal(self):
        """Test analysis for frugal spending profile."""
        profile = create_mock_financial_profile("frugal")
        analysis = self.analyzer.analyze_spending_patterns(profile)
        
        # Frugal users might have fewer savings opportunities
        self.assertGreaterEqual(len(analysis["savings_opportunities"]), 0)
        
        # Should still have spending analysis
        self.assertGreater(analysis["total_monthly_spending"], 0)
        self.assertIsInstance(analysis["spending_by_category"], dict)
    
    def test_analyze_spending_patterns_struggling(self):
        """Test analysis for users with financial struggles."""
        profile = create_mock_financial_profile("struggling")
        analysis = self.analyzer.analyze_spending_patterns(profile)
        
        # Even struggling users should have analysis
        self.assertGreater(analysis["total_monthly_spending"], 0)
        self.assertGreaterEqual(len(analysis["top_categories"]), 1)
    
    def test_category_spending_calculation(self):
        """Test that category spending is calculated correctly."""
        profile = create_mock_financial_profile("balanced")
        analysis = self.analyzer.analyze_spending_patterns(profile)
        
        # Sum of category spending should equal total spending
        category_total = sum(analysis["spending_by_category"].values())
        self.assertAlmostEqual(
            category_total, 
            analysis["total_monthly_spending"], 
            places=2
        )
    
    def test_top_categories_ordering(self):
        """Test that top categories are ordered by spending amount."""
        profile = create_mock_financial_profile("balanced")
        analysis = self.analyzer.analyze_spending_patterns(profile)
        
        spending_by_category = analysis["spending_by_category"]
        top_categories = analysis["top_categories"]
        
        if len(top_categories) > 1:
            # Check that categories are ordered from highest to lowest spending
            for i in range(len(top_categories) - 1):
                current_spending = spending_by_category.get(top_categories[i], 0)
                next_spending = spending_by_category.get(top_categories[i + 1], 0)
                self.assertGreaterEqual(current_spending, next_spending)
    
    def test_savings_opportunities_threshold(self):
        """Test that savings opportunities meet the 15% threshold."""
        profile = create_mock_financial_profile("high_spender")
        analysis = self.analyzer.analyze_spending_patterns(profile)
        
        total_spending = analysis["total_monthly_spending"]
        
        for opportunity in analysis["savings_opportunities"]:
            # Each opportunity should be > 15% of total spending
            category_percentage = opportunity["current_spending"] / total_spending
            self.assertGreater(category_percentage, 0.15)
            
            # Potential savings should be 20% of current spending
            expected_savings = opportunity["current_spending"] * 0.2
            self.assertAlmostEqual(
                opportunity["potential_savings"],
                expected_savings,
                places=2
            )
    
    def test_empty_transactions_handling(self):
        """Test handling of profiles with no transactions."""
        from app.models.schemas import FinancialProfile
        
        empty_profile = FinancialProfile(
            user_id="empty_user",
            transactions=[],
            monthly_income=3000.0,
            current_savings=1000.0
        )
        
        analysis = self.analyzer.analyze_spending_patterns(empty_profile)
        
        self.assertEqual(analysis["total_monthly_spending"], 0)
        self.assertEqual(len(analysis["spending_by_category"]), 0)
        self.assertEqual(len(analysis["top_categories"]), 0)
        self.assertEqual(len(analysis["savings_opportunities"]), 0)
        self.assertEqual(analysis["average_transaction"], 0)

if __name__ == '__main__':
    unittest.main()
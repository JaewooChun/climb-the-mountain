import sys
import os
sys.path.append(os.path.join(os.path.dirname(__file__), '..', '..'))

import unittest
from unittest.mock import patch, MagicMock
import numpy as np
from app.services.goal_validator import GoalValidator

class TestGoalValidator(unittest.TestCase):
    def setUp(self):
        """Set up test fixtures before each test method."""
        with patch('app.services.goal_validator.AutoTokenizer'):
            with patch('app.services.goal_validator.AutoModelForSequenceClassification'):
                self.validator = GoalValidator()
                # Mock the financial embeddings for testing
                self.validator.financial_embeddings = np.random.rand(5, 768)  # 5 keywords, 768 dim
    
    def test_valid_financial_goals(self):
        """Test that valid financial goals are properly identified."""
        valid_goals = [
            "I want to save $10,000 for an emergency fund",
            "My goal is to pay off my credit card debt",
            "I want to invest in a retirement fund",
            "I need to create a budget for monthly expenses"
        ]
        
        with patch.object(self.validator, 'get_embedding') as mock_embedding:
            # Mock high similarity for valid goals
            mock_embedding.return_value = np.random.rand(768)
            
            with patch('app.services.goal_validator.cosine_similarity') as mock_similarity:
                mock_similarity.return_value = np.array([[0.8]])  # High similarity
                
                for goal in valid_goals:
                    is_valid, confidence, suggestions = self.validator.validate_goal(goal)
                    
                    self.assertTrue(is_valid, f"Goal should be valid: {goal}")
                    self.assertGreater(confidence, 0.5)
                    self.assertEqual(len(suggestions), 0)
    
    def test_invalid_non_financial_goals(self):
        """Test that non-financial goals are properly rejected."""
        invalid_goals = [
            "I want to learn how to play piano",
            "My goal is to run a marathon",
            "I want to learn Spanish",
            "I need to organize my closet"
        ]
        
        with patch.object(self.validator, 'get_embedding') as mock_embedding:
            mock_embedding.return_value = np.random.rand(768)
            
            with patch('app.services.goal_validator.cosine_similarity') as mock_similarity:
                mock_similarity.return_value = np.array([[0.2]])  # Low similarity
                
                for goal in invalid_goals:
                    is_valid, confidence, suggestions = self.validator.validate_goal(goal)
                    
                    self.assertFalse(is_valid, f"Goal should be invalid: {goal}")
                    self.assertLess(confidence, 0.5)
                    self.assertGreater(len(suggestions), 0)
    
    def test_borderline_goals(self):
        """Test goals with moderate financial relevance."""
        borderline_goals = [
            "I want to buy expensive clothes",
            "I need to plan for my future",
            "I want to be more responsible with money"
        ]
        
        with patch.object(self.validator, 'get_embedding') as mock_embedding:
            mock_embedding.return_value = np.random.rand(768)
            
            with patch('app.services.goal_validator.cosine_similarity') as mock_similarity:
                mock_similarity.return_value = np.array([[0.4]])  # Moderate similarity
                
                for goal in borderline_goals:
                    is_valid, confidence, suggestions = self.validator.validate_goal(goal)
                    
                    self.assertFalse(is_valid)
                    self.assertLessEqual(confidence, 0.5)
                    self.assertGreater(len(suggestions), 0)
    
    def test_confidence_score_ranges(self):
        """Test that confidence scores are within expected ranges."""
        test_goal = "I want to save money for retirement"
        
        with patch.object(self.validator, 'get_embedding') as mock_embedding:
            mock_embedding.return_value = np.random.rand(768)
            
            # Test high confidence
            with patch('app.services.goal_validator.cosine_similarity') as mock_similarity:
                mock_similarity.return_value = np.array([[0.9]])
                
                is_valid, confidence, suggestions = self.validator.validate_goal(test_goal)
                
                self.assertTrue(is_valid)
                self.assertGreaterEqual(confidence, 0.0)
                self.assertLessEqual(confidence, 1.0)
                self.assertAlmostEqual(confidence, 0.9, places=2)
    
    def test_suggestion_generation(self):
        """Test that appropriate suggestions are generated for invalid goals."""
        with patch.object(self.validator, 'get_embedding') as mock_embedding:
            mock_embedding.return_value = np.random.rand(768)
            
            # Test very low similarity (< 0.3)
            with patch('app.services.goal_validator.cosine_similarity') as mock_similarity:
                mock_similarity.return_value = np.array([[0.1]])
                
                is_valid, confidence, suggestions = self.validator.validate_goal("I want to learn to dance")
                
                self.assertFalse(is_valid)
                self.assertIn("unrelated to financial matters", suggestions[0])
            
            # Test moderate similarity (0.3 - 0.5)
            with patch('app.services.goal_validator.cosine_similarity') as mock_similarity:
                mock_similarity.return_value = np.array([[0.4]])
                
                is_valid, confidence, suggestions = self.validator.validate_goal("I want to be better with money")
                
                self.assertFalse(is_valid)
                self.assertIn("more specific", suggestions[0])

if __name__ == '__main__':
    unittest.main()
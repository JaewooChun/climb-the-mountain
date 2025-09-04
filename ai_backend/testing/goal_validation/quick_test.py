#!/usr/bin/env python3
import sys
import os
sys.path.append(os.path.join(os.path.dirname(__file__), '..', '..'))

from app.services.goal_validator import GoalValidator

def test_goals():
    """Quick test script to validate different goal sentences"""
    print("Initializing GoalValidator...")
    validator = GoalValidator()
    print("=" * 50)
    
    # Test cases
    test_goals = [
        # Should be rejected
        "testing",
        "I want to learn piano",
        "I want to run a marathon",
        "I need to organize my closet",
        "learn spanish",
        
        # Should be accepted
        "I want to save $10,000",
        "I need to pay off my debt",
        "I want to invest in stocks",
        "I need to create a budget",
        "save money for retirement",
        
        # Borderline cases
        "I want to buy a house",
        "I need to plan for my future",
        "I want to be better with money",
        "reduce my expenses"
    ]
    
    for goal in test_goals:
        print(f"\nTesting: '{goal}'")
        is_valid, confidence, suggestions = validator.validate_goal(goal)
        
        status = "✅ VALID" if is_valid else "❌ INVALID"
        print(f"Result: {status} (confidence: {confidence:.3f})")
        
        if suggestions:
            print(f"Suggestions: {suggestions[0]}")
        print("-" * 30)

def interactive_test():
    """Interactive mode to test custom goals"""
    print("\nInteractive mode - Enter goals to test (type 'quit' to exit)")
    validator = GoalValidator()
    
    while True:
        goal = input("\nEnter goal to test: ").strip()
        if goal.lower() in ['quit', 'exit', 'q']:
            break
            
        if not goal:
            continue
            
        is_valid, confidence, suggestions = validator.validate_goal(goal)
        status = "✅ VALID" if is_valid else "❌ INVALID"
        print(f"Result: {status} (confidence: {confidence:.3f})")
        
        if suggestions:
            print(f"Suggestions: {suggestions[0]}")

if __name__ == "__main__":
    print("Goal Validator Quick Test")
    print("=" * 50)
    
    # Run predefined tests
    test_goals()
    
    # Ask if user wants interactive mode
    response = input("\nWould you like to test custom goals interactively? (y/n): ").strip().lower()
    if response in ['y', 'yes']:
        interactive_test()
    
    print("\nTest completed!")
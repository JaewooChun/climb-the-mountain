#!/usr/bin/env python3

import sys
import os
sys.path.append(os.path.join(os.path.dirname(__file__), '..', '..'))

import unittest
from test_financial_analyzer import TestFinancialAnalyzer
from test_task_generation_flow import TestTaskGenerationFlow

def run_daily_task_generation_tests():
    """Run all daily task generation tests and display results."""
    print("=" * 70)
    print("DAILY TASK GENERATION TESTING SUITE")
    print("=" * 70)
    
    # Create test suite
    test_suite = unittest.TestSuite()
    
    # Add all test cases
    test_suite.addTest(unittest.makeSuite(TestFinancialAnalyzer))
    test_suite.addTest(unittest.makeSuite(TestTaskGenerationFlow))
    
    # Run tests with detailed output
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(test_suite)
    
    # Summary
    print("\n" + "=" * 70)
    print("TEST SUMMARY")
    print("=" * 70)
    print(f"Tests run: {result.testsRun}")
    print(f"Failures: {len(result.failures)}")
    print(f"Errors: {len(result.errors)}")
    
    if result.failures:
        print("\nFAILURES:")
        for test, traceback in result.failures:
            print(f"- {test}: {traceback}")
    
    if result.errors:
        print("\nERRORS:")
        for test, traceback in result.errors:
            print(f"- {test}: {traceback}")
    
    success = len(result.failures) == 0 and len(result.errors) == 0
    print(f"\nOVERALL: {'PASSED' if success else 'FAILED'}")
    return success

if __name__ == '__main__':
    success = run_daily_task_generation_tests()
    sys.exit(0 if success else 1)
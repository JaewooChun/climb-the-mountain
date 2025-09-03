#!/usr/bin/env python3

import sys
import os
sys.path.append(os.path.join(os.path.dirname(__file__), '..'))

import subprocess
from pathlib import Path

def run_all_tests():
    """Run all test suites in the testing directory."""
    print("=" * 80)
    print("FINANCIAL PEAK AI BACKEND - COMPREHENSIVE TEST SUITE")
    print("=" * 80)
    
    testing_dir = Path(__file__).parent
    results = {}
    
    # Test suites to run
    test_suites = [
        {
            "name": "Goal Validation Tests",
            "script": testing_dir / "goal_validation" / "run_tests.py"
        },
        {
            "name": "Daily Task Generation Tests", 
            "script": testing_dir / "daily_task_generation" / "run_tests.py"
        }
    ]
    
    overall_success = True
    
    for suite in test_suites:
        print(f"\n Running {suite['name']}...")
        print("-" * 60)
        
        try:
            result = subprocess.run(
                [sys.executable, str(suite['script'])],
                capture_output=True,
                text=True,
                timeout=300  # 5 minute timeout
            )
            
            print(result.stdout)
            if result.stderr:
                print("STDERR:", result.stderr)
            
            results[suite['name']] = result.returncode == 0
            if result.returncode != 0:
                overall_success = False
                
        except subprocess.TimeoutExpired:
            print(f"{suite['name']} TIMED OUT")
            results[suite['name']] = False
            overall_success = False
            
        except Exception as e:
            print(f"Error running {suite['name']}: {e}")
            results[suite['name']] = False
            overall_success = False
    
    # Final summary
    print("\n" + "=" * 80)
    print("TEST RESULTS")
    print("=" * 80)
    
    for suite_name, success in results.items():
        status = "PASSED" if success else "FAILED"
        print(f"{suite_name}: {status}")
    
    print(f"\nOVERALL RESULT: {'ALL TESTS PASSED' if overall_success else 'SOME TESTS FAILED'}")
    
    if overall_success:
        print("\nAll systems are GOD DAMN finally working")
        print("AI backend is ready for integration with the Flutter frontend.")
    else:
        print("\nSome tests failed. YOU SUCK.")
    
    return overall_success

if __name__ == '__main__':
    success = run_all_tests()
    sys.exit(0 if success else 1)
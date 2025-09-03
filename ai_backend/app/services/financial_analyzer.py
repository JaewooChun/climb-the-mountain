from collections import defaultdict

class FinancialAnalyzer:
    def analyze_spending_patterns(self, profile):
        "Analyze user's spending patterns from their transaction history"

        category_spending = defaultdict(float)
        total_spending = 0

        for transaction in profile.transactions:
            
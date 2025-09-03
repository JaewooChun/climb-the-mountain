from collections import defaultdict

class FinancialAnalyzer:
    def analyze_spending_patterns(self, profile):
        "Analyze user's spending patterns from their transaction history"

        category_spending = defaultdict(float)
        total_spending = 0

        for transaction in profile.transactions:
            if transaction.amount < 0:  # Expense
                category_spending[transaction.category] += abs(transaction.amount)
                total_spending += abs(transaction.amount)
        
        # Calculate monthly averages (assuming 30 days of data)
        monthly_spending = {}
        for category, amount in category_spending.items():
            monthly_spending[category] = amount
        
        # Identify high-spending categories
        sorted_categories = sorted(monthly_spending.items(), 
                                 key=lambda x: x[1], reverse=True)
        
        # Calculate potential savings opportunities
        savings_opportunities = []
        for category, amount in sorted_categories[:3]:  # Top 3 spending categories
            if amount > total_spending * 0.15:  # If > 15% of total spending
                potential_reduction = amount * 0.2  # Assume 20% reduction possible
                savings_opportunities.append({
                    "category": category,
                    "current_spending": amount,
                    "potential_savings": potential_reduction
                })

        return {
            "total_monthly_spending": total_spending,
            "spending_by_category": dict(monthly_spending),
            "top_categories": [cat for cat, _ in sorted_categories[:5]],
            "savings_opportunities": savings_opportunities,
            "average_transaction": total_spending / len(profile.transactions) if profile.transactions else 0
        }
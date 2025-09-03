from datetime import datetime, timedelta
from app.models.schemas import Transaction, FinancialProfile
import random

def create_mock_transactions(num_transactions=30, user_id="test_user_123"):
    """Create mock transaction data for testing."""
    
    categories = [
        "Groceries", "Dining", "Transportation", "Entertainment", 
        "Utilities", "Rent", "Shopping", "Healthcare", "Gas", 
        "Coffee", "Subscriptions", "Fitness"
    ]
    
    merchants = {
        "Groceries": ["Whole Foods", "Safeway", "Trader Joe's", "Costco"],
        "Dining": ["McDonald's", "Chipotle", "Local Restaurant", "Pizza Place"],
        "Transportation": ["Uber", "Lyft", "Gas Station", "Public Transit"],
        "Entertainment": ["Netflix", "Spotify", "Movie Theater", "Concert"],
        "Utilities": ["PG&E", "Comcast", "Water Department", "Phone Company"],
        "Rent": ["Property Management", "Landlord"],
        "Shopping": ["Amazon", "Target", "Best Buy", "Local Store"],
        "Healthcare": ["CVS Pharmacy", "Doctor Office", "Dentist"],
        "Gas": ["Shell", "Chevron", "Exxon"],
        "Coffee": ["Starbucks", "Local Cafe", "Peet's Coffee"],
        "Subscriptions": ["Netflix", "Spotify", "Adobe", "Gym"],
        "Fitness": ["Gym Membership", "Personal Trainer", "Yoga Studio"]
    }
    
    transactions = []
    base_date = datetime.now() - timedelta(days=30)
    
    for i in range(num_transactions):
        category = random.choice(categories)
        merchant = random.choice(merchants.get(category, ["Generic Merchant"]))
        
        # Generate realistic amounts based on category
        if category == "Rent":
            amount = -random.uniform(1200, 2500)
        elif category == "Groceries":
            amount = -random.uniform(25, 150)
        elif category == "Dining":
            amount = -random.uniform(8, 75)
        elif category == "Transportation":
            amount = -random.uniform(5, 45)
        elif category == "Utilities":
            amount = -random.uniform(50, 200)
        elif category == "Entertainment":
            amount = -random.uniform(10, 100)
        elif category == "Shopping":
            amount = -random.uniform(15, 300)
        elif category == "Healthcare":
            amount = -random.uniform(20, 500)
        elif category == "Gas":
            amount = -random.uniform(30, 80)
        elif category == "Coffee":
            amount = -random.uniform(3, 12)
        elif category == "Subscriptions":
            amount = -random.uniform(5, 50)
        elif category == "Fitness":
            amount = -random.uniform(20, 150)
        else:
            amount = -random.uniform(10, 100)
        
        # Add some income transactions
        if random.random() < 0.1:  # 10% chance of income
            amount = random.uniform(500, 3000)
            category = "Income"
            merchant = "Employer"
        
        transaction_date = base_date + timedelta(days=random.randint(0, 29))
        
        transaction = Transaction(
            id=f"txn_{i+1:03d}",
            amount=round(amount, 2),
            description=f"{merchant} - {category}",
            category=category,
            date=transaction_date,
            merchant=merchant
        )
        
        transactions.append(transaction)
    
    return transactions

def create_mock_financial_profile(scenario="balanced", user_id="test_user_123"):
    """Create different financial profile scenarios for testing."""
    
    scenarios = {
        "balanced": {
            "transactions": 50,
            "monthly_income": 5000.0,
            "current_savings": 15000.0
        },
        "high_spender": {
            "transactions": 80,
            "monthly_income": 7000.0,
            "current_savings": 5000.0
        },
        "frugal": {
            "transactions": 25,
            "monthly_income": 7000.0,
            "current_savings": 25000.0
        },
        "struggling": {
            "transactions": 40,
            "monthly_income": 3000.0,
            "current_savings": 1000.0
        }
    }
    
    config = scenarios.get(scenario, scenarios["balanced"])
    
    transactions = create_mock_transactions(
        num_transactions=config["transactions"],
        user_id=user_id
    )
    
    return FinancialProfile(
        user_id=user_id,
        transactions=transactions,
        monthly_income=config["monthly_income"],
        current_savings=config["current_savings"]
    )

def get_test_goals():
    """Return a list of validated financial goals for testing."""
    return [
        "I want to save $5000 for an emergency fund within 6 months",
        "My goal is to pay off $2000 in credit card debt in 4 months",
        "I want to save $10000 for a house down payment in 2 years",
        "I need to reduce my monthly spending by $500",
        "I want to start investing $300 per month for retirement"
    ]
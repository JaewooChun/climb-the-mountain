# Directory Structure:
# backend/
# ├── app/
# │   ├── __init__.py
# │   ├── main.py
# │   ├── config.py
# │   ├── models/
# │   │   ├── __init__.py
# │   │   ├── schemas.py
# │   │   └── database.py
# │   ├── services/
# │   │   ├── __init__.py
# │   │   ├── goal_validator.py
# │   │   ├── task_generator.py
# │   │   └── financial_analyzer.py
# │   ├── routes/
# │   │   ├── __init__.py
# │   │   └── api.py
# │   └── data/
# │       ├── financial_keywords.py
# │       └── mock_transactions.py
# ├── .env
# └── run.py
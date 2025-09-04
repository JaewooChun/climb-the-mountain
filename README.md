# Financial Peak 🏔️

A gamified personal finance application that combines AI-powered financial goal validation with mountain climbing game frontend. Users set financial goals, receive AI validation, and climb a virtual mountain by completing daily financial tasks.

## Architecture

- **AI Backend** (`ai_backend/`): FastAPI server with FinBERT-based goal validation and GPT-powered task generation
- **Flutter Frontend** (`game_frontend/`): Cross-platform mobile/desktop app with mountain climbing game interface

## Quick Start

### Option 1: Automated Launcher (Recommended)

**Python Launcher:**
```bash
python3 start.py
```

**Bash Launcher (macOS/Linux):**
```bash
./start.sh
```

Both launchers will:
- Check dependencies (Python, Flutter)
- Install backend and frontend dependencies
- Start the AI backend server on `http://127.0.0.1:8000`
- Launch the Flutter app
- Monitor both services
- Clean shutdown with `Ctrl+C`

### Option 2: Manual Setup

**Backend Setup:**
```bash
cd ai_backend
pip install -r requirements.txt
python run.py
```

**Frontend Setup (in new terminal):**
```bash
cd game_frontend
flutter pub get
flutter run
```

## Environment Setup

1. **Set your OpenAI API Key:**
   ```bash
   # In root directory or ai_backend/.env
   OPENAI_API_KEY=your_api_key_here
   ```

2. **Required Dependencies:**
   - Python 3.8+ with pip
   - Flutter SDK 3.8.0+
   - OpenAI API key for task generation

## Features

### AI Backend
- **Goal Validation**: FinBERT-powered validation of financial goals
- **Task Generation**: GPT-4 generated personalized daily financial tasks
- **Financial Analysis**: Spending pattern analysis and savings opportunities
- **API Endpoints**:
  - `POST /api/v1/validate-goal` - Validate financial goals
  - `POST /api/v1/generate-tasks` - Generate daily tasks
  - `GET /api/v1/health` - Health check

### Flutter Frontend
- **Interactive Goal Setting**: Real-time AI validation of user goals
- **Mountain Climbing Game**: Gamified progress visualization
- **Daily Tasks**: Complete financial tasks to earn climbing progress
- **Beautiful Animations**: Animated mountain scenes with weather effects

## API Integration

The Flutter app automatically connects to the AI backend for:
1. **Goal Validation**: User enters goal → AI validates financial relevance → Shows suggestions
2. **Task Generation**: Based on validated goals and financial profile
3. **Real-time Feedback**: Confidence scores and improvement suggestions

## Testing

**Run Backend Tests:**
```bash
cd ai_backend/testing
python3 run_all_tests.py
```

**Test Coverage:**
- Goal validation with various financial/non-financial inputs
- Financial analysis with different spending profiles
- Complete task generation workflow
- API integration testing

## Development

**Backend Development:**
- FastAPI with automatic OpenAPI documentation at `/docs`
- Modular service architecture (GoalValidator, TaskGenerator, FinancialAnalyzer)
- Comprehensive error handling and logging

**Frontend Development:**
- Flutter with Material Design
- State management with providers
- HTTP client for API communication
- Custom animations and game mechanics

## Project Structure

```
climb-the-mountain/
├── ai_backend/                 # FastAPI AI backend
│   ├── app/
│   │   ├── models/            # Pydantic schemas
│   │   ├── services/          # AI service classes
│   │   ├── routes/            # API endpoints
│   │   └── data/              # Financial keywords & mock data
│   ├── testing/               # Comprehensive test suite
│   └── run.py                 # Backend entry point
├── game_frontend/             # Flutter frontend
│   ├── lib/
│   │   ├── models/            # Data models
│   │   ├── services/          # API service
│   │   ├── screens/           # UI screens
│   │   └── data/              # Local data services
├── start.py                   # Python launcher
├── start.sh                   # Bash launcher
└── README.md                  # This file
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Run tests: `python3 ai_backend/testing/run_all_tests.py`
4. Submit a pull request

## License

This project is licensed under the MIT License.
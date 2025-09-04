#!/bin/bash

# Financial Peak - Development Launcher (Bash version)
# Alternative launcher script for users who prefer bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_banner() {
    echo "============================================================"
    echo "FINANCIAL PEAK - DEVELOPMENT LAUNCHER"
    echo "============================================================"
    echo "This script will start both the AI backend and Flutter frontend"
    echo "Press Ctrl+C to stop both services"
    echo "============================================================"
}

print_colored() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

check_dependencies() {
    print_colored $BLUE "\nChecking dependencies..."
    
    # Check Python
    if command -v python3 &> /dev/null; then
        PYTHON_VERSION=$(python3 --version)
        print_colored $GREEN "PASS - Python: $PYTHON_VERSION"
    else
        print_colored $RED "FAIL - Python3 not found. Please install Python 3.8+"
        return 1
    fi
    
    # Check Flutter
    if command -v flutter &> /dev/null; then
        FLUTTER_VERSION=$(flutter --version | head -n 1)
        print_colored $GREEN "PASS - Flutter: $FLUTTER_VERSION"
    else
        print_colored $RED "FAIL - Flutter not found. Please install Flutter"
        return 1
    fi
    
    # Check directories
    if [ -d "ai_backend" ]; then
        print_colored $GREEN "PASS - Backend directory: $(pwd)/ai_backend"
    else
        print_colored $RED "FAIL - Backend directory not found: $(pwd)/ai_backend"
        return 1
    fi
    
    if [ -d "game_frontend" ]; then
        print_colored $GREEN "PASS - Frontend directory: $(pwd)/game_frontend"
    else
        print_colored $RED "FAIL - Frontend directory not found: $(pwd)/game_frontend"
        return 1
    fi
    
    return 0
}

install_backend_deps() {
    print_colored $BLUE "\nInstalling backend dependencies..."
    
    if [ -f "ai_backend/requirements.txt" ]; then
        cd ai_backend
        python3 -m pip install -r requirements.txt
        cd ..
        print_colored $GREEN "PASS - Backend dependencies installed"
    else
        print_colored $YELLOW "WARNING - No requirements.txt found in backend"
    fi
}

install_frontend_deps() {
    print_colored $BLUE "\nInstalling frontend dependencies..."
    
    cd game_frontend
    flutter pub get
    cd ..
    print_colored $GREEN "PASS - Frontend dependencies installed"
}

start_backend() {
    print_colored $BLUE "\nStarting AI backend..."
    
    cd ai_backend
    python3 run.py &
    BACKEND_PID=$!
    cd ..
    
    # Wait a moment for backend to start
    sleep 3
    
    # Check if process is still running
    if kill -0 $BACKEND_PID 2>/dev/null; then
        print_colored $GREEN "PASS - AI backend started successfully on http://127.0.0.1:8000"
        echo $BACKEND_PID > .backend_pid
        return 0
    else
        print_colored $RED "FAIL - Backend failed to start"
        return 1
    fi
}

start_frontend() {
    print_colored $BLUE "\nStarting Flutter frontend..."
    print_colored $YELLOW "This may take a moment for first-time setup..."
    
    cd game_frontend
    flutter run --debug &
    FRONTEND_PID=$!
    cd ..
    
    echo $FRONTEND_PID > .frontend_pid
    print_colored $GREEN "PASS - Flutter frontend is starting..."
    print_colored $BLUE "INFO - Choose your preferred device when prompted"
}

cleanup() {
    print_colored $BLUE "\nShutting down services..."
    
    # Kill frontend if running
    if [ -f ".frontend_pid" ]; then
        FRONTEND_PID=$(cat .frontend_pid)
        if kill -0 $FRONTEND_PID 2>/dev/null; then
            print_colored $YELLOW "Stopping Flutter frontend..."
            kill $FRONTEND_PID 2>/dev/null || true
            # Also kill any flutter processes
            pkill -f "flutter run" 2>/dev/null || true
        fi
        rm -f .frontend_pid
    fi
    
    # Kill backend if running
    if [ -f ".backend_pid" ]; then
        BACKEND_PID=$(cat .backend_pid)
        if kill -0 $BACKEND_PID 2>/dev/null; then
            print_colored $YELLOW "Stopping AI backend..."
            kill $BACKEND_PID 2>/dev/null || true
        fi
        rm -f .backend_pid
    fi
    
    print_colored $GREEN "PASS - All services stopped"
}

# Trap Ctrl+C and cleanup
trap cleanup EXIT INT TERM

main() {
    print_banner
    
    # Check dependencies
    if ! check_dependencies; then
        print_colored $RED "\nFAIL - Dependency check failed. Please install missing requirements."
        exit 1
    fi
    
    # Install dependencies
    if ! install_backend_deps; then
        print_colored $RED "\nFAIL - Backend dependency installation failed."
        exit 1
    fi
    
    if ! install_frontend_deps; then
        print_colored $RED "\nFAIL - Frontend dependency installation failed."
        exit 1
    fi
    
    # Start services
    if ! start_backend; then
        print_colored $RED "\nFAIL - Failed to start backend."
        exit 1
    fi
    
    sleep 2  # Give backend time to fully start
    
    if ! start_frontend; then
        print_colored $RED "\nFAIL - Failed to start frontend."
        exit 1
    fi
    
    print_colored $GREEN "\nSUCCESS - Both services are running!"
    print_colored $BLUE "Backend: http://127.0.0.1:8000"
    print_colored $BLUE "Frontend: Flutter app"
    print_colored $YELLOW "\nPress Ctrl+C to stop all services"
    
    # Keep script running
    while true; do
        sleep 1
    done
}

# Run main function
main
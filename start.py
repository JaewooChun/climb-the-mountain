#!/usr/bin/env python3
"""
Financial Peak - Development Launcher
Streamlines running both AI backend and Flutter frontend
"""

import subprocess
import sys
import os
import time
import signal
import threading
from pathlib import Path

class FinancialPeakLauncher:
    def __init__(self):
        self.root_dir = Path(__file__).parent
        self.backend_dir = self.root_dir / "ai_backend"
        self.frontend_dir = self.root_dir / "game_frontend"
        self.backend_process = None
        self.frontend_process = None
        self.running = True
        
    def print_banner(self):
        print("=" * 60)
        print("FINANCIAL PEAK - DEVELOPMENT LAUNCHER")
        print("=" * 60)
        print("This script will start both the AI backend and Flutter frontend")
        print("Press Ctrl+C to stop both services")
        print("=" * 60)
        
    def check_dependencies(self):
        """Check if required dependencies are available"""
        print("\nChecking dependencies...")
        
        # Check Python
        try:
            python_version = subprocess.check_output([sys.executable, "--version"], text=True).strip()
            print(f"PASS - Python: {python_version}")
        except Exception as e:
            print(f"FAIL - Python check failed: {e}")
            return False
            
        # Check Flutter
        try:
            flutter_version = subprocess.check_output(["flutter", "--version"], text=True, stderr=subprocess.STDOUT)
            flutter_line = flutter_version.split('\n')[0]
            print(f"PASS - Flutter: {flutter_line}")
        except Exception as e:
            print(f"FAIL - Flutter not found. Please install Flutter: {e}")
            return False
            
        # Check backend directory
        if not self.backend_dir.exists():
            print(f"FAIL - Backend directory not found: {self.backend_dir}")
            return False
        print(f"PASS - Backend directory: {self.backend_dir}")
        
        # Check frontend directory
        if not self.frontend_dir.exists():
            print(f"FAIL - Frontend directory not found: {self.frontend_dir}")
            return False
        print(f"PASS - Frontend directory: {self.frontend_dir}")
        
        return True
        
    def install_backend_deps(self):
        """Install backend Python dependencies"""
        print("\nInstalling backend dependencies...")
        
        requirements_file = self.backend_dir / "requirements.txt"
        if not requirements_file.exists():
            print("WARNING - No requirements.txt found in backend")
            return True
            
        try:
            subprocess.run([
                sys.executable, "-m", "pip", "install", "-r", str(requirements_file)
            ], check=True, cwd=self.backend_dir)
            print("PASS - Backend dependencies installed")
            return True
        except subprocess.CalledProcessError as e:
            print(f"FAIL - Failed to install backend dependencies: {e}")
            return False
            
    def install_frontend_deps(self):
        """Install Flutter dependencies"""
        print("\nInstalling frontend dependencies...")
        
        try:
            subprocess.run([
                "flutter", "pub", "get"
            ], check=True, cwd=self.frontend_dir)
            print("PASS - Frontend dependencies installed")
            return True
        except subprocess.CalledProcessError as e:
            print(f"FAIL - Failed to install frontend dependencies: {e}")
            return False
            
    def start_backend(self):
        """Start the AI backend server"""
        print("\nStarting AI backend...")
        
        try:
            self.backend_process = subprocess.Popen([
                sys.executable, "run.py"
            ], cwd=self.backend_dir, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
            
            # Wait a moment and check if it started successfully
            time.sleep(2)
            if self.backend_process.poll() is None:
                print("PASS - AI backend started successfully on http://127.0.0.1:8000")
                return True
            else:
                stdout, stderr = self.backend_process.communicate()
                print(f"FAIL - Backend failed to start:")
                print(f"STDOUT: {stdout}")
                print(f"STDERR: {stderr}")
                return False
                
        except Exception as e:
            print(f"FAIL - Failed to start backend: {e}")
            return False
            
    def start_frontend(self):
        """Start the Flutter frontend"""
        print("\nStarting Flutter frontend...")
        print("This may take a moment for first-time setup...")
        
        try:
            # For development, we'll run flutter run in debug mode
            self.frontend_process = subprocess.Popen([
                "flutter", "run", "--debug"
            ], cwd=self.frontend_dir)
            
            print("PASS - Flutter frontend is starting...")
            print("INFO - Choose your preferred device when prompted")
            return True
            
        except Exception as e:
            print(f"FAIL - Failed to start frontend: {e}")
            return False
            
    def monitor_processes(self):
        """Monitor both processes and handle cleanup"""
        def monitor_backend():
            if self.backend_process:
                stdout, stderr = self.backend_process.communicate()
                if self.running and stdout:
                    print(f"\nINFO - Backend output: {stdout}")
                if self.running and stderr:
                    print(f"\nWARNING - Backend error: {stderr}")
                    
        def monitor_frontend():
            if self.frontend_process:
                self.frontend_process.wait()
                if self.running:
                    print("\nINFO - Frontend process ended")
                    
        # Start monitoring threads
        if self.backend_process:
            backend_thread = threading.Thread(target=monitor_backend)
            backend_thread.daemon = True
            backend_thread.start()
            
        if self.frontend_process:
            frontend_thread = threading.Thread(target=monitor_frontend)
            frontend_thread.daemon = True
            frontend_thread.start()
            
    def cleanup(self):
        """Clean up processes"""
        print("\nShutting down services...")
        self.running = False
        
        if self.frontend_process:
            print("Stopping Flutter frontend...")
            self.frontend_process.terminate()
            try:
                self.frontend_process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                self.frontend_process.kill()
                
        if self.backend_process:
            print("Stopping AI backend...")
            self.backend_process.terminate()
            try:
                self.backend_process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                self.backend_process.kill()
                
        print("PASS - All services stopped")
        
    def run(self):
        """Main execution flow"""
        try:
            self.print_banner()
            
            # Check dependencies
            if not self.check_dependencies():
                print("\nFAIL - Dependency check failed. Please install missing requirements.")
                return False
                
            # Install dependencies
            if not self.install_backend_deps():
                print("\nFAIL - Backend dependency installation failed.")
                return False
                
            if not self.install_frontend_deps():
                print("\nFAIL - Frontend dependency installation failed.")
                return False
                
            # Start services
            if not self.start_backend():
                print("\nFAIL - Failed to start backend.")
                return False
                
            time.sleep(3)  # Give backend time to fully start
            
            if not self.start_frontend():
                print("\nFAIL - Failed to start frontend.")
                self.cleanup()
                return False
                
            # Monitor and wait
            self.monitor_processes()
            
            print("\nSUCCESS - Both services are running!")
            print("Backend: http://127.0.0.1:8000")
            print("Frontend: Flutter app")
            print("\nPress Ctrl+C to stop all services")
            
            # Keep the main thread alive
            while self.running:
                time.sleep(1)
                
        except KeyboardInterrupt:
            print("\n\nReceived shutdown signal...")
            self.cleanup()
            return True
        except Exception as e:
            print(f"\nERROR - Unexpected error: {e}")
            self.cleanup()
            return False

def main():
    launcher = FinancialPeakLauncher()
    
    # Handle Ctrl+C gracefully
    def signal_handler(sig, frame):
        launcher.cleanup()
        sys.exit(0)
        
    signal.signal(signal.SIGINT, signal_handler)
    
    success = launcher.run()
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()
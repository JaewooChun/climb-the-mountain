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
import socket
import requests
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
    
    def is_port_available(self, host, port):
        """Check if a port is available for binding"""
        try:
            with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
                sock.settimeout(1)
                result = sock.connect_ex((host, port))
                return result != 0  # Port is available if connection fails
        except Exception:
            return False
    
    def is_backend_running(self, host="127.0.0.1", port=8000):
        """Check if the backend API is already running and responding"""
        try:
            response = requests.get(f"http://{host}:{port}/api/v1/health", timeout=5)
            return response.status_code == 200
        except Exception:
            return False
    
    def find_backend_process(self):
        """Find existing backend processes using the port"""
        try:
            result = subprocess.run(
                ["lsof", "-ti", ":8000"], 
                capture_output=True, 
                text=True, 
                check=False
            )
            if result.returncode == 0 and result.stdout.strip():
                pids = result.stdout.strip().split('\n')
                return [int(pid) for pid in pids if pid]
            return []
        except Exception:
            return []
    
    def cleanup_existing_backend(self):
        """Clean up any existing backend processes on port 8000"""
        pids = self.find_backend_process()
        if pids:
            print(f"INFO - Found existing processes on port 8000: {pids}")
            for pid in pids:
                try:
                    os.kill(pid, signal.SIGTERM)
                    time.sleep(1)
                    # Check if process is still running, force kill if needed
                    try:
                        os.kill(pid, 0)  # This will raise OSError if process doesn't exist
                        print(f"WARNING - Process {pid} still running, force killing...")
                        os.kill(pid, signal.SIGKILL)
                    except OSError:
                        pass  # Process already terminated
                    print(f"INFO - Terminated process {pid}")
                except OSError as e:
                    print(f"WARNING - Could not terminate process {pid}: {e}")
        
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
        
        # Check if backend is already running
        if self.is_backend_running():
            print("INFO - Backend is already running and responding")
            print("PASS - AI backend is available on http://127.0.0.1:8000")
            return True
        
        # Check if port is occupied by non-responding service
        if not self.is_port_available("127.0.0.1", 8000):
            print("WARNING - Port 8000 is occupied by non-responding service")
            print("INFO - Attempting to clean up existing processes...")
            self.cleanup_existing_backend()
            time.sleep(2)  # Give time for cleanup
            
            # Verify port is now available
            if not self.is_port_available("127.0.0.1", 8000):
                print("FAIL - Could not free port 8000")
                return False
        
        try:
            print("INFO - Starting new backend instance...")
            self.backend_process = subprocess.Popen([
                sys.executable, "run.py"
            ], cwd=self.backend_dir, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
            
            # Wait and check if it started successfully
            for _ in range(10):  # Try for 10 seconds
                time.sleep(1)
                if self.backend_process.poll() is not None:
                    # Process has terminated
                    stdout, stderr = self.backend_process.communicate()
                    print(f"FAIL - Backend process terminated:")
                    if stdout:
                        print(f"STDOUT: {stdout}")
                    if stderr:
                        print(f"STDERR: {stderr}")
                    return False
                
                # Check if backend is responding
                if self.is_backend_running():
                    print("PASS - AI backend started successfully on http://127.0.0.1:8000")
                    return True
            
            # If we get here, backend didn't start responding in time
            print("FAIL - Backend started but is not responding to health checks")
            if self.backend_process.poll() is None:
                # Still running, get current output
                print("INFO - Backend process is still running, checking logs...")
                # Give it a bit more time
                time.sleep(3)
                if self.is_backend_running():
                    print("PASS - AI backend is now responding on http://127.0.0.1:8000")
                    return True
            
            return False
                
        except Exception as e:
            print(f"FAIL - Failed to start backend: {e}")
            return False
            
    def start_frontend(self):
        """Start the Flutter frontend"""
        print("\nStarting Flutter frontend...")
        print("This may take a moment for first-time setup...")
        
        try:
            # Check available devices and use Chrome by default for web development
            print("INFO - Checking available Flutter devices...")
            devices_result = subprocess.run([
                "flutter", "devices", "--machine"
            ], cwd=self.frontend_dir, capture_output=True, text=True)
            
            device_arg = []
            if devices_result.returncode == 0:
                import json
                try:
                    devices = json.loads(devices_result.stdout)
                    
                    # Check available platforms
                    macos_device = next((d for d in devices if d.get('id') == 'macos'), None)
                    chrome_device = next((d for d in devices if d.get('id') == 'chrome'), None)
                    
                    # Let user choose platform if both are available
                    if macos_device and chrome_device:
                        print("\nAvailable platforms:")
                        print("1. macOS (Native Desktop App)")
                        print("2. Chrome (Web App)")
                        
                        while True:
                            try:
                                choice = input("\nChoose platform (1 for macOS, 2 for Chrome, or Enter for macOS): ").strip()
                                
                                if choice == "" or choice == "1":
                                    device_arg = ['-d', 'macos']
                                    print("INFO - Using macOS for native desktop development")
                                    break
                                elif choice == "2":
                                    device_arg = ['-d', 'chrome', '--web-port', '8080']
                                    print("INFO - Using Chrome for web development")
                                    break
                                else:
                                    print("Invalid choice. Please enter 1, 2, or press Enter for default.")
                            except (KeyboardInterrupt, EOFError):
                                # Default to macOS if user interrupts
                                device_arg = ['-d', 'macos']
                                print("\nINFO - Defaulting to macOS for native desktop development")
                                break
                    
                    elif macos_device:
                        device_arg = ['-d', 'macos']
                        print("INFO - Using macOS for native desktop development")
                    elif chrome_device:
                        device_arg = ['-d', 'chrome', '--web-port', '8080']
                        print("INFO - Using Chrome for web development")
                    else:
                        # Fall back to first available device
                        if devices:
                            device_arg = ['-d', devices[0]['id']]
                            print(f"INFO - Using device: {devices[0]['name']}")
                except (json.JSONDecodeError, KeyError):
                    print("WARNING - Could not parse device list, using default")
            
            # For development, run flutter with selected device
            # Use release mode to avoid debug service null errors
            cmd = ["flutter", "run", "--release"] + device_arg
            print(f"INFO - Starting Flutter with command: {' '.join(cmd)}")
            
            self.frontend_process = subprocess.Popen(cmd, cwd=self.frontend_dir)
            
            print("PASS - Flutter frontend is starting...")
            if device_arg:
                print("INFO - Flutter will start automatically with selected device")
            else:
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
        del sig, frame  # Acknowledge parameters
        launcher.cleanup()
        sys.exit(0)
        
    signal.signal(signal.SIGINT, signal_handler)
    
    success = launcher.run()
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()
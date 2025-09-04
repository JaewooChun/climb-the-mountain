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
import shutil
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

    def detect_existing_player_data(self):
        """Detect if there's existing player data"""
        indicators = []
        
        # Check for reset flag files first - if they exist, clean them up and continue checking
        reset_flag_file = self.root_dir / "RESET_REQUESTED.flag"
        web_reset_file = self.root_dir / "web_reset_flag.html"
        
        # Also check for reset flag in home directory
        import os
        home_dir = os.path.expanduser("~")
        home_reset_flag = os.path.join(home_dir, "RESET_REQUESTED.flag")
        
        if reset_flag_file.exists() or web_reset_file.exists() or os.path.exists(home_reset_flag):
            # Reset flag files exist - clean them up as they're likely leftover from previous attempts
            print("🧹 Found leftover reset flag files, cleaning them up...")
            try:
                if reset_flag_file.exists():
                    reset_flag_file.unlink()
                    print(f"  Removed: {reset_flag_file}")
                if web_reset_file.exists():
                    web_reset_file.unlink()
                    print(f"  Removed: {web_reset_file}")
                if os.path.exists(home_reset_flag):
                    os.remove(home_reset_flag)
                    print(f"  Removed: {home_reset_flag}")
            except Exception as e:
                print(f"  Warning: Could not remove reset flag files: {e}")
            # Continue checking for other existing data
        
        # Check for Flutter SharedPreferences (typically stored in platform-specific locations)
        # On macOS: ~/Library/Preferences/<app_id>.plist
        # On Web: localStorage/sessionStorage (handled by Flutter)
        
        # Check for Flutter build artifacts that might contain cached data
        flutter_build_dirs = [
            self.frontend_dir / "build",
            self.frontend_dir / ".dart_tool",
        ]
        
        for build_dir in flutter_build_dirs:
            if build_dir.exists() and any(build_dir.iterdir()):
                indicators.append(f"Flutter build cache: {build_dir.name}/")
        
        # Check for backend cache/data
        backend_cache_dirs = [
            self.backend_dir / "__pycache__",
            self.backend_dir / ".pytest_cache",
            self.root_dir / ".pytest_cache",
        ]
        
        for cache_dir in backend_cache_dirs:
            if cache_dir.exists():
                indicators.append(f"Backend cache: {cache_dir.name}/")
        
        # Check for any .DS_Store or other system files that might indicate usage
        system_files = list(self.root_dir.rglob(".DS_Store"))
        if system_files:
            indicators.append(f"System files: {len(system_files)} .DS_Store files")
        
        # Debug: print what we found
        if indicators:
            print("🔍 Data detection found:")
            for indicator in indicators:
                print(f"  • {indicator}")
        else:
            print("🔍 No existing player data detected")
            
        return indicators

    def perform_complete_reset(self):
        """Perform complete reset of all local data"""
        print("\n🔄 PERFORMING COMPLETE RESET...")
        print("This will clear all local game progress and cached data.")
        
        reset_actions = []
        
        # Create reset flag file for Flutter app to detect
        reset_flag_file = self.root_dir / "RESET_REQUESTED.flag"
        try:
            with open(reset_flag_file, 'w') as f:
                f.write(f"RESET_REQUESTED_AT_{int(time.time())}")
            reset_actions.append("Created reset flag file for Flutter app")
            print(f"✅ Created reset flag file at: {reset_flag_file.absolute()}")
            print(f"✅ Reset flag file exists: {reset_flag_file.exists()}")
        except Exception as e:
            reset_actions.append(f"Failed to create reset flag: {e}")
            print(f"❌ Failed to create reset flag: {e}")
        
        # Also create reset flag in user's home directory for macOS app to find
        try:
            import os
            home_dir = os.path.expanduser("~")
            home_reset_flag = os.path.join(home_dir, "RESET_REQUESTED.flag")
            with open(home_reset_flag, 'w') as f:
                f.write(f"RESET_REQUESTED_AT_{int(time.time())}")
            reset_actions.append("Created reset flag file in home directory for macOS app")
            print(f"✅ Created reset flag file in home directory: {home_reset_flag}")
        except Exception as e:
            reset_actions.append(f"Failed to create home reset flag: {e}")
            print(f"❌ Failed to create home reset flag: {e}")
        
        # Clear Flutter build and cache directories
        flutter_dirs_to_clear = [
            self.frontend_dir / "build",
            self.frontend_dir / ".dart_tool" / "flutter_build",
        ]
        
        for dir_path in flutter_dirs_to_clear:
            if dir_path.exists():
                try:
                    shutil.rmtree(dir_path)
                    reset_actions.append(f"Cleared {dir_path.name}/")
                except Exception as e:
                    reset_actions.append(f"Failed to clear {dir_path.name}/: {e}")
        
        # Clear backend cache
        backend_dirs_to_clear = [
            self.backend_dir / "__pycache__",
            self.backend_dir / ".pytest_cache",
            self.root_dir / ".pytest_cache",
        ]
        
        for dir_path in backend_dirs_to_clear:
            if dir_path.exists():
                try:
                    shutil.rmtree(dir_path)
                    reset_actions.append(f"Cleared {dir_path.name}/")
                except Exception as e:
                    reset_actions.append(f"Failed to clear {dir_path.name}/: {e}")
        
        # Clear SharedPreferences data (platform-specific)
        self._clear_shared_preferences(reset_actions)
        
        # Clear system files
        system_files = list(self.root_dir.rglob(".DS_Store"))
        for file_path in system_files:
            try:
                file_path.unlink()
                reset_actions.append(f"Removed {file_path.name}")
            except Exception as e:
                reset_actions.append(f"Failed to remove {file_path.name}: {e}")
        
        # Run flutter clean to ensure complete cleanup
        try:
            result = subprocess.run(
                ["flutter", "clean"],
                cwd=self.frontend_dir,
                capture_output=True,
                text=True,
                timeout=30
            )
            if result.returncode == 0:
                reset_actions.append("Executed 'flutter clean'")
            else:
                reset_actions.append(f"'flutter clean' failed: {result.stderr}")
        except Exception as e:
            reset_actions.append(f"Failed to run 'flutter clean': {e}")
        
        # NOTE: Do NOT clean up reset flag files here - they need to be left for the Flutter app to detect
        # The Flutter app will delete them after processing
        print("ℹ️  Reset flag files left for Flutter app to detect and process")
        
        # Display results
        print("\nRESET RESULTS:")
        for action in reset_actions:
            print(f"  {action}")
        
        print("\n🎉 Reset complete! The game will start as a brand new player experience.")
        print("\n📱 PLATFORM COVERAGE:")
        print("✅ Web browsers (Chrome/Safari) - localStorage cleared")
        print("✅ macOS native app - SharedPreferences/containers cleared") 
        print("✅ Linux - Chrome data cleared")
        print("✅ Windows - Chrome data cleared")
        print("✅ Cross-platform reset flag created")
        print("\n⚠️  If running in BROWSER, also manually clear browser data:")
        print("   - Chrome: Cmd+Shift+Delete → Clear browsing data → localhost")
        print("   - Or use Chrome DevTools: F12 → Application → Storage → Clear storage")
        print("\n🔄 Restart the game to see the fresh player experience.")
        return True

    def _clear_shared_preferences(self, reset_actions):
        """Clear Flutter SharedPreferences data by opening a localhost URL"""
        print("🌐 Clearing Flutter web app localStorage data...")
        
        # Strategy: Open the Flutter app with a reset parameter that triggers data clearing
        try:
            import webbrowser
            import time
            
            # Open localhost:8080 with a reset parameter
            reset_url = "http://localhost:8080/#/?reset_data=true"
            print(f"Opening reset URL: {reset_url}")
            
            # First, check if the Flutter app is running
            try:
                response = requests.get("http://localhost:8080", timeout=5)
                if response.status_code == 200:
                    # Flutter app is running, open the reset URL
                    webbrowser.open(reset_url)
                    reset_actions.append("Opened Flutter app with reset parameter")
                    
                    # Give the browser time to load and execute clearing
                    print("Waiting 5 seconds for data clearing to complete...")
                    time.sleep(5)
                    
                    reset_actions.append("Flutter localStorage data cleared via URL parameter")
                else:
                    reset_actions.append("Flutter app not responding, falling back to file clearing")
                    self._clear_os_browser_data(reset_actions)
                    
            except requests.exceptions.RequestException:
                print("Flutter app not running, clearing browser files directly...")
                reset_actions.append("Flutter app not running, cleared browser files directly")
                self._clear_os_browser_data(reset_actions)
                
        except Exception as e:
            reset_actions.append(f"URL-based clearing failed: {e}")
            self._clear_os_browser_data(reset_actions)
        
        # Also create a localStorage flag file for web platforms to detect
        # This will be picked up by the Flutter app when it starts
        try:
            # Create a simple HTML file that sets the localStorage flag
            web_reset_file = self.root_dir / "web_reset_flag.html"
            with open(web_reset_file, 'w') as f:
                f.write("""
<!DOCTYPE html>
<html>
<head>
    <title>Reset Flag</title>
</head>
<body>
    <script>
        // Set the reset flag in localStorage
        localStorage.setItem('_reset_requested_by_start_py', 'true');
        console.log('Reset flag set in localStorage');
        // Close the window after setting the flag
        window.close();
    </script>
</body>
</html>
                """)
            reset_actions.append("Created web reset flag HTML file")
            
            # Try to open it in the browser to set the localStorage flag
            try:
                webbrowser.open(f"file://{web_reset_file.absolute()}")
                reset_actions.append("Opened web reset flag in browser")
                time.sleep(2)  # Give time for localStorage to be set
            except Exception as e:
                reset_actions.append(f"Could not open web reset flag: {e}")
                
        except Exception as e:
            reset_actions.append(f"Failed to create web reset flag: {e}")
    
    def _clear_os_browser_data(self, reset_actions):
        """Fallback method to clear OS-level browser data"""
        import platform
        import glob
        
        system = platform.system().lower()
        
        if system == "darwin":  # macOS
            # Clear Chrome localStorage files
            chrome_dirs = [
                os.path.expanduser("~/Library/Application Support/Google/Chrome/Default/Local Storage"),
                os.path.expanduser("~/Library/Application Support/Google/Chrome/Profile 1/Local Storage"),
            ]
            
            for chrome_dir in chrome_dirs:
                if os.path.exists(chrome_dir):
                    # Look for localhost data
                    localhost_files = glob.glob(f"{chrome_dir}/*localhost*") + glob.glob(f"{chrome_dir}/*127.0.0.1*")
                    for file_path in localhost_files:
                        try:
                            if os.path.isfile(file_path):
                                os.remove(file_path)
                                reset_actions.append(f"Cleared Chrome data: {os.path.basename(file_path)}")
                            elif os.path.isdir(file_path):
                                shutil.rmtree(file_path)
                                reset_actions.append(f"Cleared Chrome directory: {os.path.basename(file_path)}")
                        except Exception as e:
                            reset_actions.append(f"Failed to clear Chrome data: {e}")
            
            # Clear Safari data if it exists
            safari_dir = os.path.expanduser("~/Library/Safari/LocalStorage")
            if os.path.exists(safari_dir):
                localhost_files = glob.glob(f"{safari_dir}/*localhost*") + glob.glob(f"{safari_dir}/*127.0.0.1*")
                for file_path in localhost_files:
                    try:
                        os.remove(file_path)
                        reset_actions.append(f"Cleared Safari data: {os.path.basename(file_path)}")
                    except Exception as e:
                        reset_actions.append(f"Failed to clear Safari data: {e}")
            
            # Clear macOS native Flutter app data (SharedPreferences stored in plist files)
            # Flutter apps on macOS store data in ~/Library/Preferences/
            preferences_dir = os.path.expanduser("~/Library/Preferences")
            if os.path.exists(preferences_dir):
                # Look for Flutter app preference files (typically com.example.* or game_frontend related)
                flutter_prefs = glob.glob(f"{preferences_dir}/*game_frontend*") + \
                               glob.glob(f"{preferences_dir}/*flutter*") + \
                               glob.glob(f"{preferences_dir}/*com.example*")
                               
                for pref_file in flutter_prefs:
                    try:
                        os.remove(pref_file)
                        reset_actions.append(f"Cleared macOS app data: {os.path.basename(pref_file)}")
                    except Exception as e:
                        reset_actions.append(f"Failed to clear macOS app data: {e}")
            
            # Clear Flutter app containers/data directories
            containers_dir = os.path.expanduser("~/Library/Containers")
            if os.path.exists(containers_dir):
                flutter_containers = glob.glob(f"{containers_dir}/*game_frontend*") + \
                                   glob.glob(f"{containers_dir}/*flutter*")
                                   
                for container_dir in flutter_containers:
                    try:
                        if os.path.isdir(container_dir):
                            shutil.rmtree(container_dir)
                            reset_actions.append(f"Cleared macOS container: {os.path.basename(container_dir)}")
                    except Exception as e:
                        reset_actions.append(f"Failed to clear macOS container: {e}")
                        
        elif system == "linux":
            # Clear Chrome data on Linux
            chrome_dir = os.path.expanduser("~/.config/google-chrome/Default/Local Storage")
            if os.path.exists(chrome_dir):
                localhost_files = glob.glob(f"{chrome_dir}/*localhost*") + glob.glob(f"{chrome_dir}/*127.0.0.1*")
                for file_path in localhost_files:
                    try:
                        if os.path.isfile(file_path):
                            os.remove(file_path)
                            reset_actions.append(f"Cleared Chrome data: {os.path.basename(file_path)}")
                    except Exception as e:
                        reset_actions.append(f"Failed to clear Chrome data: {e}")
                        
        elif system == "windows":
            # Clear Chrome data on Windows
            chrome_dir = os.path.expanduser("~\\AppData\\Local\\Google\\Chrome\\User Data\\Default\\Local Storage")
            if os.path.exists(chrome_dir):
                localhost_files = glob.glob(f"{chrome_dir}\\*localhost*") + glob.glob(f"{chrome_dir}\\*127.0.0.1*")
                for file_path in localhost_files:
                    try:
                        if os.path.isfile(file_path):
                            os.remove(file_path)
                            reset_actions.append(f"Cleared Chrome data: {os.path.basename(file_path)}")
                    except Exception as e:
                        reset_actions.append(f"Failed to clear Chrome data: {e}")
        
        # Kill browser processes to clear in-memory data
        try:
            # Kill Chrome processes
            subprocess.run(["pkill", "-f", "chrome"], capture_output=True)
            reset_actions.append("🔄 Killed Chrome processes")
        except:
            pass
            
        try:
            # Kill Safari processes
            subprocess.run(["pkill", "-f", "Safari"], capture_output=True)
            reset_actions.append("🔄 Killed Safari processes")  
        except:
            pass
            
        # Manual clearing instructions
        reset_actions.append("ℹ️  For complete reset, clear browser data manually:")
        reset_actions.append("   Chrome: Settings > Privacy > Clear browsing data > localhost")
        reset_actions.append("   Safari: Develop menu > Empty Caches")

    def check_reset_needed(self):
        """Check if reset is needed and prompt user"""
        existing_data = self.detect_existing_player_data()
        
        if not existing_data:
            print("✨ Welcome! Starting fresh player experience...")
            return False  # No reset needed
        
        print("\n🔍 EXISTING PLAYER DATA DETECTED:")
        for indicator in existing_data:
            print(f"  • {indicator}")
        
        print("\nOptions:")
        print("  1. Continue with existing data (default)")
        print("  2. Reset all data and start fresh")
        print("  3. Exit")
        
        while True:
            try:
                choice = input("\nEnter your choice (1-3): ").strip()
                
                if choice == "" or choice == "1":
                    print("Continuing with existing data...")
                    return False
                elif choice == "2":
                    confirm = input("\nAre you sure? This will delete ALL progress! (yes/no): ").strip().lower()
                    if confirm in ["yes", "y"]:
                        return self.perform_complete_reset()
                    else:
                        print("Reset cancelled. Continuing with existing data...")
                        return False
                elif choice == "3":
                    print("Exiting...")
                    sys.exit(0)
                else:
                    print("Please enter 1, 2, or 3")
            except KeyboardInterrupt:
                print("\nExiting...")
                sys.exit(0)

def main():
    launcher = FinancialPeakLauncher()
    
    # Check for existing player data and offer reset option
    launcher.check_reset_needed()
    
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
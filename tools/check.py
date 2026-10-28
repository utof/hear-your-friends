#!/usr/bin/env python3
"""Run the game-independent regression tests from any working directory."""
from pathlib import Path
import subprocess
import sys

root = Path(__file__).resolve().parents[1]
subprocess.run([sys.executable, '-m', 'unittest', 'discover', '-s', 'tests', '-p', 'test_*.py'], cwd=root, check=True)
subprocess.run([sys.executable, 'tools/run_lua.py', 'tests/voice_spec.lua'], cwd=root, check=True)
subprocess.run([sys.executable, 'tools/run_lua.py', 'tests/playback_spec.lua'], cwd=root, check=True)
subprocess.run([sys.executable, 'tools/run_lua.py', 'tests/menu_reload_spec.lua'], cwd=root, check=True)

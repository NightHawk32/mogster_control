#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Deployment script for Mogster Control widget.
Copies the widget to the ETHOS simulator or radio SD card.
"""
import argparse
import json
import os
import shutil
import sys
from pathlib import Path

def load_config():
    """Load deployment configuration from deploy.json"""
    config_path = Path(__file__).parent.parent / "deploy.json"
    if config_path.exists():
        with open(config_path, 'r') as f:
            return json.load(f)
    return {}

def get_simulator_path(firmware):
    """Get the simulator root path"""
    workspace = Path(__file__).parent.parent.parent
    # ETHOS uses /persist/RADIO_MODEL as the user directory
    return workspace / "simulator" / firmware / "persist" / firmware.split('_')[0]

def get_radio_path():
    """Get the radio SD card path (needs to be detected or configured)"""
    # This would need to be implemented based on your setup
    # For now, return None to indicate radio deployment is not yet configured
    return None

def deploy_widget(source_dir, target_dir, lang="en"):
    """Deploy the widget directory to the target directory"""
    target_dir = Path(target_dir)
    source = Path(source_dir)
    
    if not source.exists():
        raise FileNotFoundError(f"Source directory not found: {source}")
    
    # Deploy to scripts directory
    # Location 1: /persist/RADIO/scripts/mogster/
    persist_scripts_dir = target_dir / "scripts" / "mogster"
    
    # Location 2: Root scripts directory (for simulator compatibility)
    root_dir = target_dir.parent.parent if "persist" in str(target_dir) else target_dir
    root_scripts_dir = root_dir / "scripts" / "mogster"
    
    print(f"Deploying Mogster Control widget")
    print(f"  Source: {source}")
    
    # Copy to persist location
    print(f"  Target 1: {persist_scripts_dir}")
    if persist_scripts_dir.exists():
        shutil.rmtree(persist_scripts_dir)
    shutil.copytree(source, persist_scripts_dir)
    
    # Copy to root location
    print(f"  Target 2: {root_scripts_dir}")
    if root_scripts_dir.exists():
        shutil.rmtree(root_scripts_dir)
    shutil.copytree(source, root_scripts_dir)
    
    print(f"[OK] Deployed successfully to both locations")
    
    return True

def main():
    parser = argparse.ArgumentParser(description="Deploy Mogster Control widget")
    parser.add_argument("--radio", action="store_true", help="Deploy to radio SD card")
    parser.add_argument("--radio-debug", action="store_true", help="Enable radio serial debug")
    parser.add_argument("--connect-only", action="store_true", help="Only connect for debugging")
    parser.add_argument("--lang", default="en", help="Deployment language")
    parser.add_argument("--clear-lock", action="store_true", help="Clear deployment locks")
    
    args = parser.parse_args()
    
    # Load configuration
    config = load_config()
    
    # Get workspace root
    workspace = Path(__file__).parent.parent.parent
    widget_dir = workspace / "src" / "mogster"
    
    if not widget_dir.exists():
        print(f"Error: Widget directory not found: {widget_dir}")
        return 1
    
    # Handle clear lock
    if args.clear_lock:
        print("Clearing deployment locks...")
        # Implement lock clearing if needed
        return 0
    
    # Handle connect-only mode
    if args.connect_only:
        print("Connect-only mode - serial debug connection")
        # Implement serial connection if needed
        return 0
    
    # Deploy to simulator or radio
    if args.radio:
        print("Deploying to radio...")
        radio_path = get_radio_path()
        if radio_path is None:
            print("Error: Radio SD card path not configured")
            print("Please configure the radio SD card path in deploy.py")
            return 1
        target_dir = radio_path
    else:
        print("Deploying to simulator...")
        # Get firmware from environment or use default
        firmware = os.environ.get("ETHOS_FIRMWARE", "X20S_FCC")
        target_dir = get_simulator_path(firmware)
    
    # Deploy the widget
    try:
        deploy_widget(widget_dir, target_dir, args.lang)
        print(f"\n[OK] Deployment complete!")
        print(f"  Target: {target_dir}")
        print(f"  Language: {args.lang}")
        return 0
    except Exception as e:
        print(f"Error during deployment: {e}")
        import traceback
        traceback.print_exc()
        return 1

if __name__ == "__main__":
    sys.exit(main())

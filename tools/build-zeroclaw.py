#!/usr/bin/env python3
import os
import sys
import json
import shutil
import urllib.request
import zipfile
import stat

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DIST = os.path.join(ROOT, "dist")
WORK = os.path.join(ROOT, ".build", "zeroclaw-zip")
MODULE_SRC = os.path.join(ROOT, "modules", "zeroclaw-agent")
OUT_ZIP = os.path.join(DIST, "zeroclaw-agent-twrp.zip")

GITHUB_REPO = "zeroclaw-labs/zeroclaw"

def get_latest_release_url():
    url = f"https://api.github.com/repos/{GITHUB_REPO}/releases/latest"
    print(f"Querying GitHub API for latest release: {url}")
    try:
        req = urllib.request.Request(
            url, 
            headers={"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"}
        )
        with urllib.request.urlopen(req, timeout=10) as response:
            data = json.loads(response.read().decode())
            tag_name = data.get("tag_name", "latest")
            print(f"Found latest tag: {tag_name}")
            
            assets = data.get("assets", [])
            for asset in assets:
                name = asset.get("name", "")
                # Prioritize android aarch64, fallback to linux aarch64
                if "aarch64" in name and ("android" in name or "linux" in name):
                    print(f"Found target asset: {name}")
                    return asset.get("browser_download_url"), name
            
            # If no perfect match, print available assets
            print("Available assets:")
            for asset in assets:
                print(f" - {asset.get('name')}")
    except Exception as e:
        print(f"Error querying GitHub API: {e}")
    return None, None

def download_binary(download_url, dest_path):
    print(f"Downloading binary from {download_url}...")
    try:
        req = urllib.request.Request(
            download_url, 
            headers={"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"}
        )
        with urllib.request.urlopen(req, timeout=30) as response, open(dest_path, "wb") as out_file:
            shutil.copyfileobj(response, out_file)
        print("Download successful!")
        return True
    except Exception as e:
        print(f"Error downloading binary: {e}")
        return False

def zip_dir(dir_path, zip_path):
    if os.path.exists(zip_path):
        os.remove(zip_path)
        
    with zipfile.ZipFile(zip_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
        for root, dirs, files in os.walk(dir_path):
            for file in files:
                full_path = os.path.join(root, file)
                rel_path = os.path.relpath(full_path, dir_path).replace('\\', '/')
                
                # Store permissions in the external_attr field
                st = os.stat(full_path)
                zinfo = zipfile.ZipInfo(rel_path)
                zinfo.external_attr = (st.st_mode & 0xFFFF) << 16
                
                with open(full_path, 'rb') as f:
                    zipf.writestr(zinfo, f.read())

def main():
    print("=== ZeroClaw Magisk Module Builder ===")
    
    # 1. Ensure target dirs exist
    os.makedirs(DIST, exist_ok=True)
    if os.path.exists(WORK):
        shutil.rmtree(WORK)
    os.makedirs(WORK)
    
    bin_dir = os.path.join(MODULE_SRC, "system", "bin")
    os.makedirs(bin_dir, exist_ok=True)
    target_bin = os.path.join(bin_dir, "zeroclaw")
    
    # 2. Acquire Binary
    has_bin = False
    if os.path.exists(target_bin):
        print(f"Using pre-existing local binary at {target_bin}")
        has_bin = True
    else:
        download_url, asset_name = get_latest_release_url()
        if download_url:
            has_bin = download_binary(download_url, target_bin)
        
    if not has_bin:
        print("\n[WARNING] Could not fetch binary automatically.")
        print(f"Please manually download the 'aarch64-linux-android' binary of ZeroClaw,")
        print(f"place it at '{target_bin}', and run this script again.\n")
        sys.exit(1)
        
    # 3. Stage the files for building
    print("Staging files...")
    pkg = os.path.join(WORK, "package")
    os.makedirs(pkg)
    
    # Copy template assets
    shutil.copytree(MODULE_SRC, os.path.join(pkg, "module"))
    # Copy again at root level for in-OS Magisk manager compat
    for item in os.listdir(MODULE_SRC):
        s = os.path.join(MODULE_SRC, item)
        d = os.path.join(pkg, item)
        if os.path.isdir(s):
            shutil.copytree(s, d)
        else:
            shutil.copy2(s, d)
            
    # 4. Inject TWRP installer binaries
    print("Injecting installer scripts...")
    installer_dir = os.path.join(pkg, "META-INF", "com", "google", "android")
    os.makedirs(installer_dir, exist_ok=True)
    
    src_update_bin = os.path.join(ROOT, "installer", "update-binary")
    dest_update_bin = os.path.join(installer_dir, "update-binary")
    shutil.copy2(src_update_bin, dest_update_bin)
    
    # Create updater-script header
    with open(os.path.join(installer_dir, "updater-script"), "w") as f:
        f.write("#MAGISK\n")
        
    # 5. Set proper executable permissions
    print("Setting permissions...")
    os.chmod(dest_update_bin, 0o755)
    
    for service_path in [os.path.join(pkg, "service.sh"), os.path.join(pkg, "module", "service.sh")]:
        if os.path.exists(service_path):
            os.chmod(service_path, 0o755)
            
    for bin_path in [os.path.join(pkg, "system", "bin", "zeroclaw"), os.path.join(pkg, "module", "system", "bin", "zeroclaw")]:
        if os.path.exists(bin_path):
            os.chmod(bin_path, 0o755)
            
    # 6. Package Zip
    print(f"Creating Magisk flashable zip: {OUT_ZIP}...")
    zip_dir(pkg, OUT_ZIP)
    
    # Clean up workspace
    shutil.rmtree(WORK)
    print("\n✓ Reusable ZeroClaw Magisk Module built successfully!")
    print(f"Path: {OUT_ZIP}\n")

if __name__ == "__main__":
    main()

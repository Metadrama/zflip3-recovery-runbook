#!/usr/bin/env python3
import json
import urllib.request
import tarfile
import os
import sys
import subprocess

PRISTINE_PATH = "/data/ssh/root/.local/bin/agy"
PATCHED_PATH = "/data/data/com.termux/files/home/.local/bin/agy.va39"
MANIFEST_URL = "https://antigravity-cli-auto-updater-974169037036.us-central1.run.app/manifests/linux_arm64.json"

def get_current_version():
    try:
        # Run patched binary via proot with a flag to get version
        cmd = [
            "/data/data/com.termux/files/usr/bin/proot",
            "-b", "/data/data/com.termux/files/home/.local/etc/resolv.conf:/etc/resolv.conf",
            "/data/data/com.termux/files/usr/glibc/lib/ld-linux-aarch64.so.1",
            "--library-path", "/data/data/com.termux/files/home/.local/lib/agy-glibc:/data/data/com.termux/files/usr/glibc/lib",
            PATCHED_PATH,
            "--version"
        ]
        result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, timeout=5)
        for line in result.stdout.split('\n'):
            if line.strip():
                return line.strip()
    except Exception:
        pass
    return "unknown"

def main():
    print("⟳ Checking for updates...")
    current = get_current_version()
    
    try:
        req = urllib.request.Request(MANIFEST_URL, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req) as response:
            manifest = json.loads(response.read().decode())
    except Exception as e:
        print(f"Error: failed to fetch update manifest: {e}")
        sys.exit(1)
        
    latest = manifest.get("version")
    url = manifest.get("url")
    
    print(f"Current version: {current}")
    print(f"Latest version : {latest}")
    
    if current == latest and current != "unknown":
        print("✓ Already up to date!")
        return
        
    print(f"⟳ Downloading update...")
    temp_tar = "/tmp/agy_update.tar.gz"
    try:
        urllib.request.urlretrieve(url, temp_tar)
    except Exception as e:
        print(f"Error: failed to download update: {e}")
        sys.exit(1)
        
    print("⟳ Extracting files...")
    try:
        with tarfile.open(temp_tar, "r:gz") as tar:
            # Find the binary in the tarball (usually named 'agy' or 'antigravity')
            binary_member = None
            for member in tar.getmembers():
                if member.name.endswith("agy") or member.name.endswith("antigravity"):
                    binary_member = member
                    break
            if not binary_member:
                # Fallback to the first regular file
                for member in tar.getmembers():
                    if member.isfile():
                        binary_member = member
                        break
            if not binary_member:
                raise Exception("No binary file found in the archive")
                
            # Extract it directly to the pristine path
            os.makedirs(os.path.dirname(PRISTINE_PATH), exist_ok=True)
            with tar.extractfile(binary_member) as source, open(PRISTINE_PATH, "wb") as target:
                target.write(source.read())
                
        os.chmod(PRISTINE_PATH, 0o755)
        print("✓ Update successful!")
        print("🔄 The VA39 auto-patcher will automatically patch the new binary on the next run.")
    except Exception as e:
        print(f"Error: failed to extract and install update: {e}")
        if os.path.exists(temp_tar):
            os.remove(temp_tar)
        sys.exit(1)
        
    if os.path.exists(temp_tar):
        os.remove(temp_tar)

if __name__ == "__main__":
    main()

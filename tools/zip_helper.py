import os
import sys
import zipfile

def zip_dir(dir_path, zip_path):
    # Ensure any previous zip file is removed
    if os.path.exists(zip_path):
        os.remove(zip_path)
        
    with zipfile.ZipFile(zip_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
        for root, dirs, files in os.walk(dir_path):
            for file in files:
                full_path = os.path.join(root, file)
                # Use forward slashes for zip entries to be compatible with Android/Linux
                rel_path = os.path.relpath(full_path, dir_path).replace('\\', '/')
                
                # Get file permissions
                st = os.stat(full_path)
                zinfo = zipfile.ZipInfo(rel_path)
                # Store permissions in the external_attr field
                zinfo.external_attr = (st.st_mode & 0xFFFF) << 16
                
                with open(full_path, 'rb') as f:
                    zipf.writestr(zinfo, f.read())

if __name__ == '__main__':
    if len(sys.argv) < 3:
        print("Usage: python zip_helper.py <dir_path> <zip_path>")
        sys.exit(1)
    zip_dir(sys.argv[1], sys.argv[2])
    print(f"Successfully zipped {sys.argv[1]} to {sys.argv[2]}")

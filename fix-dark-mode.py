#!/usr/bin/env python3
"""
Batch add dark mode classes to React/Next.js components
"""

import os
import re
import glob

# Mapping of common patterns to their dark mode equivalents
REPLACEMENTS = [
    # Headers and titles
    (r'className="text-3xl font-bold text-gray-900"', 
     r'className="text-3xl font-bold text-gray-900 dark:text-white"'),
    (r'className="text-2xl font-bold text-gray-900"', 
     r'className="text-2xl font-bold text-gray-900 dark:text-white"'),
    (r'className="text-xl font-bold text-gray-900"', 
     r'className="text-xl font-bold text-gray-900 dark:text-white"'),
    (r'className="text-lg font-semibold text-gray-900"', 
     r'className="text-lg font-semibold text-gray-900 dark:text-white"'),
    (r'className="font-semibold text-gray-900"', 
     r'className="font-semibold text-gray-900 dark:text-white"'),
    
    # Icons and arrows
    (r'<ArrowLeft className="w-6 h-6 text-gray-900" />', 
     r'<ArrowLeft className="w-6 h-6 text-gray-900 dark:text-white" />'),
    (r'<ArrowLeft className="w-5 h-5 text-gray-900" />', 
     r'<ArrowLeft className="w-5 h-5 text-gray-900 dark:text-white" />'),
    
    # Text elements
    (r'className="text-gray-600"([^>]*?)>', 
     r'className="text-gray-600 dark:text-gray-400"\1>'),
    (r'className="text-sm text-gray-500"', 
     r'className="text-sm text-gray-500 dark:text-gray-400"'),
    
    # Buttons
    (r'className="p-2 hover:bg-gray-100 rounded-lg transition"', 
     r'className="p-2 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg transition"'),
    
    # Cards and containers
    (r'className="bg-white rounded-xl border border-gray-200 p-6 shadow-sm"', 
     r'className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-6 shadow-sm"'),
    (r'className="bg-white rounded-xl border border-gray-200 p-4"', 
     r'className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-4"'),
]

def fix_dark_mode(filepath):
    """Add dark mode classes to a file"""
    print(f"Processing: {filepath}")
    
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original = content
        changes = 0
        
        for pattern, replacement in REPLACEMENTS:
            new_content = re.sub(pattern, replacement, content)
            if new_content != content:
                changes += re.subn(pattern, replacement, content)[1]
                content = new_content
        
        if content != original:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"  ✓ Made {changes} changes")
            return True
        else:
            print(f"  - No changes needed")
            return False
    
    except Exception as e:
        print(f"  ✗ Error: {e}")
        return False

def main():
    web_dir = "/Users/zia/Desktop/SiteLedger/web/app"
    
    # Find all TSX files
    tsx_files = []
    for root, dirs, files in os.walk(web_dir):
        for file in files:
            if file.endswith('.tsx'):
                tsx_files.append(os.path.join(root, file))
    
    print(f"Found {len(tsx_files)} TSX files\n")
    
    fixed_count = 0
    for filepath in tsx_files:
        if fix_dark_mode(filepath):
            fixed_count += 1
    
    print(f"\n✅ Fixed {fixed_count}/{len(tsx_files)} files")

if __name__ == '__main__':
    main()

"""Check content_edits.sql for JSON issues."""
import json
import re
import sys
from pathlib import Path

# Set UTF-8 encoding for output
sys.stdout.reconfigure(encoding='utf-8') if hasattr(sys.stdout, 'reconfigure') else None

file_path = Path("scripts/backup_plain_tables/table_content_edits.sql")
content = file_path.read_text(encoding="utf-8")

# Find all INSERT statements
inserts = re.findall(r'INSERT INTO[^;]+;', content, re.DOTALL)

for i, ins in enumerate(inserts, 1):
    # Extract all quoted strings
    json_strings = []
    pattern = r"'((?:[^'\\]|\\.|'')*?)'"
    for match in re.finditer(pattern, ins, re.DOTALL):
        inner = match.group(1).replace("''", "'")
        if inner.strip().startswith(("{", "[")):
            json_strings.append((match.start(), inner))
    
    for j, (pos, js) in enumerate(json_strings, 1):
        try:
            json.loads(js)
        except json.JSONDecodeError as e:
            error_msg = str(e)
            print(f"INSERT {i}, JSON {j}:")
            print(f"  Error: {error_msg[:150]}")
            print(f"  Length: {len(js)}")
            
            # Find error position
            error_pos = None
            if "char " in error_msg:
                try:
                    error_pos = int(error_msg.split("char ")[1].split(")")[0])
                except:
                    pass
            
            if error_pos:
                start = max(0, error_pos - 100)
                end = min(len(js), error_pos + 100)
                print(f"  Around error (pos {error_pos}):")
                print(f"    {js[start:end]}")
            
            # Try to find the issue
            if '"' in js[error_pos-10:error_pos+10] if error_pos else False:
                print(f"  Issue: Unescaped quote or unterminated string")
            
            print()

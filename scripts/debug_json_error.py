"""Debug JSON errors in content_edits.sql."""
import json
import re
from pathlib import Path

file_path = Path("scripts/backup_plain_tables/table_content_edits.sql")
content = file_path.read_text(encoding="utf-8")

# Find all INSERT statements
inserts = re.findall(r'INSERT INTO[^;]+;', content, re.DOTALL)

# Check INSERT 2, JSON 4 (originalContentSnapshot)
ins2 = inserts[1]
pattern = r"'originalContentSnapshot',\s*'([^']*(?:''[^']*)*)'"
match = re.search(pattern, ins2, re.DOTALL)

if match:
    json_str = match.group(1).replace("''", "'")
    print(f"INSERT 2, originalContentSnapshot:")
    print(f"  Length: {len(json_str)}")
    print(f"  Error at position 518")
    print(f"  Context around 518:")
    print(f"    {json_str[500:550]}")
    print(f"\n  Checking for unescaped quotes:")
    
    # Check for unescaped quotes
    for i in range(500, min(550, len(json_str))):
        if json_str[i] == '"':
            # Check if escaped
            if i == 0 or json_str[i-1] != '\\':
                print(f"    Position {i}: Unescaped quote!")
                print(f"      Context: {json_str[max(0,i-20):min(len(json_str),i+20)]}")
    
    # Try to fix by finding the issue
    try:
        parsed = json.loads(json_str)
        print("  -> Valid JSON")
    except json.JSONDecodeError as e:
        print(f"  -> Error: {e}")
        # Try to find where the string should end
        error_pos = 518
        # Look for the next quote after error_pos
        next_quote = json_str.find('"', error_pos + 1)
        if next_quote > 0:
            print(f"  -> Next quote at position {next_quote}")
            print(f"  -> Content between: {json_str[error_pos:next_quote+1]}")

"""Test parsing specific JSON strings from content_edits.sql."""
import json
import re
from pathlib import Path

file_path = Path("scripts/backup_plain_tables/table_content_edits.sql")
content = file_path.read_text(encoding="utf-8")
content = re.sub(r'\\\s*\n\s*', '', content)

inserts = re.findall(r'INSERT INTO[^;]+;', content, re.DOTALL)

# Check INSERT 2 (index 1)
ins = inserts[1]

# Extract originalContentSnapshot value
pattern = r"'originalContentSnapshot',\s*'([^']*(?:''[^']*)*)'"
match = re.search(pattern, ins, re.DOTALL)

if match:
    json_str = match.group(1).replace("''", "'")
    print(f"JSON string length: {len(json_str)}")
    print(f"Position 510-530: {json_str[510:530]}")
    print(f"Position 515-520: {repr(json_str[515:520])}")
    
    # Check character at position 518
    if len(json_str) > 518:
        char_518 = json_str[518]
        print(f"Character at 518: {repr(char_518)}")
        print(f"Context: {repr(json_str[510:530])}")
    
    # Try to parse
    try:
        parsed = json.loads(json_str)
        print("Valid JSON!")
    except json.JSONDecodeError as e:
        print(f"Error: {e}")
        # Try to find where the issue is
        error_pos = int(str(e).split("char ")[1].split(")")[0]) if "char " in str(e) else None
        if error_pos:
            print(f"Error at position: {error_pos}")
            print(f"Context around error: {repr(json_str[max(0,error_pos-20):min(len(json_str),error_pos+20)])}")

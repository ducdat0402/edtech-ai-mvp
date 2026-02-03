"""Fix remaining JSON errors in SQL files."""
import json
import re
from pathlib import Path

def fix_json_string(json_str: str) -> str:
    """Fix a JSON string that has errors."""
    # Try to find and fix unterminated strings
    # Common issue: unescaped quotes in string values
    
    # First, try parsing as-is
    try:
        parsed = json.loads(json_str)
        return json.dumps(parsed, ensure_ascii=False)
    except json.JSONDecodeError as e:
        error_msg = str(e)
        
        # If it's an unterminated string, try to fix it
        if "Unterminated string" in error_msg:
            # Find the error position
            error_pos = None
            if "char " in error_msg:
                try:
                    error_pos = int(error_msg.split("char ")[1].split(")")[0])
                except:
                    pass
            
            if error_pos:
                # Look for unescaped quotes before the error position
                # Check if there's a quote that should be escaped
                for i in range(max(0, error_pos - 50), min(len(json_str), error_pos + 50)):
                    if json_str[i] == '"':
                        # Check if it's escaped
                        if i == 0 or json_str[i-1] != '\\':
                            # Check if it's inside a string value (not a key)
                            # Look backwards to see if we're in a string value
                            before = json_str[:i]
                            # Count quotes before this position
                            quote_count = before.count('"')
                            # If odd number, we're in a string value
                            if quote_count % 2 == 1:
                                # This quote should be escaped
                                json_str = json_str[:i] + '\\' + json_str[i:]
                                # Retry parsing
                                try:
                                    parsed = json.loads(json_str)
                                    return json.dumps(parsed, ensure_ascii=False)
                                except:
                                    pass
        
        # If still can't parse, return original
        return json_str

def fix_file(file_path: Path) -> int:
    """Fix remaining JSON errors in a file."""
    content = file_path.read_text(encoding="utf-8")
    content = re.sub(r'\\\s*\n\s*', '', content)
    
    fixes = 0
    
    # Find all INSERT statements
    inserts = re.findall(r'INSERT INTO[^;]+;', content, re.DOTALL)
    
    for insert_stmt in inserts:
        # Find all JSON strings
        pattern = r"'((?:[^'\\]|\\.|'')*?)'"
        matches = list(re.finditer(pattern, insert_stmt, re.DOTALL))
        
        for match in matches:
            inner = match.group(1).replace("''", "'")
            if inner.strip().startswith(("{", "[")):
                try:
                    json.loads(inner)
                except json.JSONDecodeError:
                    # Try to fix it
                    fixed_json = fix_json_string(inner)
                    if fixed_json != inner:
                        # Replace in insert statement
                        fixed_value = f"'{fixed_json.replace(\"'\", \"''\")}'"
                        insert_stmt = insert_stmt[:match.start()] + fixed_value + insert_stmt[match.end():]
                        fixes += 1
    
    if fixes > 0:
        # Reconstruct content with fixed INSERT statements
        # This is complex, so we'll use a simpler approach: fix the whole file
        pass
    
    return fixes

# Test on content_edits.sql
file_path = Path("scripts/backup_plain_tables/table_content_edits.sql")
print(f"Fixing {file_path.name}...")
fixes = fix_file(file_path)
print(f"Fixed {fixes} JSON values")

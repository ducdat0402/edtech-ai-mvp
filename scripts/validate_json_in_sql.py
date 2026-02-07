import json
import re
from pathlib import Path


def validate_file(file_path: Path) -> tuple[int, list[str]]:
    """Validate all JSON strings in a SQL file."""
    content = file_path.read_text(encoding="utf-8")
    content = re.sub(r'\\\s*\n\s*', '', content)  # Remove line continuations
    
    errors = []
    json_count = 0
    
    # Find all INSERT statements (may span multiple lines)
    inserts = re.findall(r'INSERT INTO[^;]+;', content, re.DOTALL)
    
    for insert_stmt in inserts:
        # Find all quoted strings that look like JSON
        pattern = r"'((?:[^'\\]|\\.|'')*?)'"
        for match in re.finditer(pattern, insert_stmt, re.DOTALL):
            inner = match.group(1).replace("''", "'")
            if inner.strip().startswith(("{", "[")):
                json_count += 1
                try:
                    json.loads(inner)
                except json.JSONDecodeError as e:
                    # Find line number in original content
                    line_num = content[:content.find(insert_stmt)].count('\n') + 1
                    errors.append(f"Line {line_num}: {str(e)[:100]}")
    
    return json_count, errors


def main():
    input_dir = Path("scripts/backup_plain_tables")
    sql_files = sorted(input_dir.glob("table_*.sql"))
    
    total_json = 0
    total_errors = 0
    
    for sql_file in sql_files:
        if sql_file.name == "table_schema.sql":
            continue
        
        count, errors = validate_file(sql_file)
        total_json += count
        if errors:
            total_errors += len(errors)
            print(f"{sql_file.name}: {len(errors)} errors in {count} JSON values")
            for err in errors[:3]:  # Show first 3 errors
                print(f"  {err}")
    
    print(f"\nTotal: {total_json} JSON values, {total_errors} errors")


if __name__ == "__main__":
    main()

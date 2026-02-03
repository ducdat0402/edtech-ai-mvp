"""Complete fix for JSON in SQL files - handles multiline INSERT statements."""
import argparse
import json
import re
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Fix JSON in SQL files, handling multiline INSERT statements.",
    )
    parser.add_argument(
        "input_dir",
        type=Path,
        help="Directory containing SQL files to fix.",
    )
    parser.add_argument(
        "--backup",
        action="store_true",
        help="Create backup files before fixing.",
    )
    return parser.parse_args()


def fix_json_value(value: str) -> str:
    """Fix a single JSON value."""
    if value.strip() == "NULL":
        return value
    
    if not (value.startswith("'") and value.endswith("'")):
        return value
    
    inner = value[1:-1].replace("''", "'")
    
    if not inner.strip().startswith(("{", "[")):
        return value
    
    # Check if it has actual newlines
    has_newline = "\n" in inner or "\r" in inner
    
    if has_newline:
        try:
            # Replace actual newlines with escape sequences
            inner_fixed = inner.replace("\n", "\\n")
            inner_fixed = inner_fixed.replace("\r", "\\r")
            inner_fixed = inner_fixed.replace("\t", "\\t")
            
            parsed = json.loads(inner_fixed)
            fixed = json.dumps(parsed, ensure_ascii=False)
            fixed = fixed.replace("'", "''")
            return f"'{fixed}'"
        except json.JSONDecodeError:
            try:
                # Try more fixes
                inner_fixed = inner.replace("\\\\n", "\n")
                inner_fixed = inner_fixed.replace("\\\\t", "\t")
                inner_fixed = inner_fixed.replace("\\\\r", "\r")
                inner_fixed = inner_fixed.replace("\n", "\\n")
                inner_fixed = inner_fixed.replace("\r", "\\r")
                inner_fixed = inner_fixed.replace("\t", "\\t")
                inner_fixed = re.sub(r'\\{3,}"', lambda m: '\\' * (len(m.group(0)) - 1) + '"', inner_fixed)
                
                parsed = json.loads(inner_fixed)
                fixed = json.dumps(parsed, ensure_ascii=False)
                fixed = fixed.replace("'", "''")
                return f"'{fixed}'"
            except:
                return value
    else:
        try:
            parsed = json.loads(inner)
            fixed = json.dumps(parsed, ensure_ascii=False)
            fixed = fixed.replace("'", "''")
            return f"'{fixed}'"
        except json.JSONDecodeError:
            return value


def extract_values_carefully(values_str: str) -> list[str]:
    """Extract values from VALUES clause, handling quotes and nested structures."""
    values = []
    current = []
    depth = 0
    in_string = False
    quote_char = None
    
    i = 0
    while i < len(values_str):
        char = values_str[i]
        
        if not in_string:
            if char in ("'", '"'):
                in_string = True
                quote_char = char
                current.append(char)
            elif char == '(':
                depth += 1
                current.append(char)
            elif char == ')':
                depth -= 1
                current.append(char)
            elif char == ',' and depth == 0:
                val = ''.join(current).strip()
                if val:
                    values.append(val)
                current = []
            else:
                current.append(char)
        else:
            current.append(char)
            if char == quote_char:
                # Check if escaped: look for '' pattern (SQL escape)
                if quote_char == "'" and i + 1 < len(values_str) and values_str[i + 1] == "'":
                    # SQL escape: ''
                    current.append("'")
                    i += 1  # Skip next quote
                else:
                    # Check if backslash-escaped
                    backslash_count = 0
                    j = len(current) - 2
                    while j >= 0 and current[j] == '\\':
                        backslash_count += 1
                        j -= 1
                    
                    # Even number means quote is not escaped
                    if backslash_count % 2 == 0:
                        in_string = False
                        quote_char = None
        
        i += 1
    
    if current:
        val = ''.join(current).strip()
        if val:
            values.append(val)
    
    return values


def fix_file(file_path: Path, backup: bool) -> tuple[int, int]:
    """Fix JSON in a SQL file, joining multiline INSERT statements."""
    if backup:
        backup_path = file_path.with_suffix(file_path.suffix + ".bak")
        backup_path.write_text(file_path.read_text(encoding="utf-8"), encoding="utf-8")
    
    content = file_path.read_text(encoding="utf-8")
    
    # Remove SQL line continuations
    content = re.sub(r'\\\s*\n\s*', '', content)
    
    # Join multiline INSERT statements
    lines = content.splitlines(keepends=True)
    joined_lines = []
    i = 0
    
    while i < len(lines):
        line = lines[i]
        
        if line.strip().upper().startswith("INSERT INTO"):
            # Collect the entire INSERT statement
            insert_text = line.rstrip('\n\r')
            j = i + 1
            
            while j < len(lines):
                next_line = lines[j]
                insert_text += next_line.rstrip('\n\r')
                
                # Check if INSERT statement is complete (ends with ;)
                if ';' in insert_text:
                    break
                j += 1
            
            joined_lines.append(insert_text + '\n')
            i = j + 1
        else:
            joined_lines.append(line)
            i += 1
    
    content = ''.join(joined_lines)
    
    # Now fix JSON in the joined content
    fixes = [0]
    insert_count = 0
    
    def fix_json_match(match):
        """Fix a quoted string that contains JSON."""
        full = match.group(0)
        inner = match.group(1)
        
        inner = inner.replace("''", "'")
        
        if not inner.strip().startswith(("{", "[")):
            return full
        
        has_newline = "\n" in inner or "\r" in inner
        
        if has_newline:
            try:
                inner_fixed = inner.replace("\n", "\\n")
                inner_fixed = inner_fixed.replace("\r", "\\r")
                inner_fixed = inner_fixed.replace("\t", "\\t")
                
                parsed = json.loads(inner_fixed)
                fixed = json.dumps(parsed, ensure_ascii=False)
                fixed = fixed.replace("'", "''")
                fixes[0] += 1
                return f"'{fixed}'"
            except json.JSONDecodeError:
                try:
                    inner_fixed = inner.replace("\\\\n", "\n")
                    inner_fixed = inner_fixed.replace("\\\\t", "\t")
                    inner_fixed = inner_fixed.replace("\\\\r", "\r")
                    inner_fixed = inner_fixed.replace("\n", "\\n")
                    inner_fixed = inner_fixed.replace("\r", "\\r")
                    inner_fixed = inner_fixed.replace("\t", "\\t")
                    inner_fixed = re.sub(r'\\{3,}"', lambda m: '\\' * (len(m.group(0)) - 1) + '"', inner_fixed)
                    
                    parsed = json.loads(inner_fixed)
                    fixed = json.dumps(parsed, ensure_ascii=False)
                    fixed = fixed.replace("'", "''")
                    fixes[0] += 1
                    return f"'{fixed}'"
                except:
                    return full
        else:
            try:
                parsed = json.loads(inner)
                fixed = json.dumps(parsed, ensure_ascii=False)
                fixed = fixed.replace("'", "''")
                fixes[0] += 1
                return f"'{fixed}'"
            except json.JSONDecodeError:
                return full
    
    # Count INSERT statements
    insert_count = len([l for l in content.splitlines() if l.strip().upper().startswith("INSERT")])
    
    # Fix JSON strings
    pattern = r"'((?:[^'\\]|\\.|'')*?)'"
    fixed_content = re.sub(pattern, fix_json_match, content, flags=re.DOTALL)
    
    file_path.write_text(fixed_content, encoding="utf-8")
    return fixes[0], insert_count


def main() -> None:
    args = parse_args()
    input_dir: Path = args.input_dir
    
    if not input_dir.exists() or not input_dir.is_dir():
        print(f"Error: Directory '{input_dir}' not found")
        return
    
    sql_files = sorted(input_dir.glob("table_*.sql"))
    
    if not sql_files:
        print(f"No table_*.sql files found in '{input_dir}'")
        return
    
    print(f"Fixing JSON in {len(sql_files)} SQL files...")
    if args.backup:
        print("Creating backups...")
    
    total_fixed = 0
    total_inserts = 0
    
    for sql_file in sql_files:
        if sql_file.name == "table_schema.sql":
            continue
        
        try:
            fixed, inserts = fix_file(sql_file, args.backup)
            total_fixed += fixed
            total_inserts += inserts
            if fixed > 0:
                print(f"  {sql_file.name}: fixed {fixed} JSON values in {inserts} INSERT statements")
        except Exception as e:
            print(f"  Error processing {sql_file.name}: {e}")
            import traceback
            traceback.print_exc()
    
    print(f"\nFixed {total_fixed} JSON values")
    print("Done!")


if __name__ == "__main__":
    main()

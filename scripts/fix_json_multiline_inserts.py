"""Fix JSON in SQL files with multiline INSERT statements."""
import argparse
import json
import re
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Fix JSON in SQL files with multiline INSERT statements.",
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
                # Try fixing double-escaped sequences first
                inner_fixed = inner.replace("\\\\n", "\n")
                inner_fixed = inner_fixed.replace("\\\\t", "\t")
                inner_fixed = inner_fixed.replace("\\\\r", "\r")
                # Then escape actual newlines
                inner_fixed = inner_fixed.replace("\n", "\\n")
                inner_fixed = inner_fixed.replace("\r", "\\r")
                inner_fixed = inner_fixed.replace("\t", "\\t")
                
                # Fix excessive backslashes
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


def extract_values_from_multiline_insert(insert_text: str) -> list[str]:
    """Extract values from a multiline INSERT statement."""
    # Find VALUES clause
    values_match = re.search(r'VALUES\s*\(', insert_text, re.IGNORECASE)
    if not values_match:
        return []
    
    values_start = values_match.end()
    
    # Find matching closing paren
    paren_count = 1
    i = values_start
    while i < len(insert_text) and paren_count > 0:
        if insert_text[i] == '(':
            paren_count += 1
        elif insert_text[i] == ')':
            paren_count -= 1
        i += 1
    
    if paren_count != 0:
        return []
    
    values_str = insert_text[values_start:i-1]
    
    # Split by comma, respecting quotes and nested structures
    values = []
    current = []
    depth = 0
    in_string = False
    quote_char = None
    
    for char in values_str:
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
                if quote_char == "'" and len(current) > 1 and current[-2] == "'":
                    # SQL escape: ''
                    continue
                else:
                    # End of string
                    in_string = False
                    quote_char = None
    
    if current:
        val = ''.join(current).strip()
        if val:
            values.append(val)
    
    return values


def fix_file(file_path: Path, backup: bool) -> tuple[int, int]:
    """Fix JSON in a SQL file, handling multiline INSERT statements."""
    if backup:
        backup_path = file_path.with_suffix(file_path.suffix + ".bak")
        backup_path.write_text(file_path.read_text(encoding="utf-8"), encoding="utf-8")
    
    content = file_path.read_text(encoding="utf-8")
    
    # Remove SQL line continuations
    content = re.sub(r'\\\s*\n\s*', '', content)
    
    lines = content.splitlines(keepends=True)
    fixed_lines = []
    fixed_count = 0
    insert_count = 0
    
    i = 0
    while i < len(lines):
        line = lines[i]
        
        if not line.strip().upper().startswith("INSERT INTO"):
            fixed_lines.append(line)
            i += 1
            continue
        
        insert_count += 1
        
        # Collect the entire INSERT statement (may span multiple lines)
        insert_text = line
        j = i + 1
        while j < len(lines) and ';' not in insert_text:
            insert_text += lines[j]
            j += 1
        
        # Fix JSON in this INSERT statement
        values = extract_values_from_multiline_insert(insert_text)
        if values:
            fixed_values = [fix_json_value(v) for v in values]
            
            # Reconstruct INSERT statement
            values_match = re.search(r'VALUES\s*\(', insert_text, re.IGNORECASE)
            if values_match:
                values_start = values_match.end()
                paren_count = 1
                k = values_start
                while k < len(insert_text) and paren_count > 0:
                    if insert_text[k] == '(':
                        paren_count += 1
                    elif insert_text[k] == ')':
                        paren_count -= 1
                    k += 1
                
                if paren_count == 0:
                    before = insert_text[:values_start]
                    after = insert_text[k-1:]
                    fixed_insert = before + ", ".join(fixed_values) + after
                    
                    if fixed_insert != insert_text:
                        fixed_count += 1
                    
                    fixed_lines.append(fixed_insert)
                    i = j
                    continue
        
        fixed_lines.append(line)
        i += 1
    
    file_path.write_text("".join(fixed_lines), encoding="utf-8")
    return fixed_count, insert_count


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
                print(f"  {sql_file.name}: fixed {fixed}/{inserts} INSERT statements")
        except Exception as e:
            print(f"  Error processing {sql_file.name}: {e}")
            import traceback
            traceback.print_exc()
    
    print(f"\nFixed {total_fixed} INSERT statements")
    print("Done!")


if __name__ == "__main__":
    main()

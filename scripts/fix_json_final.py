"""Final fix for JSON strings with newlines in SQL files."""
import argparse
import json
import re
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Fix JSON strings with newlines in SQL files.",
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


def fix_file(file_path: Path, backup: bool) -> int:
    """Fix JSON strings by replacing actual newlines with escape sequences."""
    if backup:
        backup_path = file_path.with_suffix(file_path.suffix + ".bak")
        backup_path.write_text(file_path.read_text(encoding="utf-8"), encoding="utf-8")
    
    content = file_path.read_text(encoding="utf-8")
    
    # Remove SQL line continuations first
    content = re.sub(r'\\\s*\n\s*', '', content)
    
    fixes = [0]
    
    def fix_json_match(match):
        """Fix a quoted string that contains JSON."""
        full = match.group(0)
        inner = match.group(1)
        
        # Unescape SQL quotes
        inner = inner.replace("''", "'")
        
        if not inner.strip().startswith(("{", "[")):
            return full
        
        # Check if it has actual newlines
        has_newline = "\n" in inner or "\r" in inner
        
        if has_newline:
            try:
                # Replace actual newlines with escape sequences
                inner_fixed = inner.replace("\n", "\\n")
                inner_fixed = inner_fixed.replace("\r", "\\r")
                inner_fixed = inner_fixed.replace("\t", "\\t")
                
                # Parse and re-serialize
                parsed = json.loads(inner_fixed)
                fixed = json.dumps(parsed, ensure_ascii=False)
                fixed = fixed.replace("'", "''")
                fixes[0] += 1
                return f"'{fixed}'"
            except json.JSONDecodeError:
                # Try more fixes
                try:
                    # Fix double-escaped sequences first
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
                    fixes[0] += 1
                    return f"'{fixed}'"
                except:
                    return full
        else:
            # No newlines, try parsing as-is
            try:
                parsed = json.loads(inner)
                fixed = json.dumps(parsed, ensure_ascii=False)
                fixed = fixed.replace("'", "''")
                fixes[0] += 1
                return f"'{fixed}'"
            except json.JSONDecodeError:
                return full
    
    # Match quoted strings - use DOTALL to handle newlines inside strings
    # Pattern: '...' where ... can contain '' (SQL escape) or any char including newline
    pattern = r"'((?:[^'\\]|\\.|'')*?)'"
    
    fixed_content = re.sub(pattern, fix_json_match, content, flags=re.DOTALL)
    
    file_path.write_text(fixed_content, encoding="utf-8")
    return fixes[0]


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
    
    for sql_file in sql_files:
        if sql_file.name == "table_schema.sql":
            continue
        
        try:
            fixed = fix_file(sql_file, args.backup)
            total_fixed += fixed
            if fixed > 0:
                print(f"  {sql_file.name}: fixed {fixed} JSON values")
        except Exception as e:
            print(f"  Error processing {sql_file.name}: {e}")
            import traceback
            traceback.print_exc()
    
    print(f"\nFixed {total_fixed} JSON values")
    print("Done!")


if __name__ == "__main__":
    main()

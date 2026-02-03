"""Fix JSON in SQL files that have multiline INSERT statements."""
import argparse
import json
import re
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Fix JSON syntax errors in SQL INSERT statements with multiline support.",
    )
    parser.add_argument(
        "input_file",
        type=Path,
        help="SQL file to fix.",
    )
    parser.add_argument(
        "--backup",
        action="store_true",
        help="Create backup file before fixing.",
    )
    return parser.parse_args()


def fix_file(file_path: Path, backup: bool) -> int:
    """Fix JSON in a SQL file, handling multiline INSERT statements."""
    if backup:
        backup_path = file_path.with_suffix(file_path.suffix + ".bak")
        backup_path.write_text(file_path.read_text(encoding="utf-8"), encoding="utf-8")
    
    content = file_path.read_text(encoding="utf-8")
    
    # Remove SQL line continuations
    content = re.sub(r'\\\s*\n\s*', '', content)
    
    fixes = [0]
    
    def fix_json_in_quoted_string(match):
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
    pattern = r"'((?:[^'\\]|\\.|'')*?)'"
    
    fixed_content = re.sub(pattern, fix_json_in_quoted_string, content, flags=re.DOTALL)
    
    file_path.write_text(fixed_content, encoding="utf-8")
    return fixes[0]


def main() -> None:
    args = parse_args()
    input_file: Path = args.input_file
    
    if not input_file.exists():
        print(f"Error: File '{input_file}' not found")
        return
    
    print(f"Fixing JSON in {input_file.name}...")
    if args.backup:
        print("Creating backup...")
    
    try:
        fixed = fix_file(input_file, args.backup)
        print(f"Fixed {fixed} JSON values")
        print("Done!")
    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()


if __name__ == "__main__":
    main()

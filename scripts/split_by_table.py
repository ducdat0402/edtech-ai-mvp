import argparse
import re
from pathlib import Path
from collections import defaultdict
from datetime import datetime


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Split a SQL file containing INSERT statements into separate files per table.",
    )
    parser.add_argument(
        "input",
        type=Path,
        help="Path to SQL file with INSERT statements.",
    )
    parser.add_argument(
        "output_dir",
        type=Path,
        nargs="?",
        help="Directory to write output files (default: <input>_tables/).",
    )
    parser.add_argument(
        "--prefix",
        type=str,
        default="table_",
        help="Prefix for output filenames (default: 'table_').",
    )
    return parser.parse_args()


def extract_table_name(insert_line: str) -> str | None:
    """
    Extract table name from INSERT INTO statement.
    
    Examples:
        INSERT INTO public.users (...) -> 'users'
        INSERT INTO users (...) -> 'users'
    """
    match = re.match(r'INSERT\s+INTO\s+(?:public\.)?(\w+)', insert_line, re.IGNORECASE)
    return match.group(1) if match else None


def split_file(input_path: Path, output_dir: Path, prefix: str) -> None:
    """
    Split SQL file by table, grouping INSERT statements per table.
    """
    output_dir.mkdir(parents=True, exist_ok=True)
    
    # Group INSERT statements by table name
    tables: dict[str, list[str]] = defaultdict(list)
    non_insert_lines: list[str] = []
    
    with input_path.open("r", encoding="utf-8") as fin:
        for line in fin:
            stripped = line.strip()
            
            if not stripped or stripped.startswith("--"):
                # Keep comments/empty lines with the first table or in a separate file
                continue
            
            if stripped.upper().startswith("INSERT INTO"):
                table_name = extract_table_name(stripped)
                if table_name:
                    tables[table_name].append(line)
                else:
                    # Malformed INSERT, keep in non-insert
                    non_insert_lines.append(line)
            else:
                # Non-INSERT statements (CREATE, ALTER, etc.)
                non_insert_lines.append(line)
    
    # Write each table to its own file
    for table_name, inserts in sorted(tables.items()):
        output_file = output_dir / f"{prefix}{table_name}.sql"
        
        with output_file.open("w", encoding="utf-8") as fout:
            # Write header
            fout.write(f"-- SQL data for table: {table_name}\n")
            fout.write(f"-- Generated from: {input_path.name}\n")
            fout.write(f"-- Generated at: {datetime.now().isoformat()}\n")
            fout.write(f"-- Total rows: {len(inserts)}\n")
            fout.write("\n")
            
            # Write all INSERT statements for this table
            for insert_line in inserts:
                fout.write(insert_line)
        
        print(f"  {output_file.name}: {len(inserts)} rows")
    
    # Write non-INSERT statements to a separate file if any
    if non_insert_lines:
        schema_file = output_dir / f"{prefix}schema.sql"
        with schema_file.open("w", encoding="utf-8") as fout:
            fout.write("-- Non-INSERT statements (CREATE, ALTER, etc.)\n")
            fout.write(f"-- Generated from: {input_path.name}\n")
            fout.write(f"-- Generated at: {datetime.now().isoformat()}\n")
            fout.write("\n")
            for line in non_insert_lines:
                fout.write(line)
        print(f"  {schema_file.name}: {len(non_insert_lines)} lines")
    
    print(f"\nSplit into {len(tables)} table files in '{output_dir}'")


def main() -> None:
    args = parse_args()
    input_path: Path = args.input
    output_dir: Path = args.output_dir or input_path.parent / f"{input_path.stem}_tables"
    
    if not input_path.exists():
        print(f"Error: Input file '{input_path}' not found")
        return
    
    print(f"Splitting '{input_path}' by table...")
    split_file(input_path, output_dir, args.prefix)
    print("Done!")


if __name__ == "__main__":
    main()

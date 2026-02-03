"""
Script to analyze dependencies and generate insert order for SQL files.
"""
from pathlib import Path
import re


def parse_foreign_keys(schema_file: Path) -> dict[str, list[str]]:
    """Parse foreign keys from schema file."""
    content = schema_file.read_text(encoding="utf-8")
    
    # Pattern: FK constraint referencing another table
    fk_pattern = r'ADD CONSTRAINT "[^"]+" FOREIGN KEY \("[^"]+"\) REFERENCES public\.(\w+)'
    
    # Pattern: ALTER TABLE table_name ... FK ...
    table_fk_pattern = r'ALTER TABLE ONLY public\.(\w+)\s+ADD CONSTRAINT "[^"]+" FOREIGN KEY[^R]+REFERENCES public\.(\w+)'
    
    dependencies: dict[str, list[str]] = {}
    
    for match in re.finditer(table_fk_pattern, content):
        table = match.group(1)
        ref_table = match.group(2)
        
        if table not in dependencies:
            dependencies[table] = []
        
        if ref_table not in dependencies[table]:
            dependencies[table].append(ref_table)
    
    return dependencies


def get_all_tables(sql_dir: Path) -> list[str]:
    """Get all table names from SQL files."""
    tables = []
    for sql_file in sorted(sql_dir.glob("table_*.sql")):
        if sql_file.name == "table_schema.sql":
            continue
        # Extract table name from filename: table_users.sql -> users
        table_name = sql_file.stem.replace("table_", "")
        tables.append(table_name)
    return tables


def topological_sort(tables: list[str], dependencies: dict[str, list[str]]) -> list[str]:
    """Topological sort to determine insert order."""
    # Build dependency graph
    graph: dict[str, set[str]] = {table: set() for table in tables}
    
    for table in tables:
        if table in dependencies:
            for dep in dependencies[table]:
                if dep in tables:
                    graph[table].add(dep)
    
    # Kahn's algorithm for topological sort
    in_degree = {table: 0 for table in tables}
    
    for table in tables:
        for dep in graph[table]:
            if dep in in_degree:
                in_degree[table] += 1
    
    queue = [table for table in tables if in_degree[table] == 0]
    result = []
    
    while queue:
        table = queue.pop(0)
        result.append(table)
        
        # Update in-degrees
        for other_table in tables:
            if table in graph[other_table]:
                in_degree[other_table] -= 1
                if in_degree[other_table] == 0:
                    queue.append(other_table)
    
    # Add any remaining tables (shouldn't happen if no cycles)
    remaining = [t for t in tables if t not in result]
    if remaining:
        result.extend(remaining)
    
    return result


def main():
    sql_dir = Path("scripts/backup_plain_tables")
    schema_file = sql_dir / "table_schema.sql"
    
    if not schema_file.exists():
        print(f"Error: Schema file not found: {schema_file}")
        return
    
    # Parse dependencies
    dependencies = parse_foreign_keys(schema_file)
    
    # Get all tables
    tables = get_all_tables(sql_dir)
    
    # Sort by dependencies
    insert_order = topological_sort(tables, dependencies)
    
    print("=" * 80)
    print("THU TU INSERT DATA")
    print("=" * 80)
    print()
    
    # Group by level (tables with same number of dependencies)
    levels: dict[int, list[str]] = {}
    for table in insert_order:
        deps = dependencies.get(table, [])
        # Count only dependencies that are in our table list
        dep_count = len([d for d in deps if d in tables])
        if dep_count not in levels:
            levels[dep_count] = []
        levels[dep_count].append(table)
    
    print("Thu tu insert theo dependencies:\n")
    for level in sorted(levels.keys()):
        if level == 0:
            print(f"Level {level + 1} (khong co dependencies):")
        else:
            print(f"Level {level + 1} (co {level} dependencies):")
        for table in levels[level]:
            deps = dependencies.get(table, [])
            dep_str = f" -> depends on: {', '.join(deps)}" if deps else " -> no dependencies"
            print(f"  table_{table}.sql{dep_str}")
        print()
    
    print("\n" + "=" * 80)
    print("DANH SACH FILE THEO THU TU:")
    print("=" * 80)
    print()
    
    for i, table in enumerate(insert_order, 1):
        print(f"{i:2d}. table_{table}.sql")
    
    print("\n" + "=" * 80)
    print("LENH INSERT (co the copy va chay):")
    print("=" * 80)
    print()
    
    print("-- Chay schema truoc:")
    print("\\i table_schema.sql")
    print()
    print("-- Sau do chay data theo thu tu:")
    for i, table in enumerate(insert_order, 1):
        print(f"\\i table_{table}.sql")


if __name__ == "__main__":
    main()

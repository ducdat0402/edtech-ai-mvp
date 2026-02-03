"""Check for foreign key violations in content_versions."""
import re
from pathlib import Path

cv_file = Path("scripts/backup_plain_tables/table_content_versions.sql")
ci_file = Path("scripts/backup_plain_tables/table_content_items.sql")

# Extract contentItemIds from content_versions
cv_content = cv_file.read_text(encoding="utf-8")
cv_ids = set()

# Parse INSERT statements - contentItemId is the 2nd column (index 1)
for line in cv_content.splitlines():
    if 'INSERT INTO' in line and 'content_versions' in line:
        # Find VALUES clause
        values_match = re.search(r'VALUES\s*\(', line, re.IGNORECASE)
        if values_match:
            values_start = values_match.end()
            # Extract all values
            values_str = line[values_start:]
            # Find closing paren
            paren_count = 1
            i = 0
            while i < len(values_str) and paren_count > 0:
                if values_str[i] == '(':
                    paren_count += 1
                elif values_str[i] == ')':
                    paren_count -= 1
                i += 1
            
            if paren_count == 0:
                values_part = values_str[:i-1]
                # Split by comma, respecting quotes
                values = []
                current = []
                in_quote = False
                quote_char = None
                
                for char in values_part:
                    if not in_quote:
                        if char in ("'", '"'):
                            in_quote = True
                            quote_char = char
                            current.append(char)
                        elif char == ',':
                            val = ''.join(current).strip()
                            if val:
                                values.append(val)
                            current = []
                        else:
                            current.append(char)
                    else:
                        current.append(char)
                        if char == quote_char:
                            # Check if escaped
                            if len(current) > 1 and current[-2] == '\\':
                                continue
                            # Check for SQL escape ''
                            if quote_char == "'" and len(current) > 1 and current[-2] == "'":
                                continue
                            in_quote = False
                            quote_char = None
                
                if current:
                    val = ''.join(current).strip()
                    if val:
                        values.append(val)
                
                # contentItemId is the 2nd value (index 1)
                if len(values) > 1:
                    ci_id = values[1].strip("'\"")
                    cv_ids.add(ci_id)

print(f"ContentItemIds referenced in content_versions: {len(cv_ids)}")
if cv_ids:
    print(f"IDs: {sorted(cv_ids)}")

# Extract IDs from content_items (first value in VALUES)
ci_content = ci_file.read_text(encoding="utf-8")
ci_ids = set()

for line in ci_content.splitlines():
    if 'INSERT INTO' in line and 'content_items' in line:
        values_match = re.search(r'VALUES\s*\(', line, re.IGNORECASE)
        if values_match:
            values_start = values_match.end()
            # Find first UUID value
            id_match = re.search(r"'([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})'", line[values_start:values_start+100])
            if id_match:
                ci_ids.add(id_match.group(1))

print(f"\nContentItemIds in content_items: {len(ci_ids)}")

# Check which CV IDs are missing in CI
if cv_ids:
    missing = cv_ids - ci_ids
    if missing:
        print(f"\nERROR: Missing contentItemIds in content_items:")
        for mid in missing:
            print(f"  - {mid}")
        print("\nThese IDs are referenced in content_versions but don't exist in content_items!")
        print("\nSolution: Either:")
        print("  1. Remove these rows from content_versions, OR")
        print("  2. Add the missing content_items first")
    else:
        print("\nAll contentItemIds exist in content_items.")
        print("The issue might be with insert order - make sure content_items is inserted before content_versions.")
else:
    print("\nCould not extract contentItemIds from content_versions file.")

import argparse
import re
from pathlib import Path


def parse_args() -> argparse.Namespace:
  parser = argparse.ArgumentParser(
    description=(
      "Convert PostgreSQL pg_dump (plain) file into 'plain SQL': "
      "rewrite COPY ... FROM stdin blocks to INSERT INTO and optionally strip pg_dump/psql meta."
    ),
  )
  parser.add_argument(
    "input",
    type=Path,
    help="Path to original pg_dump SQL file (with COPY ... FROM stdin blocks).",
  )
  parser.add_argument(
    "output",
    type=Path,
    nargs="?",
    help="Path to output SQL file (default: <input>_plain.sql).",
  )
  parser.add_argument(
    "--keep-meta",
    action="store_true",
    help="Keep pg_dump/psql meta statements (SET, SELECT set_config, \\restrict, GRANT/REVOKE...).",
  )
  return parser.parse_args()


_re_int = re.compile(r"^[+-]?\d+$")
_re_float = re.compile(r"^[+-]?(?:\d+\.\d*|\d*\.\d+)(?:[eE][+-]?\d+)?$|^[+-]?\d+[eE][+-]?\d+$")


def escape_value(value: str) -> str:
  """
  Convert a single COPY field to an SQL literal.

  - \\N -> NULL
  - numbers/booleans kept unquoted (Postgres will cast strings too, but this is cleaner)
  - otherwise wrap in single-quotes and escape embedded quotes
  """
  if value == r"\N":
    return "NULL"

  # pg_dump COPY uses \t separators; fields may contain literal newlines encoded as \n in text.
  # We keep them as-is (standard_conforming_strings=on in dumps).

  # Booleans in COPY are typically 't'/'f'
  if value == "t":
    return "TRUE"
  if value == "f":
    return "FALSE"

  # Numeric heuristics
  if _re_int.match(value) or _re_float.match(value):
    return value

  # Basic escaping for single quotes; pg_dump uses standard_conforming_strings=on,
  # so backslashes are literal and don't need special handling.
  escaped = value.replace("'", "''")
  return f"'{escaped}'"


def convert_copy_block(header_line: str, data_lines: list[str]) -> list[str]:
  """
  Given a COPY header and its data lines, return equivalent INSERT statements.

  Example header:
    COPY public.users (id, email) FROM stdin;
  """
  header = header_line.strip()
  # Remove trailing " FROM stdin;" and leading "COPY "
  assert header.startswith("COPY "), f"Unexpected COPY header: {header}"
  header_body = header[len("COPY ") :]
  if header_body.endswith(" FROM stdin;"):
    header_body = header_body[: -len(" FROM stdin;")]

  insert_prefix = f"INSERT INTO {header_body} VALUES "

  insert_lines: list[str] = []
  for raw in data_lines:
    line = raw.rstrip("\n")
    if not line or line == r"\.":
      continue

    fields = line.split("\t")
    values_sql = ", ".join(escape_value(f) for f in fields)
    insert_lines.append(insert_prefix + f"({values_sql});\n")

  return insert_lines


def _is_meta_line(line: str) -> bool:
  stripped = line.strip()

  # psql meta commands in plain dumps (not valid SQL)
  if stripped.startswith("\\"):
    # Keep COPY terminator is handled elsewhere; everything else is meta
    return True

  # Common pg_dump boilerplate that isn't needed for a "plain SQL" import
  if stripped.startswith("SET "):
    return True
  if stripped.startswith("SELECT pg_catalog.set_config"):
    return True
  if stripped.startswith("ALTER ") and " OWNER TO " in stripped:
    return True
  if stripped.startswith("REVOKE ") or stripped.startswith("GRANT "):
    return True
  if stripped.startswith("COMMENT ON EXTENSION "):
    return True

  return False


def convert_file(input_path: Path, output_path: Path, *, keep_meta: bool) -> None:
  # Stream line-by-line so it works for large dumps
  with input_path.open("r", encoding="utf-8") as fin, output_path.open("w", encoding="utf-8") as fout:
    while True:
      line = fin.readline()
      if not line:
        break

      if line.startswith("COPY ") and line.rstrip().endswith("FROM stdin;"):
        copy_header = line
        data_lines: list[str] = []

        while True:
          data_line = fin.readline()
          if not data_line:
            break
          if data_line.strip() == r"\.":
            break
          data_lines.append(data_line)

        for ins in convert_copy_block(copy_header, data_lines):
          fout.write(ins)
        continue

      if not keep_meta and _is_meta_line(line):
        continue

      fout.write(line)


def main() -> None:
  args = parse_args()
  input_path: Path = args.input
  output_path: Path = args.output or input_path.with_name(input_path.stem + "_plain.sql")

  convert_file(input_path, output_path, keep_meta=args.keep_meta)
  print(f"Converted '{input_path}' -> '{output_path}'")


if __name__ == "__main__":
  main()


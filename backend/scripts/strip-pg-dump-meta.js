/**
 * Remove pg_dump 18+ \restrict / \unrestrict lines for portable DDL sharing.
 */
const fs = require('fs');
const path = require('path');

const file = path.resolve(process.argv[2] || path.join(__dirname, '..', 'schema-export.sql'));
let s = fs.readFileSync(file, 'utf8');
const lines = s.split(/\r?\n/).filter(
  (l) => !l.startsWith('\\restrict') && !l.startsWith('\\unrestrict'),
);
fs.writeFileSync(file, lines.join('\n') + '\n');

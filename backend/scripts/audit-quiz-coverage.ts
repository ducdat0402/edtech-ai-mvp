import 'dotenv/config';
import { Client } from 'pg';

type QuestionRow = {
  subject_id: string;
  subject_name: string;
  node_id: string;
  node_title: string;
  source: 'learning_nodes' | 'lesson_type_contents';
  question: any;
};

const REQUIRED_KEYS = [
  'logical_thinking',
  'practical_application',
  'systems_thinking',
  'creativity',
  'critical_thinking',
] as const;

function safeQuestions(raw: any): any[] {
  if (!raw || typeof raw !== 'object') return [];
  const qs = (raw as any).questions;
  return Array.isArray(qs) ? qs : [];
}

function competencyKeys(question: any): string[] {
  const mix = question?.competencyMix;
  if (!mix || typeof mix !== 'object' || Array.isArray(mix)) return [];
  return Object.entries(mix)
    .filter(([k, v]) => !!k && typeof v === 'number' && Number.isFinite(v) && v > 0)
    .map(([k]) => k);
}

async function main() {
  const databaseUrl = process.env.DATABASE_URL;
  if (!databaseUrl) {
    throw new Error('Missing DATABASE_URL in environment');
  }

  const client = new Client({
    connectionString: databaseUrl,
    ssl: { rejectUnauthorized: false },
  });
  await client.connect();

  try {
    const sql = `
      select s.id as subject_id, s.name as subject_name, n.id as node_id, n.title as node_title, 'learning_nodes' as source, q as question
      from learning_nodes n
      join subjects s on s.id = n."subjectId"
      cross join lateral jsonb_array_elements(coalesce(n."endQuiz"->'questions', '[]'::jsonb)) as q
      union all
      select s.id as subject_id, s.name as subject_name, n.id as node_id, n.title as node_title, 'lesson_type_contents' as source, q as question
      from lesson_type_contents ltc
      join learning_nodes n on n.id = ltc."nodeId"
      join subjects s on s.id = n."subjectId"
      cross join lateral jsonb_array_elements(coalesce(ltc."endQuiz"->'questions', '[]'::jsonb)) as q
    `;
    const result = await client.query(sql);
    const rows = result.rows as QuestionRow[];

    const bySubject = new Map<
      string,
      {
        name: string;
        questionCount: number;
        perKey: Record<string, number>;
        nodes: Map<
          string,
          {
            title: string;
            questionCount: number;
            perKey: Record<string, number>;
          }
        >;
      }
    >();

    for (const row of rows) {
      if (!bySubject.has(row.subject_id)) {
        bySubject.set(row.subject_id, {
          name: row.subject_name,
          questionCount: 0,
          perKey: Object.fromEntries(REQUIRED_KEYS.map((k) => [k, 0])),
          nodes: new Map(),
        });
      }
      const subject = bySubject.get(row.subject_id)!;
      if (!subject.nodes.has(row.node_id)) {
        subject.nodes.set(row.node_id, {
          title: row.node_title,
          questionCount: 0,
          perKey: Object.fromEntries(REQUIRED_KEYS.map((k) => [k, 0])),
        });
      }
      const node = subject.nodes.get(row.node_id)!;

      const keys = new Set(competencyKeys(row.question));
      subject.questionCount += 1;
      node.questionCount += 1;

      for (const k of REQUIRED_KEYS) {
        if (keys.has(k)) {
          subject.perKey[k] += 1;
          node.perKey[k] += 1;
        }
      }
    }

    console.log('\n=== QUIZ COMPETENCY COVERAGE AUDIT ===');
    console.log(`Subjects audited: ${bySubject.size}`);
    console.log(`Questions audited: ${rows.length}\n`);

    for (const [, subject] of [...bySubject.entries()].sort((a, b) =>
      a[1].name.localeCompare(b[1].name),
    )) {
      console.log(`Subject: ${subject.name}`);
      console.log(`  Questions: ${subject.questionCount}`);
      for (const k of REQUIRED_KEYS) {
        const pct = subject.questionCount
          ? ((subject.perKey[k] / subject.questionCount) * 100).toFixed(1)
          : '0.0';
        console.log(`  - ${k}: ${subject.perKey[k]} (${pct}%)`);
      }

      const weakNodes = [...subject.nodes.entries()]
        .map(([id, n]) => {
          const missingKeys = REQUIRED_KEYS.filter((k) => n.perKey[k] === 0);
          return {
            id,
            title: n.title,
            questionCount: n.questionCount,
            missingKeys,
          };
        })
        .filter((x) => x.missingKeys.length > 0)
        .sort((a, b) => b.missingKeys.length - a.missingKeys.length)
        .slice(0, 8);

      if (weakNodes.length) {
        console.log('  Nodes ưu tiên regen (thiếu key):');
        for (const n of weakNodes) {
          console.log(
            `   * ${n.title} [${n.id}] | q=${n.questionCount} | missing=${n.missingKeys.join(', ')}`,
          );
        }
      } else {
        console.log('  Nodes ưu tiên regen: không có (coverage ổn)');
      }
      console.log('');
    }

    console.log(
      'Gợi ý: ưu tiên regen các node thiếu critical_thinking/systems_thinking trước.',
    );
  } finally {
    await client.end();
  }
}

main().catch((err) => {
  console.error('Audit failed:', err);
  process.exit(1);
});


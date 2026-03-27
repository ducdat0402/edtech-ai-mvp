import 'dotenv/config';
import { Client } from 'pg';

type QuizRow = {
  source: 'learning_nodes' | 'lesson_type_contents';
  id: string;
  node_id: string;
  subject_id: string;
  subject_name: string;
  node_title: string;
  lesson_type: string | null;
  end_quiz: any;
};

type ParsedArgs = {
  subjectId?: string;
  subjectName?: string;
  limit: number;
  offset: number;
  apply: boolean;
};

const REQUIRED_KEYS = [
  'logical_thinking',
  'practical_application',
  'systems_thinking',
  'creativity',
  'critical_thinking',
] as const;

function parseArgs(argv: string[]): ParsedArgs {
  const args: ParsedArgs = {
    limit: 200,
    offset: 0,
    apply: false,
  };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    const next = argv[i + 1];
    if (a === '--subject-id' && next) {
      args.subjectId = next;
      i++;
    } else if (a === '--subject-name' && next) {
      args.subjectName = next;
      i++;
    } else if (a === '--limit' && next) {
      args.limit = Math.max(1, Number(next) || 200);
      i++;
    } else if (a === '--offset' && next) {
      args.offset = Math.max(0, Number(next) || 0);
      i++;
    } else if (a === '--apply') {
      args.apply = true;
    }
  }
  return args;
}

function normalizeMix(raw: Record<string, number>): Record<string, number> {
  const clean: Record<string, number> = {};
  let sum = 0;
  for (const [k, v] of Object.entries(raw)) {
    if (!REQUIRED_KEYS.includes(k as any)) continue;
    if (typeof v !== 'number' || !Number.isFinite(v) || v <= 0) continue;
    clean[k] = v;
    sum += v;
  }
  if (sum <= 0) {
    return {
      logical_thinking: 0.3,
      practical_application: 0.2,
      systems_thinking: 0.2,
      creativity: 0.1,
      critical_thinking: 0.2,
    };
  }
  const out: Record<string, number> = {};
  for (const k of REQUIRED_KEYS) {
    out[k] = Math.round(((clean[k] ?? 0) / sum) * 1000) / 1000;
  }
  return out;
}

function inferLogicTypes(text: string): string[] {
  const t = text.toLowerCase();
  const out = new Set<string>();
  if (/(so sánh|khác nhau|tương đồng|compare)/.test(t)) out.add('compare');
  if (/(giả định|ngầm định|assumption)/.test(t)) out.add('assumption_check');
  if (/(bằng chứng|nguồn|độ tin cậy|evidence|source)/.test(t))
    out.add('source_reliability');
  if (/(hệ quả|nếu.*thì|cause|effect|tác động dây chuyền)/.test(t))
    out.add('inference');
  if (/(trình tự|thứ tự|bước)/.test(t)) out.add('sequence');
  if (out.size === 0) out.add('inference');
  return [...out];
}

function inferMix(text: string): Record<string, number> {
  const t = text.toLowerCase();
  const score = {
    logical_thinking: 1.0,
    practical_application: 0.8,
    systems_thinking: 0.8,
    creativity: 0.6,
    critical_thinking: 1.0,
  };
  if (/(thực tế|tình huống|áp dụng|scenario|case)/.test(t))
    score.practical_application += 0.7;
  if (/(hệ thống|liên kết|tác động dây chuyền|toàn cục|trade-off)/.test(t))
    score.systems_thinking += 0.9;
  if (/(sáng tạo|ý tưởng|phương án mới|đa phương án|alternative)/.test(t))
    score.creativity += 0.9;
  if (/(lập luận|phản biện|giả định|bằng chứng|nguồn tin|ngụy biện|argument)/.test(t))
    score.critical_thinking += 1.0;
  if (/(suy luận|logic|hệ quả|if|then|inference)/.test(t))
    score.logical_thinking += 0.7;
  return normalizeMix(score);
}

function ensureCriticalCoverage(questions: any[]) {
  const idx = questions
    .map((q, i) => ({
      i,
      c: (q.competencyMix?.critical_thinking ?? 0) as number,
    }))
    .sort((a, b) => b.c - a.c);
  const already = idx.filter((x) => x.c >= 0.4).length;
  if (already >= 2) return;
  const need = Math.min(2 - already, idx.length);
  for (let k = 0; k < need; k++) {
    const i = idx[k]?.i;
    if (i === undefined) continue;
    const q = questions[i];
    const mix = { ...(q.competencyMix ?? {}) } as Record<string, number>;
    mix.critical_thinking = Math.max(0.4, mix.critical_thinking ?? 0);
    q.competencyMix = normalizeMix(mix);
  }
}

function transformQuiz(endQuiz: any): { changed: boolean; next: any } {
  if (!endQuiz || typeof endQuiz !== 'object') return { changed: false, next: endQuiz };
  const questions = Array.isArray(endQuiz.questions) ? [...endQuiz.questions] : [];
  if (!questions.length) return { changed: false, next: endQuiz };

  let changed = false;
  const nextQuestions = questions.map((q) => {
    const text = [
      String(q?.question ?? ''),
      ...(Array.isArray(q?.options) ? q.options.map((x: any) => String(x?.text ?? '')) : []),
    ].join(' ');
    const prevMix = q?.competencyMix;
    const hasValidPrevMix =
      prevMix &&
      typeof prevMix === 'object' &&
      !Array.isArray(prevMix) &&
      Object.values(prevMix).some((v) => typeof v === 'number' && v > 0);
    const mix = hasValidPrevMix
      ? normalizeMix(prevMix as Record<string, number>)
      : inferMix(text);

    const prevLogicTypes = Array.isArray(q?.logicTypes) ? q.logicTypes : [];
    const logicTypes =
      prevLogicTypes.length > 0
        ? [...new Set(prevLogicTypes.map((x: any) => String(x).trim()).filter(Boolean))]
        : inferLogicTypes(text);

    if (
      JSON.stringify(prevMix ?? null) !== JSON.stringify(mix) ||
      JSON.stringify(prevLogicTypes) !== JSON.stringify(logicTypes)
    ) {
      changed = true;
    }
    return {
      ...q,
      competencyMix: mix,
      logicTypes,
    };
  });

  ensureCriticalCoverage(nextQuestions);
  if (JSON.stringify(questions) !== JSON.stringify(nextQuestions)) changed = true;
  return {
    changed,
    next: {
      ...endQuiz,
      questions: nextQuestions,
      passingScore: Number(endQuiz.passingScore) > 0 ? endQuiz.passingScore : 70,
    },
  };
}

async function listSubjects(client: Client) {
  const rs = await client.query(
    `select id, name from subjects order by name asc`,
  );
  console.log('\nSubjects:');
  for (const r of rs.rows) {
    console.log(`- ${r.name} [${r.id}]`);
  }
  console.log(
    '\nUsage:\n  npx ts-node scripts/backfill-quiz-competency-mix-by-subject.ts --subject-id <uuid> --limit 200 --offset 0 --apply',
  );
}

async function main() {
  const databaseUrl = process.env.DATABASE_URL;
  if (!databaseUrl) throw new Error('Missing DATABASE_URL');
  const args = parseArgs(process.argv.slice(2));

  const client = new Client({
    connectionString: databaseUrl,
    ssl: { rejectUnauthorized: false },
  });
  await client.connect();
  try {
    if (!args.subjectId && !args.subjectName) {
      await listSubjects(client);
      return;
    }

    const conds: string[] = [];
    const vals: any[] = [];
    if (args.subjectId) {
      vals.push(args.subjectId);
      conds.push(`s.id = $${vals.length}`);
    }
    if (args.subjectName) {
      vals.push(args.subjectName);
      conds.push(`s.name ilike $${vals.length}`);
    }
    vals.push(args.limit, args.offset);
    const where = conds.length ? `where ${conds.join(' and ')}` : '';

    const sql = `
      select 'learning_nodes'::text as source, n.id::text as id, n.id::text as node_id, s.id::text as subject_id, s.name as subject_name,
             n.title as node_title, n."lessonType"::text as lesson_type, n."endQuiz" as end_quiz
      from learning_nodes n
      join subjects s on s.id = n."subjectId"
      ${where}
      order by n."createdAt" asc
      limit $${vals.length - 1} offset $${vals.length}
    `;

    const sqlLtc = `
      select 'lesson_type_contents'::text as source, ltc.id::text as id, n.id::text as node_id, s.id::text as subject_id, s.name as subject_name,
             n.title as node_title, ltc."lessonType"::text as lesson_type, ltc."endQuiz" as end_quiz
      from lesson_type_contents ltc
      join learning_nodes n on n.id = ltc."nodeId"
      join subjects s on s.id = n."subjectId"
      ${where}
      order by ltc."createdAt" asc
      limit $${vals.length - 1} offset $${vals.length}
    `;

    const [nodesRs, ltcRs] = await Promise.all([
      client.query(sql, vals),
      client.query(sqlLtc, vals),
    ]);
    const rows = [...(nodesRs.rows as QuizRow[]), ...(ltcRs.rows as QuizRow[])];

    if (!rows.length) {
      console.log('No quizzes found for provided subject filter.');
      return;
    }

    let changedRows = 0;
    let changedQuestions = 0;
    for (const row of rows) {
      const { changed, next } = transformQuiz(row.end_quiz);
      if (!changed) continue;
      changedRows++;
      changedQuestions += Array.isArray(next?.questions) ? next.questions.length : 0;
      if (args.apply) {
        if (row.source === 'learning_nodes') {
          await client.query(`update learning_nodes set "endQuiz" = $1 where id = $2`, [
            JSON.stringify(next),
            row.id,
          ]);
        } else {
          await client.query(
            `update lesson_type_contents set "endQuiz" = $1 where id = $2`,
            [JSON.stringify(next), row.id],
          );
        }
      }
    }

    console.log('\n=== BACKFILL QUIZ COMPETENCY MIX ===');
    console.log(`Mode: ${args.apply ? 'APPLY' : 'DRY_RUN'}`);
    console.log(`Rows scanned: ${rows.length}`);
    console.log(`Rows changed: ${changedRows}`);
    console.log(`Questions updated(est): ${changedQuestions}`);
    if (!args.apply) {
      console.log('No DB changes were written. Re-run with --apply to persist.');
    }
  } finally {
    await client.end();
  }
}

main().catch((e) => {
  console.error('Backfill failed:', e);
  process.exit(1);
});


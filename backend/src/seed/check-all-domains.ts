/**
 * Script kiểm tra tất cả domains và liệt kê
 */

import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module';
import { SubjectsModule } from '../subjects/subjects.module';
import { SubjectsService } from '../subjects/subjects.service';
import { KnowledgeGraphModule } from '../knowledge-graph/knowledge-graph.module';
import { KnowledgeGraphService } from '../knowledge-graph/knowledge-graph.service';
import { NodeType } from '../knowledge-graph/entities/knowledge-node.entity';
import { EdgeType } from '../knowledge-graph/entities/knowledge-edge.entity';

async function checkAllDomains() {
  const app = await NestFactory.createApplicationContext(AppModule);
  const subjectsService = app.select(SubjectsModule).get(SubjectsService);
  const kgService = app.select(KnowledgeGraphModule).get(KnowledgeGraphService);

  const allSubjects = await subjectsService.findByTrack('explorer');
  console.log('🔍 Liệt kê tất cả domains:\n');

  for (const subject of allSubjects) {
    const mindMap = await kgService.getMindMapForSubject(subject.id);
    const domainNodes = mindMap.nodes.filter(n => n.type === NodeType.DOMAIN);

    console.log(`\n📖 ${subject.name} (${domainNodes.length} domains):`);

    const domainNames: string[] = [];
    domainNodes.forEach(domain => {
      const topicCount = mindMap.edges.filter(
        e => e.fromNodeId === domain.id && e.type === EdgeType.PART_OF
      ).length;
      domainNames.push(domain.name);
      console.log(`   - ${domain.name} (${topicCount} topics)`);
    });

    // Kiểm tra trùng
    const nameMap = new Map<string, string[]>();
    domainNames.forEach(name => {
      const key = name.toLowerCase().trim().replace(/\s+/g, ' ');
      if (!nameMap.has(key)) {
        nameMap.set(key, []);
      }
      nameMap.get(key)!.push(name);
    });

    const duplicates = Array.from(nameMap.entries()).filter(([_, names]) => names.length > 1);
    if (duplicates.length > 0) {
      console.log(`   ⚠️  DOMAINS TRÙNG:`);
      duplicates.forEach(([key, names]) => {
        console.log(`      - "${key}": ${names.join(', ')}`);
      });
    }

    // Kiểm tra domain không có topics
    const domainsWithoutTopics = domainNodes.filter(domain => {
      const hasTopics = mindMap.edges.some(
        e => e.fromNodeId === domain.id && e.type === EdgeType.PART_OF
      );
      return !hasTopics;
    });

    if (domainsWithoutTopics.length > 0) {
      console.log(`   ⚠️  Domains không có topics (${domainsWithoutTopics.length}):`);
      domainsWithoutTopics.forEach(d => console.log(`      - ${d.name}`));
    }
  }

  await app.close();
}

checkAllDomains().catch(console.error);

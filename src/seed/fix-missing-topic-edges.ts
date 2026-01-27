/**
 * Script sửa các topics thiếu edge với domain
 * 
 * CÁCH SỬ DỤNG:
 * npx ts-node src/seed/fix-missing-topic-edges.ts
 */

import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module';
import { SubjectsModule } from '../subjects/subjects.module';
import { SubjectsService } from '../subjects/subjects.service';
import { KnowledgeGraphModule } from '../knowledge-graph/knowledge-graph.module';
import { KnowledgeGraphService } from '../knowledge-graph/knowledge-graph.service';
import { NodeType } from '../knowledge-graph/entities/knowledge-node.entity';
import { EdgeType } from '../knowledge-graph/entities/knowledge-edge.entity';

async function fixMissingTopicEdges() {
  const app = await NestFactory.createApplicationContext(AppModule);
  const subjectsService = app.select(SubjectsModule).get(SubjectsService);
  const kgService = app.select(KnowledgeGraphModule).get(KnowledgeGraphService);

  console.log('🔧 Đang sửa các topics thiếu edge với domain...\n');

  try {
    const allSubjects = await subjectsService.findByTrack('explorer');
    console.log(`📚 Tìm thấy ${allSubjects.length} môn học\n`);

    let totalFixed = 0;

    for (const subject of allSubjects) {
      console.log(`\n📖 Subject: ${subject.name} (ID: ${subject.id})`);
      console.log('─'.repeat(60));

      try {
        const mindMap = await kgService.getMindMapForSubject(subject.id);
        
        if (mindMap.nodes.length === 0) {
          console.log('   ⚠️  Không có mind map');
          continue;
        }

        const domainNodes = mindMap.nodes.filter(n => n.type === NodeType.DOMAIN);
        const topicNodes = mindMap.nodes.filter(n => {
          const isConcept = n.type === NodeType.CONCEPT;
          const originalType = (n.metadata as any)?.originalType;
          return isConcept && (originalType === 'topic' || originalType === 'concept');
        });

        console.log(`   📊 Domains: ${domainNodes.length}, Topics: ${topicNodes.length}`);

        let fixedCount = 0;

        for (const topic of topicNodes) {
          // Kiểm tra xem topic có edge với domain chưa
          const hasEdge = mindMap.edges.some(e => 
            e.toNodeId === topic.id && e.type === EdgeType.PART_OF
          );

          if (!hasEdge) {
            // Tìm domain gần nhất (có thể dựa vào tên hoặc tạo edge với domain đầu tiên)
            // Hoặc tìm domain có nhiều topics nhất để gán vào
            let targetDomain = domainNodes[0]; // Mặc định là domain đầu tiên

            // Tìm domain có nhiều topics nhất
            const domainTopicCounts = new Map<string, number>();
            domainNodes.forEach(domain => {
              const count = mindMap.edges.filter(e => 
                e.fromNodeId === domain.id && e.type === EdgeType.PART_OF
              ).length;
              domainTopicCounts.set(domain.id, count);
            });

            // Chọn domain có ít topics nhất để phân bổ đều
            let minCount = Infinity;
            for (const [domainId, count] of domainTopicCounts.entries()) {
              if (count < minCount) {
                minCount = count;
                targetDomain = domainNodes.find(d => d.id === domainId)!;
              }
            }

            // Tạo edge từ domain đến topic
            await kgService.createEdge(
              targetDomain.id,
              topic.id,
              EdgeType.PART_OF,
              {
                description: `${topic.name} là phần của ${targetDomain.name}`,
                weight: 1.0,
              },
            );

            console.log(`   ✅ Đã tạo edge: ${targetDomain.name} -> ${topic.name}`);
            fixedCount++;
          }
        }

        if (fixedCount > 0) {
          console.log(`   📊 Đã sửa ${fixedCount} topics`);
          totalFixed += fixedCount;
        } else {
          console.log(`   ✅ Tất cả topics đã có edge với domain`);
        }
      } catch (error) {
        console.error(`   ❌ Lỗi khi xử lý subject "${subject.name}":`, error.message);
      }
    }

    console.log('\n' + '═'.repeat(60));
    console.log(`✅ Hoàn thành! Đã sửa tổng cộng ${totalFixed} topics`);
  } catch (error) {
    console.error('❌ Lỗi:', error);
  } finally {
    await app.close();
  }
}

fixMissingTopicEdges().catch(console.error);

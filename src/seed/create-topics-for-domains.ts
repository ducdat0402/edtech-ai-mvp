/**
 * Script tạo topics cho các domains còn thiếu
 * 
 * CÁCH SỬ DỤNG:
 * npx ts-node src/seed/create-topics-for-domains.ts
 */

import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module';
import { SubjectsModule } from '../subjects/subjects.module';
import { SubjectsService } from '../subjects/subjects.service';
import { KnowledgeGraphModule } from '../knowledge-graph/knowledge-graph.module';
import { KnowledgeGraphService } from '../knowledge-graph/knowledge-graph.service';
import { AiModule } from '../ai/ai.module';
import { AiService } from '../ai/ai.service';
import { NodeType } from '../knowledge-graph/entities/knowledge-node.entity';
import { EdgeType } from '../knowledge-graph/entities/knowledge-edge.entity';

async function createTopicsForDomains() {
  const app = await NestFactory.createApplicationContext(AppModule);
  const subjectsService = app.select(SubjectsModule).get(SubjectsService);
  const kgService = app.select(KnowledgeGraphModule).get(KnowledgeGraphService);
  const aiService = app.select(AiModule).get(AiService);

  console.log('🔧 Đang tạo topics cho các domains còn thiếu...\n');

  try {
    const allSubjects = await subjectsService.findByTrack('explorer');
    console.log(`📚 Tìm thấy ${allSubjects.length} môn học\n`);

    let totalCreated = 0;

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

        // Tìm các domains không có topics
        const domainsWithoutTopics = domainNodes.filter(domain => {
          const hasTopics = mindMap.edges.some(e => 
            e.fromNodeId === domain.id && e.type === EdgeType.PART_OF
          );
          return !hasTopics;
        });

        if (domainsWithoutTopics.length === 0) {
          console.log('   ✅ Tất cả domains đều có topics');
          continue;
        }

        console.log(`   ⚠️  Tìm thấy ${domainsWithoutTopics.length} domains không có topics:`);
        domainsWithoutTopics.forEach(d => console.log(`      - ${d.name}`));

        // Tạo topics cho mỗi domain thiếu
        for (const domain of domainsWithoutTopics) {
          try {
            console.log(`\n   🎯 Đang tạo topics cho domain "${domain.name}"...`);

            // Sử dụng AI để tạo 2-3 topics cho domain này
            const topicsPrompt = `Bạn là một chuyên gia giáo dục. Hãy tạo 2-3 topics (chủ đề học tập) chi tiết cho domain "${domain.name}" trong môn học "${subject.name}".

Yêu cầu:
- Mỗi topic phải là một chủ đề học tập cụ thể và thực tế
- Topics phải liên quan trực tiếp đến domain "${domain.name}"
- Mỗi topic cần có tên ngắn gọn (2-5 từ) và mô tả chi tiết (1-2 câu)

Trả về JSON array với format:
[
  {
    "name": "Tên topic",
    "description": "Mô tả chi tiết về topic này"
  },
  ...
]`;

            const aiResponse = await aiService.chat([
              {
                role: 'system',
                content: 'Bạn là một chuyên gia giáo dục. Trả về JSON hợp lệ, không có markdown formatting.',
              },
              {
                role: 'user',
                content: topicsPrompt,
              },
            ]);

            // Parse JSON response
            let topicsData: Array<{ name: string; description: string }> = [];
            try {
              const jsonMatch = aiResponse.match(/\[[\s\S]*\]/);
              if (jsonMatch) {
                topicsData = JSON.parse(jsonMatch[0]);
              } else {
                topicsData = JSON.parse(aiResponse);
              }
            } catch (parseError) {
              console.error(`      ❌ Lỗi parse JSON: ${parseError.message}`);
              console.error(`      Response: ${aiResponse.substring(0, 200)}`);
              // Fallback: tạo 2 topics mặc định
              topicsData = [
                {
                  name: `${domain.name} - Cơ bản`,
                  description: `Kiến thức cơ bản về ${domain.name}`,
                },
                {
                  name: `${domain.name} - Nâng cao`,
                  description: `Kiến thức nâng cao về ${domain.name}`,
                },
              ];
            }

            // Tạo knowledge nodes cho các topics
            for (const topicData of topicsData) {
              const entityId = `${subject.id}_${domain.name}_${topicData.name}`;
              
              const topicNode = await kgService.createOrUpdateNode(
                topicData.name,
                NodeType.CONCEPT,
                entityId,
                {
                  description: topicData.description,
                  metadata: {
                    subjectId: subject.id,
                    subjectName: subject.name,
                    domainName: domain.name,
                    originalType: 'topic',
                  },
                },
              );

              // Tạo edge từ domain đến topic
              await kgService.createEdge(
                domain.id,
                topicNode.id,
                EdgeType.PART_OF,
                {
                  description: `${topicData.name} là phần của ${domain.name}`,
                  weight: 1.0,
                },
              );

              console.log(`      ✅ Đã tạo topic: "${topicData.name}"`);
              totalCreated++;
            }
          } catch (error) {
            console.error(`      ❌ Lỗi khi tạo topics cho domain "${domain.name}":`, error.message);
          }
        }
      } catch (error) {
        console.error(`   ❌ Lỗi khi xử lý subject "${subject.name}":`, error.message);
      }
    }

    console.log('\n' + '═'.repeat(60));
    console.log(`✅ Hoàn thành! Đã tạo tổng cộng ${totalCreated} topics cho các domains thiếu`);
  } catch (error) {
    console.error('❌ Lỗi:', error);
  } finally {
    await app.close();
  }
}

createTopicsForDomains().catch(console.error);

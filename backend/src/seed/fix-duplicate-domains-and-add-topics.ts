/**
 * Script sửa các domain trùng và tạo topics cho domain thiếu
 * 
 * CÁCH SỬ DỤNG:
 * npx ts-node src/seed/fix-duplicate-domains-and-add-topics.ts
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
import { DataSource } from 'typeorm';
import { KnowledgeNode } from '../knowledge-graph/entities/knowledge-node.entity';
import { KnowledgeEdge } from '../knowledge-graph/entities/knowledge-edge.entity';

async function fixDuplicateDomainsAndAddTopics() {
  const app = await NestFactory.createApplicationContext(AppModule);
  const subjectsService = app.select(SubjectsModule).get(SubjectsService);
  const kgService = app.select(KnowledgeGraphModule).get(KnowledgeGraphService);
  const aiService = app.select(AiModule).get(AiService);
  const dataSource = app.get(DataSource);
  const knowledgeNodeRepo = dataSource.getRepository(KnowledgeNode);
  const knowledgeEdgeRepo = dataSource.getRepository(KnowledgeEdge);

  console.log('🔧 Đang sửa domain trùng và tạo topics cho domain thiếu...\n');

  try {
    const allSubjects = await subjectsService.findByTrack('explorer');
    console.log(`📚 Tìm thấy ${allSubjects.length} môn học\n`);

    let totalDomainsRemoved = 0;
    let totalTopicsCreated = 0;

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

        console.log(`   📊 Ban đầu: ${domainNodes.length} domains, ${topicNodes.length} topics`);

        // Bước 1: Xử lý domain trùng
        // Normalize domain name để tìm trùng (loại bỏ tiền tố "Microsoft", "Lập", v.v.)
        const normalizeDomainName = (name: string): string => {
          let normalized = name.toLowerCase().trim();
          // Loại bỏ các tiền tố phổ biến
          normalized = normalized.replace(/^(microsoft\s+|ms\s+|lập\s+|quản\s+lý\s+|chăm\s+sóc\s+|sử\s+dụng\s+|kỹ\s+năng\s+)/i, '');
          // Loại bỏ các hậu tố
          normalized = normalized.replace(/\s+(cơ\s+bản|nâng\s+cao|chuyên\s+nghiệp)$/i, '');
          // Loại bỏ dấu câu đặc biệt và từ khóa không quan trọng
          normalized = normalized.replace(/[-\–]/g, ' ').replace(/\s+/g, ' ').trim();
          // Xử lý các trường hợp đặc biệt: "word - soạn thảo văn bản" -> "word"
          normalized = normalized.replace(/\s*-\s*.*$/, '');
          // Xử lý các từ đồng nghĩa (tiếng Anh <-> tiếng Việt)
          const synonyms: { [key: string]: string } = {
            // Office
            'word': 'word',
            'excel': 'excel',
            'powerpoint': 'powerpoint',
            'soạn thảo văn bản': 'word',
            'bảng tính': 'excel',
            'trình chiếu': 'powerpoint',
            'văn phòng': 'văn phòng',
            'ngân sách': 'ngân sách',
            'kế hoạch tài chính': 'kế hoạch tài chính',
            // Skincare
            'understanding skin': 'hiểu về loại da',
            'hiểu về loại da': 'hiểu về loại da',
            'skincare products': 'sản phẩm chăm sóc da',
            'sản phẩm chăm sóc da': 'sản phẩm chăm sóc da',
            'skincare routine': 'quy trình skincare',
            'quy trình skincare': 'quy trình skincare',
            'advanced techniques': 'kỹ thuật nâng cao',
            'lifestyle factors': 'yếu tố lối sống',
          };
          for (const [synonym, base] of Object.entries(synonyms)) {
            if (normalized.includes(synonym) || normalized === synonym) {
              normalized = base;
              break;
            }
          }
          return normalized;
        };

        const domainMap = new Map<string, KnowledgeNode[]>();
        domainNodes.forEach(domain => {
          const key = normalizeDomainName(domain.name);
          if (!domainMap.has(key)) {
            domainMap.set(key, []);
          }
          domainMap.get(key)!.push(domain);
        });

        const duplicateGroups = Array.from(domainMap.entries()).filter(([_, domains]) => domains.length > 1);
        
        if (duplicateGroups.length > 0) {
          console.log(`   ⚠️  Tìm thấy ${duplicateGroups.length} nhóm domain trùng:`);
          
          for (const [name, domains] of duplicateGroups) {
            console.log(`      - "${name}": ${domains.length} domains trùng`);
            
            // Giữ domain đầu tiên, merge topics của các domain còn lại vào domain đầu tiên
            const keepDomain = domains[0];
            const removeDomains = domains.slice(1);
            
            for (const removeDomain of removeDomains) {
              // Tìm tất cả topics của domain bị xóa
              const topicsToMove = mindMap.edges
                .filter(e => e.fromNodeId === removeDomain.id && e.type === EdgeType.PART_OF)
                .map(e => mindMap.nodes.find(n => n.id === e.toNodeId))
                .filter(Boolean) as KnowledgeNode[];
              
              // Di chuyển topics sang domain giữ lại
              for (const topic of topicsToMove) {
                // Xóa edge cũ
                const oldEdge = mindMap.edges.find(e => 
                  e.fromNodeId === removeDomain.id && 
                  e.toNodeId === topic.id && 
                  e.type === EdgeType.PART_OF
                );
                if (oldEdge) {
                  await knowledgeEdgeRepo.delete(oldEdge.id);
                  mindMap.edges = mindMap.edges.filter(e => e.id !== oldEdge.id);
                }
                
                // Kiểm tra xem đã có edge từ keepDomain đến topic chưa
                const existingEdge = mindMap.edges.find(e => 
                  e.fromNodeId === keepDomain.id && 
                  e.toNodeId === topic.id && 
                  e.type === EdgeType.PART_OF
                );
                
                if (!existingEdge) {
                  // Tạo edge mới
                  await kgService.createEdge(
                    keepDomain.id,
                    topic.id,
                    EdgeType.PART_OF,
                    {
                      description: `${topic.name} là phần của ${keepDomain.name}`,
                      weight: 1.0,
                    },
                  );
                  console.log(`         ✅ Đã di chuyển topic "${topic.name}" sang domain "${keepDomain.name}"`);
                }
              }
              
              // Xóa tất cả edges liên quan đến domain trùng trước khi xóa node
              const edgesToDelete = await knowledgeEdgeRepo.find({
                where: [
                  { fromNodeId: removeDomain.id },
                  { toNodeId: removeDomain.id },
                ],
              });
              
              if (edgesToDelete.length > 0) {
                await knowledgeEdgeRepo.remove(edgesToDelete);
              }
              
              // Xóa domain node
              await knowledgeNodeRepo.delete(removeDomain.id);
              console.log(`         🗑️  Đã xóa domain trùng: "${removeDomain.name}"`);
              totalDomainsRemoved++;
            }
          }
        } else {
          console.log(`   ✅ Không có domain trùng`);
        }

        // Bước 2: Tạo topics cho domain thiếu (sau khi đã xóa trùng)
        // Refresh mind map
        const updatedMindMap = await kgService.getMindMapForSubject(subject.id);
        const updatedDomainNodes = updatedMindMap.nodes.filter(n => n.type === NodeType.DOMAIN);
        
        const domainsWithoutTopics = updatedDomainNodes.filter(domain => {
          const hasTopics = updatedMindMap.edges.some(e => 
            e.fromNodeId === domain.id && e.type === EdgeType.PART_OF
          );
          return !hasTopics;
        });

        if (domainsWithoutTopics.length > 0) {
          console.log(`   ⚠️  Tìm thấy ${domainsWithoutTopics.length} domains không có topics:`);
          domainsWithoutTopics.forEach(d => console.log(`      - ${d.name}`));

          for (const domain of domainsWithoutTopics) {
            try {
              console.log(`\n   🎯 Đang tạo topics cho domain "${domain.name}"...`);

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

              let topicsData: Array<{ name: string; description: string }> = [];
              try {
                const jsonMatch = aiResponse.match(/\[[\s\S]*\]/);
                if (jsonMatch) {
                  topicsData = JSON.parse(jsonMatch[0]);
                } else {
                  topicsData = JSON.parse(aiResponse);
                }
              } catch (parseError) {
                console.error(`      ❌ Lỗi parse JSON, dùng topics mặc định`);
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

              for (const topicData of topicsData) {
                const entityId = `${subject.id}_${domain.name}_${topicData.name}_${Date.now()}`;
                
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
                totalTopicsCreated++;
              }
            } catch (error) {
              console.error(`      ❌ Lỗi khi tạo topics cho domain "${domain.name}":`, error.message);
            }
          }
        } else {
          console.log(`   ✅ Tất cả domains đều có topics`);
        }

        // Bước 3: Báo cáo cuối cùng
        const finalMindMap = await kgService.getMindMapForSubject(subject.id);
        const finalDomainNodes = finalMindMap.nodes.filter(n => n.type === NodeType.DOMAIN);
        const finalTopicNodes = finalMindMap.nodes.filter(n => {
          const isConcept = n.type === NodeType.CONCEPT;
          const originalType = (n.metadata as any)?.originalType;
          return isConcept && (originalType === 'topic' || originalType === 'concept');
        });
        const finalDomainsWithTopics = finalDomainNodes.filter(domain => {
          return finalMindMap.edges.some(e => 
            e.fromNodeId === domain.id && e.type === EdgeType.PART_OF
          );
        }).length;

        console.log(`\n   📊 Kết quả: ${finalDomainNodes.length} domains, ${finalTopicNodes.length} topics, ${finalDomainsWithTopics}/${finalDomainNodes.length} domains có topics`);
      } catch (error) {
        console.error(`   ❌ Lỗi khi xử lý subject "${subject.name}":`, error.message);
      }
    }

    console.log('\n' + '═'.repeat(60));
    console.log(`✅ Hoàn thành!`);
    console.log(`   🗑️  Đã xóa ${totalDomainsRemoved} domains trùng`);
    console.log(`   🎯 Đã tạo ${totalTopicsCreated} topics mới`);
  } catch (error) {
    console.error('❌ Lỗi:', error);
  } finally {
    await app.close();
  }
}

fixDuplicateDomainsAndAddTopics().catch(console.error);

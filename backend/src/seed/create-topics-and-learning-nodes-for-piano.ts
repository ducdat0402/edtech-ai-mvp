/**
 * Script tạo topics cho các domains chưa có topics trong môn Piano,
 * sau đó tạo learning nodes cho tất cả các topics mới
 * 
 * CÁCH SỬ DỤNG:
 * npx ts-node src/seed/create-topics-and-learning-nodes-for-piano.ts
 */

import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module';
import { SubjectsModule } from '../subjects/subjects.module';
import { SubjectsService } from '../subjects/subjects.service';
import { KnowledgeGraphModule } from '../knowledge-graph/knowledge-graph.module';
import { KnowledgeGraphService } from '../knowledge-graph/knowledge-graph.service';
import { LearningNodesModule } from '../learning-nodes/learning-nodes.module';
import { LearningNodesService } from '../learning-nodes/learning-nodes.service';
import { AiModule } from '../ai/ai.module';
import { AiService } from '../ai/ai.service';
import { NodeType } from '../knowledge-graph/entities/knowledge-node.entity';
import { EdgeType } from '../knowledge-graph/entities/knowledge-edge.entity';

async function createTopicsAndLearningNodesForPiano() {
  const app = await NestFactory.createApplicationContext(AppModule);
  const subjectsService = app.select(SubjectsModule).get(SubjectsService);
  const kgService = app.select(KnowledgeGraphModule).get(KnowledgeGraphService);
  const nodesService = app.select(LearningNodesModule).get(LearningNodesService);
  const aiService = app.select(AiModule).get(AiService);

  console.log('🎹 Đang tạo topics và learning nodes cho các domains chưa có topics trong môn Piano...\n');

  try {
    // Tìm môn Piano
    const allSubjects = await subjectsService.findByTrack('explorer');
    const pianoSubject = allSubjects.find(s => s.name === 'Piano');

    if (!pianoSubject) {
      console.log('❌ Không tìm thấy môn Piano');
      await app.close();
      return;
    }

    console.log(`📖 Môn: ${pianoSubject.name} (ID: ${pianoSubject.id})\n`);

    // Lấy mind map
    const mindMap = await kgService.getMindMapForSubject(pianoSubject.id);

    // Tìm các domains chưa có topics
    const domains = mindMap.nodes.filter(n => n.type === NodeType.DOMAIN);
    const domainsWithoutTopics: typeof domains = [];

    for (const domain of domains) {
      const topicEdges = mindMap.edges.filter(
        e => e.fromNodeId === domain.id && e.type === EdgeType.PART_OF
      );
      if (topicEdges.length === 0) {
        domainsWithoutTopics.push(domain);
      }
    }

    if (domainsWithoutTopics.length === 0) {
      console.log('✅ Tất cả domains đều đã có topics!');
      await app.close();
      return;
    }

    console.log(`📚 Tìm thấy ${domainsWithoutTopics.length} domains chưa có topics:\n`);
    domainsWithoutTopics.forEach(d => console.log(`   - ${d.name}`));

    let totalNewTopicsCreated = 0;
    const newTopicNodes: any[] = [];

    // Tạo topics cho mỗi domain
    for (const domain of domainsWithoutTopics) {
      try {
        console.log(`\n🎯 Đang tạo topics cho domain "${domain.name}"...`);

        const topicsPrompt = `Bạn là một chuyên gia giáo dục về Piano. Hãy tạo 3 topics (chủ đề học tập) chi tiết cho domain "${domain.name}" trong môn học Piano.

Yêu cầu:
- Mỗi topic phải là một chủ đề học tập cụ thể và thực tế về Piano
- Topics phải liên quan trực tiếp đến domain "${domain.name}"
- Mỗi topic cần có tên ngắn gọn (2-5 từ) và mô tả chi tiết (1-2 câu)
- Topics phải phù hợp với việc học Piano từ cơ bản đến nâng cao

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
            content: 'Bạn là một chuyên gia giáo dục về Piano. Trả về JSON hợp lệ, không có markdown formatting.',
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
            // Try to parse the whole response
            topicsData = JSON.parse(aiResponse);
          }
        } catch (parseError) {
          console.error(`   ⚠️  Lỗi parse JSON response:`, parseError);
          console.error(`   Response:`, aiResponse.substring(0, 200));
          continue;
        }

        if (!Array.isArray(topicsData) || topicsData.length === 0) {
          console.error(`   ⚠️  Không tạo được topics cho domain "${domain.name}"`);
          continue;
        }

        // Tạo topic nodes trong knowledge graph
        for (const topicData of topicsData) {
          const topicNode = await kgService.createOrUpdateNode(
            topicData.name,
            NodeType.CONCEPT,
            `${pianoSubject.id}_${domain.id}_${topicData.name}`,
            {
              description: topicData.description,
              metadata: {
                subjectId: pianoSubject.id,
                subjectName: pianoSubject.name,
                domainId: domain.id,
                domainName: domain.name,
                originalType: 'topic',
              },
            }
          );

          // Tạo edge từ domain đến topic
          await kgService.createEdge(domain.id, topicNode.id, EdgeType.PART_OF, {
            description: `Topic of ${domain.name}`,
          });

          newTopicNodes.push({
            node: topicNode,
            domainName: domain.name,
          });

          totalNewTopicsCreated++;
          console.log(`      ✅ Đã tạo topic: "${topicNode.name}"`);
        }
      } catch (error) {
        console.error(`   ❌ Lỗi khi tạo topics cho domain "${domain.name}":`, error.message);
      }
    }

    console.log(`\n✅ Đã tạo ${totalNewTopicsCreated} topics mới cho ${domainsWithoutTopics.length} domains`);

    // Bước 2: Tạo learning nodes cho tất cả topics mới
    if (newTopicNodes.length > 0) {
      console.log(`\n🎓 Đang tạo learning nodes cho ${newTopicNodes.length} topics mới...\n`);

      let generatedCount = 0;
      for (const { node: topicNode, domainName } of newTopicNodes) {
        try {
          // Kiểm tra xem đã có learning nodes cho topic này chưa
          const existingNodes = await nodesService.findByTopicNodeId(topicNode.id);
          if (existingNodes.length > 0) {
            console.log(`   ⏭️  Topic "${topicNode.name}" đã có ${existingNodes.length} learning nodes, bỏ qua...`);
            continue;
          }

          // Tạo learning node cho topic này
          console.log(`   🎯 Đang tạo learning node cho topic "${topicNode.name}"...`);
          await nodesService.generateSingleLearningNodeFromTopic(
            pianoSubject.id,
            topicNode.id,
            topicNode.name,
            topicNode.description || `Bài học về ${topicNode.name}`,
            pianoSubject.name,
            pianoSubject.description,
            domainName,
            1, // Order sẽ được skill tree quản lý sau
          );

          generatedCount++;
          console.log(`   ✅ Đã tạo learning node cho topic "${topicNode.name}"`);
        } catch (error) {
          console.error(`   ❌ Lỗi khi tạo learning node cho topic "${topicNode.name}":`, error.message);
        }
      }

      console.log(`\n✅ Đã tạo ${generatedCount} learning nodes cho ${newTopicNodes.length} topics mới`);
    }

    // Tổng kết
    console.log('\n' + '═'.repeat(60));
    console.log('📊 Tổng kết:');
    console.log(`   📚 Domains được xử lý: ${domainsWithoutTopics.length}`);
    console.log(`   📝 Topics mới được tạo: ${totalNewTopicsCreated}`);
    console.log(`   🎓 Learning nodes mới được tạo: ${newTopicNodes.length > 0 ? newTopicNodes.length : 0}`);
    console.log('═'.repeat(60));

  } catch (error) {
    console.error('❌ Lỗi:', error);
  } finally {
    await app.close();
  }
}

createTopicsAndLearningNodesForPiano().catch(console.error);

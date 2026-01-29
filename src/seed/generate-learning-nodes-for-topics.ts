/**
 * Script tạo learning nodes cho tất cả topics hiện có mà chưa có learning nodes
 * Script này KHÔNG xóa subjects, chỉ tạo learning nodes cho các topics chưa có
 * 
 * CÁCH SỬ DỤNG:
 * npx ts-node src/seed/generate-learning-nodes-for-topics.ts
 */

import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module';
import { SubjectsModule } from '../subjects/subjects.module';
import { SubjectsService } from '../subjects/subjects.service';
import { KnowledgeGraphModule } from '../knowledge-graph/knowledge-graph.module';
import { KnowledgeGraphService } from '../knowledge-graph/knowledge-graph.service';
import { LearningNodesModule } from '../learning-nodes/learning-nodes.module';
import { LearningNodesService } from '../learning-nodes/learning-nodes.service';
import { NodeType } from '../knowledge-graph/entities/knowledge-node.entity';
import { EdgeType } from '../knowledge-graph/entities/knowledge-edge.entity';
import { DataSource } from 'typeorm';
import { Subject } from '../subjects/entities/subject.entity';

async function generateLearningNodesForAllTopics() {
  const app = await NestFactory.createApplicationContext(AppModule);
  const subjectsService = app.select(SubjectsModule).get(SubjectsService);
  const kgService = app.select(KnowledgeGraphModule).get(KnowledgeGraphService);
  const nodesService = app.select(LearningNodesModule).get(LearningNodesService);
  const dataSource = app.get(DataSource);
  const subjectRepo = dataSource.getRepository(Subject);

  console.log('🎓 Bắt đầu tạo learning nodes cho tất cả topics...\n');

  try {
    // Lấy tất cả subjects
    const subjects = await subjectRepo.find();
    console.log(`📚 Tìm thấy ${subjects.length} subjects\n`);

    let totalGenerated = 0;
    let totalSkipped = 0;

    for (const subject of subjects) {
      console.log(`\n📖 Subject: ${subject.name} (ID: ${subject.id})`);
      console.log('─'.repeat(60));

      try {
        // Lấy mind map cho subject này
        const allKgNodes = await kgService.getMindMapForSubject(subject.id);
        
        if (allKgNodes.nodes.length === 0) {
          console.log(`   ⚠️  Không có mind map nodes cho subject này`);
          continue;
        }

        // Debug: In ra tất cả nodes
        console.log(`   🔍 Tổng số nodes trong mind map: ${allKgNodes.nodes.length}`);
        
        // Filter topic nodes: Loại bỏ SUBJECT và DOMAIN, chỉ lấy CONCEPT với originalType là 'topic' hoặc 'concept'
        const topicNodes = allKgNodes.nodes.filter(node => {
          const isConcept = node.type === NodeType.CONCEPT;
          const originalType = (node.metadata as any)?.originalType;
          const isTopic = originalType === 'topic' || originalType === 'concept';
          // Loại bỏ nodes là subject hoặc domain
          const isNotSubjectOrDomain = originalType !== 'subject' && originalType !== 'domain';
          return isConcept && isTopic && isNotSubjectOrDomain;
        });

        console.log(`   📝 Tìm thấy ${topicNodes.length} topics`);

        if (topicNodes.length === 0) {
          console.log(`   ⚠️  Không có topics nào để tạo learning nodes`);
          continue;
        }

        let generatedCount = 0;
        let skippedCount = 0;

        for (const topicNode of topicNodes) {
          try {
            // Kiểm tra xem đã có learning nodes cho topic này chưa
            const existingNodes = await nodesService.findByTopicNodeId(topicNode.id);
            if (existingNodes.length > 0) {
              console.log(`   ⏭️  Topic "${topicNode.name}" đã có ${existingNodes.length} learning nodes, bỏ qua...`);
              skippedCount++;
              continue;
            }

            // Tìm domain của topic này
            const domainEdges = allKgNodes.edges.filter(e => 
              e.toNodeId === topicNode.id && e.type === EdgeType.PART_OF
            );
            const domainNodeId = domainEdges.length > 0 ? domainEdges[0].fromNodeId : null;
            const domainNode = domainNodeId ? allKgNodes.nodes.find(n => n.id === domainNodeId) : null;
            const domainName = domainNode?.name;

            // Tạo learning node cho topic này
            console.log(`   🎯 Đang tạo learning node cho topic "${topicNode.name}"...`);
            await nodesService.generateSingleLearningNodeFromTopic(
              subject.id,
              topicNode.id,
              topicNode.name,
              topicNode.description || `Bài học về ${topicNode.name}`,
              subject.name,
              subject.description,
              domainName,
              1, // Order sẽ được skill tree quản lý sau
            );

            generatedCount++;
            console.log(`   ✅ Đã tạo learning node cho topic "${topicNode.name}"`);
          } catch (error) {
            console.error(`   ❌ Lỗi khi tạo learning node cho topic "${topicNode.name}":`, error.message);
          }
        }

        console.log(`   ✅ Hoàn thành: Tạo ${generatedCount} learning nodes, bỏ qua ${skippedCount} topics đã có`);
        totalGenerated += generatedCount;
        totalSkipped += skippedCount;
      } catch (error) {
        console.error(`   ❌ Lỗi khi xử lý subject "${subject.name}":`, error.message);
      }
    }

    console.log('\n' + '═'.repeat(60));
    console.log(`✅ Hoàn thành!`);
    console.log(`   📊 Tổng số learning nodes đã tạo: ${totalGenerated}`);
    console.log(`   ⏭️  Tổng số topics đã bỏ qua (đã có learning nodes): ${totalSkipped}`);
  } catch (error) {
    console.error('❌ Lỗi:', error);
  } finally {
    await app.close();
  }
}

generateLearningNodesForAllTopics().catch(console.error);

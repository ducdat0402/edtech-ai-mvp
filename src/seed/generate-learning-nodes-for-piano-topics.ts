/**
 * Script tạo learning nodes cho tất cả topics chưa có trong môn Piano
 * 
 * CÁCH SỬ DỤNG:
 * npx ts-node src/seed/generate-learning-nodes-for-piano-topics.ts
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

async function generateLearningNodesForPianoTopics() {
  const app = await NestFactory.createApplicationContext(AppModule);
  const subjectsService = app.select(SubjectsModule).get(SubjectsService);
  const kgService = app.select(KnowledgeGraphModule).get(KnowledgeGraphService);
  const nodesService = app.select(LearningNodesModule).get(LearningNodesService);

  console.log('🎹 Đang tạo learning nodes cho tất cả topics trong môn Piano...\n');

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

    // Filter topic nodes (Level 3 - CONCEPT với originalType = 'topic' hoặc 'concept')
    const topicNodes = mindMap.nodes.filter(node => {
      const isConcept = node.type === NodeType.CONCEPT;
      const originalType = (node.metadata as any)?.originalType;
      const isTopic = originalType === 'topic' || originalType === 'concept';
      const isNotSubjectOrDomain = originalType !== 'subject' && originalType !== 'domain';
      return isConcept && isTopic && isNotSubjectOrDomain;
    });

    console.log(`📝 Tìm thấy ${topicNodes.length} topics\n`);

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
        const domainEdges = mindMap.edges.filter(e => 
          e.toNodeId === topicNode.id && e.type === EdgeType.PART_OF
        );
        const domainNodeId = domainEdges.length > 0 ? domainEdges[0].fromNodeId : null;
        const domainNode = domainNodeId ? mindMap.nodes.find(n => n.id === domainNodeId) : null;
        const domainName = domainNode?.name;

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

    console.log('\n' + '═'.repeat(60));
    console.log('✅ Hoàn thành!');
    console.log(`   🎯 Đã tạo: ${generatedCount} learning nodes mới`);
    console.log(`   ⏭️  Bỏ qua: ${skippedCount} topics đã có learning nodes`);
    console.log(`   📝 Tổng cộng: ${topicNodes.length} topics`);
    console.log('═'.repeat(60));

  } catch (error) {
    console.error('❌ Lỗi:', error);
  } finally {
    await app.close();
  }
}

generateLearningNodesForPianoTopics().catch(console.error);

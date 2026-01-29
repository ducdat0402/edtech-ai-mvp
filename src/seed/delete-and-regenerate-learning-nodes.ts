/**
 * Script xóa tất cả learning nodes và content items, sau đó tạo lại với cấu trúc mới
 * (chỉ 1 phần thưởng thay vì 3-5)
 * 
 * CÁCH SỬ DỤNG:
 * npx ts-node src/seed/delete-and-regenerate-learning-nodes.ts
 */

import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module';
import { DataSource } from 'typeorm';
import { LearningNode } from '../learning-nodes/entities/learning-node.entity';
import { ContentItem } from '../content-items/entities/content-item.entity';
import { ContentEdit } from '../content-edits/entities/content-edit.entity';
import { ContentVersion } from '../content-edits/entities/content-version.entity';
import { EditHistory } from '../content-edits/entities/edit-history.entity';
import { UserProgress } from '../user-progress/entities/user-progress.entity';
import { SkillNode } from '../skill-tree/entities/skill-node.entity';
import { UserSkillProgress } from '../skill-tree/entities/user-skill-progress.entity';
import { KnowledgeGraphModule } from '../knowledge-graph/knowledge-graph.module';
import { KnowledgeGraphService } from '../knowledge-graph/knowledge-graph.service';
import { LearningNodesModule } from '../learning-nodes/learning-nodes.module';
import { LearningNodesService } from '../learning-nodes/learning-nodes.service';
import { SubjectsModule } from '../subjects/subjects.module';
import { SubjectsService } from '../subjects/subjects.service';
import { NodeType } from '../knowledge-graph/entities/knowledge-node.entity';
import { EdgeType } from '../knowledge-graph/entities/knowledge-edge.entity';

async function deleteAndRegenerateLearningNodes() {
  const app = await NestFactory.createApplicationContext(AppModule);
  const dataSource = app.get(DataSource);
  
  const learningNodeRepo = dataSource.getRepository(LearningNode);
  const contentItemRepo = dataSource.getRepository(ContentItem);
  const contentEditRepo = dataSource.getRepository(ContentEdit);
  const contentVersionRepo = dataSource.getRepository(ContentVersion);
  const editHistoryRepo = dataSource.getRepository(EditHistory);
  const userProgressRepo = dataSource.getRepository(UserProgress);
  const skillNodeRepo = dataSource.getRepository(SkillNode);
  const userSkillProgressRepo = dataSource.getRepository(UserSkillProgress);
  
  const kgService = app.select(KnowledgeGraphModule).get(KnowledgeGraphService);
  const nodesService = app.select(LearningNodesModule).get(LearningNodesService);
  const subjectsService = app.select(SubjectsModule).get(SubjectsService);

  console.log('🗑️  Bắt đầu xóa tất cả learning nodes và content items...\n');

  try {
    // 1. Xóa edit history (có foreign key đến ContentItem)
    const allEditHistory = await editHistoryRepo.find();
    if (allEditHistory.length > 0) {
      await editHistoryRepo.remove(allEditHistory);
      console.log(`✅ Đã xóa ${allEditHistory.length} edit history records`);
    }

    // 2. Xóa content versions (có foreign key đến ContentItem)
    const allContentVersions = await contentVersionRepo.find();
    if (allContentVersions.length > 0) {
      await contentVersionRepo.remove(allContentVersions);
      console.log(`✅ Đã xóa ${allContentVersions.length} content versions`);
    }

    // 3. Xóa content edits (có foreign key đến ContentItem)
    const allContentEdits = await contentEditRepo.find();
    if (allContentEdits.length > 0) {
      await contentEditRepo.remove(allContentEdits);
      console.log(`✅ Đã xóa ${allContentEdits.length} content edits`);
    }

    // 4. Xóa content items
    const allContentItems = await contentItemRepo.find();
    if (allContentItems.length > 0) {
      await contentItemRepo.remove(allContentItems);
      console.log(`✅ Đã xóa ${allContentItems.length} content items`);
    } else {
      console.log('   ⏭️  Không có content items để xóa');
    }

    // 5. Xóa user progress (có foreign key đến LearningNode)
    const allUserProgress = await userProgressRepo.find();
    if (allUserProgress.length > 0) {
      await userProgressRepo.remove(allUserProgress);
      console.log(`✅ Đã xóa ${allUserProgress.length} user progress records`);
    }

    // 6. Xóa user skill progress (có foreign key đến SkillNode)
    const allUserSkillProgress = await userSkillProgressRepo.find();
    if (allUserSkillProgress.length > 0) {
      await userSkillProgressRepo.remove(allUserSkillProgress);
      console.log(`✅ Đã xóa ${allUserSkillProgress.length} user skill progress records`);
    }

    // 7. Xóa skill nodes (có foreign key đến LearningNode)
    const allSkillNodes = await skillNodeRepo.find();
    if (allSkillNodes.length > 0) {
      await skillNodeRepo.remove(allSkillNodes);
      console.log(`✅ Đã xóa ${allSkillNodes.length} skill nodes`);
    }

    // 8. Xóa learning nodes
    const allLearningNodes = await learningNodeRepo.find();
    if (allLearningNodes.length > 0) {
      await learningNodeRepo.remove(allLearningNodes);
      console.log(`✅ Đã xóa ${allLearningNodes.length} learning nodes`);
    } else {
      console.log('   ⏭️  Không có learning nodes để xóa');
    }

    console.log('\n✅ Hoàn thành xóa dữ liệu cũ!\n');
    console.log('🌱 Bắt đầu tạo lại learning nodes với cấu trúc mới...\n');

    // 3. Lấy tất cả subjects
    const subjects = await subjectsService.findByTrack('explorer');
    console.log(`📚 Tìm thấy ${subjects.length} subjects\n`);

    let totalGenerated = 0;

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

        // Filter topic nodes
        const topicNodes = allKgNodes.nodes.filter(node => {
          const isConcept = node.type === NodeType.CONCEPT;
          const originalType = (node.metadata as any)?.originalType;
          const isTopic = originalType === 'topic' || originalType === 'concept';
          const isNotSubjectOrDomain = originalType !== 'subject' && originalType !== 'domain';
          return isConcept && isTopic && isNotSubjectOrDomain;
        });

        console.log(`   📝 Tìm thấy ${topicNodes.length} topics`);

        if (topicNodes.length === 0) {
          console.log(`   ⚠️  Không có topics nào để tạo learning nodes`);
          continue;
        }

        let generatedCount = 0;

        for (const topicNode of topicNodes) {
          try {
            // Tìm domain của topic này
            const domainEdges = allKgNodes.edges.filter(e => 
              e.toNodeId === topicNode.id && e.type === EdgeType.PART_OF
            );
            const domainNodeId = domainEdges.length > 0 ? domainEdges[0].fromNodeId : null;
            const domainNode = domainNodeId ? allKgNodes.nodes.find(n => n.id === domainNodeId) : null;
            const domainName = domainNode?.name;

            // Tạo learning node cho topic này (với cấu trúc mới: chỉ 1 phần thưởng)
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

        console.log(`   ✅ Hoàn thành: Tạo ${generatedCount} learning nodes`);
        totalGenerated += generatedCount;
      } catch (error) {
        console.error(`   ❌ Lỗi khi xử lý subject "${subject.name}":`, error.message);
      }
    }

    console.log('\n' + '═'.repeat(60));
    console.log(`✅ Hoàn thành!`);
    console.log(`   📊 Tổng số learning nodes đã tạo: ${totalGenerated}`);
    console.log(`\n📝 Cấu trúc mới: Mỗi node có:`);
    console.log(`   - Concepts (khái niệm)`);
    console.log(`   - Examples (ví dụ)`);
    console.log(`   - 1 Hidden Reward (phần thưởng)`);
    console.log(`   - 1 Boss Quiz (quiz)`);
  } catch (error) {
    console.error('❌ Lỗi:', error);
  } finally {
    await app.close();
  }
}

deleteAndRegenerateLearningNodes().catch(console.error);

/**
 * Script xóa tất cả các môn học có tên chứa "IC3" và tất cả dữ liệu liên quan
 * 
 * CÁCH SỬ DỤNG:
 * npx ts-node src/seed/delete-ic3-subjects.ts
 */

import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module';
import { DataSource } from 'typeorm';
import { Subject } from '../subjects/entities/subject.entity';
import { LearningNode } from '../learning-nodes/entities/learning-node.entity';
import { ContentItem } from '../content-items/entities/content-item.entity';
import { ContentEdit } from '../content-edits/entities/content-edit.entity';
import { ContentVersion } from '../content-edits/entities/content-version.entity';
import { EditHistory } from '../content-edits/entities/edit-history.entity';
import { UserProgress } from '../user-progress/entities/user-progress.entity';
import { SkillNode } from '../skill-tree/entities/skill-node.entity';
import { UserSkillProgress } from '../skill-tree/entities/user-skill-progress.entity';
import { KnowledgeNode } from '../knowledge-graph/entities/knowledge-node.entity';
import { KnowledgeEdge } from '../knowledge-graph/entities/knowledge-edge.entity';
import { Domain } from '../domains/entities/domain.entity';
import { PlacementTest } from '../placement-test/entities/placement-test.entity';
import { Question } from '../placement-test/entities/question.entity';
import { In } from 'typeorm';

async function deleteIC3Subjects() {
  const app = await NestFactory.createApplicationContext(AppModule);
  const dataSource = app.get(DataSource);
  
  const subjectRepo = dataSource.getRepository(Subject);
  const learningNodeRepo = dataSource.getRepository(LearningNode);
  const contentItemRepo = dataSource.getRepository(ContentItem);
  const contentEditRepo = dataSource.getRepository(ContentEdit);
  const contentVersionRepo = dataSource.getRepository(ContentVersion);
  const editHistoryRepo = dataSource.getRepository(EditHistory);
  const userProgressRepo = dataSource.getRepository(UserProgress);
  const skillNodeRepo = dataSource.getRepository(SkillNode);
  const userSkillProgressRepo = dataSource.getRepository(UserSkillProgress);
  const knowledgeNodeRepo = dataSource.getRepository(KnowledgeNode);
  const knowledgeEdgeRepo = dataSource.getRepository(KnowledgeEdge);
  const domainRepo = dataSource.getRepository(Domain);
  const placementTestRepo = dataSource.getRepository(PlacementTest);
  const questionRepo = dataSource.getRepository(Question);

  console.log('🔍 Đang tìm các môn học có tên chứa "IC3"...\n');

  try {
    // Tìm tất cả subjects có tên chứa "IC3" (case-insensitive)
    const ic3Subjects = await subjectRepo
      .createQueryBuilder('subject')
      .where('LOWER(subject.name) LIKE LOWER(:name)', { name: '%IC3%' })
      .getMany();

    if (ic3Subjects.length === 0) {
      console.log('✅ Không tìm thấy môn học nào có tên chứa "IC3"');
      await app.close();
      return;
    }

    console.log(`📚 Tìm thấy ${ic3Subjects.length} môn học có tên chứa "IC3":`);
    ic3Subjects.forEach(subject => {
      console.log(`   - ${subject.name} (ID: ${subject.id})`);
    });
    console.log('\n🗑️  Bắt đầu xóa dữ liệu...\n');

    const subjectIds = ic3Subjects.map(s => s.id);

    // 1. Xóa edit history liên quan đến content items của các learning nodes này
    const learningNodes = await learningNodeRepo.find({
      where: { subjectId: In(subjectIds) },
    });
    const learningNodeIds = learningNodes.map(n => n.id);
    
    if (learningNodeIds.length > 0) {
      const contentItems = await contentItemRepo.find({
        where: { nodeId: In(learningNodeIds) },
      });
      const contentItemIds = contentItems.map(i => i.id);

      if (contentItemIds.length > 0) {
        // Xóa edit history
        const editHistoryToDelete = await editHistoryRepo.find({
          where: { contentItemId: In(contentItemIds) },
        });
        if (editHistoryToDelete.length > 0) {
          await editHistoryRepo.remove(editHistoryToDelete);
          console.log(`✅ Đã xóa ${editHistoryToDelete.length} edit history records`);
        }

        // Xóa content versions
        const contentVersionsToDelete = await contentVersionRepo.find({
          where: { contentItemId: In(contentItemIds) },
        });
        if (contentVersionsToDelete.length > 0) {
          await contentVersionRepo.remove(contentVersionsToDelete);
          console.log(`✅ Đã xóa ${contentVersionsToDelete.length} content versions`);
        }

        // Xóa content edits
        const contentEditsToDelete = await contentEditRepo.find({
          where: { contentItemId: In(contentItemIds) },
        });
        if (contentEditsToDelete.length > 0) {
          await contentEditRepo.remove(contentEditsToDelete);
          console.log(`✅ Đã xóa ${contentEditsToDelete.length} content edits`);
        }

        // Xóa content items
        await contentItemRepo.remove(contentItems);
        console.log(`✅ Đã xóa ${contentItems.length} content items`);
      }
    }

    // 2. Xóa user progress
    if (learningNodeIds.length > 0) {
      const userProgressToDelete = await userProgressRepo.find({
        where: { nodeId: In(learningNodeIds) },
      });
      if (userProgressToDelete.length > 0) {
        await userProgressRepo.remove(userProgressToDelete);
        console.log(`✅ Đã xóa ${userProgressToDelete.length} user progress records`);
      }
    }

    // 3. Xóa skill nodes và user skill progress
    const skillNodes = await skillNodeRepo.find({
      where: { learningNodeId: In(learningNodeIds) },
    });
    const skillNodeIds = skillNodes.map(n => n.id);

    if (skillNodeIds.length > 0) {
      const userSkillProgressToDelete = await userSkillProgressRepo.find({
        where: { skillNodeId: In(skillNodeIds) },
      });
      if (userSkillProgressToDelete.length > 0) {
        await userSkillProgressRepo.remove(userSkillProgressToDelete);
        console.log(`✅ Đã xóa ${userSkillProgressToDelete.length} user skill progress records`);
      }

      await skillNodeRepo.remove(skillNodes);
      console.log(`✅ Đã xóa ${skillNodes.length} skill nodes`);
    }

    // 4. Xóa learning nodes
    if (learningNodes.length > 0) {
      await learningNodeRepo.remove(learningNodes);
      console.log(`✅ Đã xóa ${learningNodes.length} learning nodes`);
    }

    // 5. Xóa knowledge graph edges và nodes
    // Tìm knowledge nodes có entityId chứa subjectId
    const allKnowledgeNodes = await knowledgeNodeRepo.find();
    const knowledgeNodes = allKnowledgeNodes.filter(node => {
      return subjectIds.some(subjectId => node.entityId === subjectId || node.entityId?.includes(subjectId));
    });
    const knowledgeNodeIds = knowledgeNodes.map(n => n.id);

    if (knowledgeNodeIds.length > 0) {
      // Xóa edges
      const edgesToDelete = await knowledgeEdgeRepo
        .createQueryBuilder('edge')
        .where('edge.fromNodeId IN (:...ids) OR edge.toNodeId IN (:...ids)', { ids: knowledgeNodeIds })
        .getMany();
      if (edgesToDelete.length > 0) {
        await knowledgeEdgeRepo.remove(edgesToDelete);
        console.log(`✅ Đã xóa ${edgesToDelete.length} knowledge edges`);
      }

      // Xóa knowledge nodes
      await knowledgeNodeRepo.remove(knowledgeNodes);
      console.log(`✅ Đã xóa ${knowledgeNodes.length} knowledge nodes`);
    }

    // 6. Xóa domains
    const domainsToDelete = await domainRepo.find({
      where: { subjectId: In(subjectIds) },
    });
    if (domainsToDelete.length > 0) {
      await domainRepo.remove(domainsToDelete);
      console.log(`✅ Đã xóa ${domainsToDelete.length} domains`);
    }

    // 7. Xóa placement tests
    const placementTestsToDelete = await placementTestRepo.find({
      where: { subjectId: In(subjectIds) },
    });
    if (placementTestsToDelete.length > 0) {
      await placementTestRepo.remove(placementTestsToDelete);
      console.log(`✅ Đã xóa ${placementTestsToDelete.length} placement tests`);
    }

    // 8. Xóa questions
    const questionsToDelete = await questionRepo.find({
      where: { subjectId: In(subjectIds) },
    });
    if (questionsToDelete.length > 0) {
      await questionRepo.remove(questionsToDelete);
      console.log(`✅ Đã xóa ${questionsToDelete.length} questions`);
    }

    // 9. Xóa roadmaps (nếu còn tồn tại trong database)
    try {
      const roadmapsToDelete = await dataSource.query(
        `DELETE FROM roadmaps WHERE "subjectId" = ANY($1::uuid[])`,
        [subjectIds]
      );
      console.log(`✅ Đã xóa roadmaps (nếu có)`);
    } catch (error) {
      // Bảng roadmaps có thể không tồn tại, bỏ qua
      console.log(`   ⏭️  Bảng roadmaps không tồn tại hoặc đã được xóa`);
    }

    // 10. Xóa subjects
    await subjectRepo.remove(ic3Subjects);
    console.log(`✅ Đã xóa ${ic3Subjects.length} subjects`);

    console.log('\n' + '═'.repeat(60));
    console.log('✅ Hoàn thành xóa tất cả môn học IC3!');
    console.log(`   📊 Đã xóa ${ic3Subjects.length} subject(s)`);
    console.log(`   📊 Đã xóa ${learningNodes.length} learning node(s)`);
    console.log(`   📊 Đã xóa ${domainsToDelete.length} domain(s)`);
    console.log(`   📊 Đã xóa ${knowledgeNodes.length} knowledge node(s)`);
  } catch (error) {
    console.error('❌ Lỗi:', error);
  } finally {
    await app.close();
  }
}

deleteIC3Subjects().catch(console.error);

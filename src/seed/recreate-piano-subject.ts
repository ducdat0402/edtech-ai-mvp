/**
 * Script xóa và tạo lại môn Piano với đầy đủ Learning Nodes cho tất cả topics
 * 
 * CÁCH SỬ DỤNG:
 * npx ts-node src/seed/recreate-piano-subject.ts
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
import { DataSource } from 'typeorm';
import { Subject } from '../subjects/entities/subject.entity';
import { LearningNode } from '../learning-nodes/entities/learning-node.entity';
import { Domain } from '../domains/entities/domain.entity';
import { ContentItem } from '../content-items/entities/content-item.entity';
import { KnowledgeNode } from '../knowledge-graph/entities/knowledge-node.entity';
import { KnowledgeEdge } from '../knowledge-graph/entities/knowledge-edge.entity';
import { SkillTree } from '../skill-tree/entities/skill-tree.entity';
import { SkillNode } from '../skill-tree/entities/skill-node.entity';
import { UserSkillProgress } from '../skill-tree/entities/user-skill-progress.entity';
import { UserProgress } from '../user-progress/entities/user-progress.entity';
import { ContentEdit } from '../content-edits/entities/content-edit.entity';
import { ContentVersion } from '../content-edits/entities/content-version.entity';
import { EditHistory } from '../content-edits/entities/edit-history.entity';
import { PlacementTest } from '../placement-test/entities/placement-test.entity';
import { Question } from '../placement-test/entities/question.entity';

async function recreatePianoSubject() {
  const app = await NestFactory.createApplicationContext(AppModule);
  const subjectsService = app.select(SubjectsModule).get(SubjectsService);
  const kgService = app.select(KnowledgeGraphModule).get(KnowledgeGraphService);
  const nodesService = app.select(LearningNodesModule).get(LearningNodesService);
  const aiService = app.select(AiModule).get(AiService);
  const dataSource = app.get(DataSource);

  // Repositories
  const subjectRepo = dataSource.getRepository(Subject);
  const knowledgeNodeRepo = dataSource.getRepository(KnowledgeNode);
  const knowledgeEdgeRepo = dataSource.getRepository(KnowledgeEdge);
  const learningNodeRepo = dataSource.getRepository(LearningNode);
  const domainRepo = dataSource.getRepository(Domain);
  const contentItemRepo = dataSource.getRepository(ContentItem);
  const skillTreeRepo = dataSource.getRepository(SkillTree);
  const skillNodeRepo = dataSource.getRepository(SkillNode);
  const userSkillProgressRepo = dataSource.getRepository(UserSkillProgress);
  const userProgressRepo = dataSource.getRepository(UserProgress);
  const contentEditRepo = dataSource.getRepository(ContentEdit);
  const contentVersionRepo = dataSource.getRepository(ContentVersion);
  const editHistoryRepo = dataSource.getRepository(EditHistory);
  const placementTestRepo = dataSource.getRepository(PlacementTest);
  const questionRepo = dataSource.getRepository(Question);

  console.log('🎹 Bắt đầu xóa và tạo lại môn Piano...\n');

  try {
    // Bước 1: Tìm môn Piano
    const pianoSubject = await subjectRepo.findOne({ where: { name: 'Piano' } });
    
    if (!pianoSubject) {
      console.log('⚠️  Không tìm thấy môn Piano, sẽ tạo mới');
    } else {
      console.log(`📋 Tìm thấy môn Piano (ID: ${pianoSubject.id})`);
      console.log('🗑️  Đang xóa dữ liệu cũ...\n');

      // Lấy tất cả knowledge nodes của Piano
      const pianoKgNodes = await knowledgeNodeRepo
        .createQueryBuilder('node')
        .where('node.entityId LIKE :pattern', { pattern: `%${pianoSubject.id}%` })
        .orWhere('node.entityId = :subjectId', { subjectId: pianoSubject.id })
        .getMany();
      const kgNodeIds = pianoKgNodes.map(n => n.id);

      // Lấy tất cả learning nodes của Piano
      const pianoLearningNodes = await learningNodeRepo.find({
        where: { subjectId: pianoSubject.id },
      });
      const learningNodeIds = pianoLearningNodes.map(n => n.id);

      // Lấy tất cả domains của Piano
      const pianoDomains = await domainRepo.find({
        where: { subjectId: pianoSubject.id },
      });
      const domainIds = pianoDomains.map(d => d.id);

      // Lấy tất cả skill trees của Piano
      const pianoSkillTrees = await skillTreeRepo.find({
        where: { subjectId: pianoSubject.id },
      });
      const skillTreeIds = pianoSkillTrees.map(st => st.id);

      // Lấy tất cả skill nodes của các skill trees
      const pianoSkillNodes = skillTreeIds.length > 0
        ? await skillNodeRepo.find({
            where: { skillTreeId: skillTreeIds[0] },
          })
        : [];
      const skillNodeIds = pianoSkillNodes.map(sn => sn.id);

      // Xóa theo thứ tự để tránh foreign key constraint
      if (learningNodeIds.length > 0) {
        // Lấy tất cả content items
        const contentItems = await contentItemRepo
          .createQueryBuilder('item')
          .where('item.nodeId IN (:...ids)', { ids: learningNodeIds })
          .getMany();
        const contentItemIds = contentItems.map(ci => ci.id);

        if (contentItemIds.length > 0) {
          // Xóa content edits, versions, history
          await editHistoryRepo.createQueryBuilder().delete().where('contentItemId IN (:...ids)', { ids: contentItemIds }).execute();
          await contentVersionRepo.createQueryBuilder().delete().where('contentItemId IN (:...ids)', { ids: contentItemIds }).execute();
          await contentEditRepo.createQueryBuilder().delete().where('contentItemId IN (:...ids)', { ids: contentItemIds }).execute();
          
          // Xóa content items
          await contentItemRepo.createQueryBuilder().delete().where('id IN (:...ids)', { ids: contentItemIds }).execute();
        }

        // Xóa user progress
        await userProgressRepo.createQueryBuilder().delete().where('nodeId IN (:...ids)', { ids: learningNodeIds }).execute();
      }

      // Xóa user skill progress
      if (skillNodeIds.length > 0) {
        await userSkillProgressRepo.createQueryBuilder().delete().where('skillNodeId IN (:...ids)', { ids: skillNodeIds }).execute();
      }

      // Xóa skill nodes
      if (skillTreeIds.length > 0) {
        await skillNodeRepo.createQueryBuilder().delete().where('skillTreeId IN (:...ids)', { ids: skillTreeIds }).execute();
      }

      // Xóa skill trees
      if (skillTreeIds.length > 0) {
        await skillTreeRepo.delete({ subjectId: pianoSubject.id });
      }

      // Xóa learning nodes
      if (learningNodeIds.length > 0) {
        await learningNodeRepo.delete({ subjectId: pianoSubject.id });
      }

      // Xóa knowledge edges liên quan đến Piano
      if (kgNodeIds.length > 0) {
        await knowledgeEdgeRepo
          .createQueryBuilder()
          .delete()
          .where('fromNodeId IN (:...ids) OR toNodeId IN (:...ids)', { ids: kgNodeIds })
          .execute();
      }

      // Xóa knowledge nodes
      if (kgNodeIds.length > 0) {
        await knowledgeNodeRepo
          .createQueryBuilder()
          .delete()
          .where('id IN (:...ids)', { ids: kgNodeIds })
          .execute();
      }

      // Xóa domains
      await domainRepo.delete({ subjectId: pianoSubject.id });

      // Xóa placement tests
      await placementTestRepo.delete({ subjectId: pianoSubject.id });

      // Xóa questions (có foreign key với subject)
      await questionRepo.delete({ subjectId: pianoSubject.id });

      // Xóa subject
      await subjectRepo.delete({ id: pianoSubject.id });

      console.log('✅ Đã xóa môn Piano và tất cả dữ liệu liên quan\n');
    }

    // Bước 2: Tạo lại môn Piano
    console.log('🎹 Đang tạo lại môn Piano...');
    const newPiano = await subjectsService.createIfNotExists(
      'Piano',
      'Học chơi đàn piano từ cơ bản đến nâng cao, bao gồm nhạc lý, kỹ thuật chơi đàn và cảm thụ âm nhạc',
      'explorer',
    );

    // Update metadata
    newPiano.metadata = {
      icon: '🎹',
      color: '#8B4513',
      estimatedDays: 30,
    };
    newPiano.unlockConditions = {
      minCoin: 0,
    };
    await subjectRepo.save(newPiano);

    console.log(`✅ Đã tạo môn Piano (ID: ${newPiano.id})`);

    // Bước 3: Tạo mind map (knowledge graph) cho Piano
    console.log('\n🤖 Đang tạo mind map cho Piano...');
    const mindMap = await aiService.generateMindMap(
      'Piano',
      'Học chơi đàn piano từ cơ bản đến nâng cao, bao gồm nhạc lý, kỹ thuật chơi đàn và cảm thụ âm nhạc',
    );

    // Lưu mind map vào knowledge graph
    console.log('📊 Đang lưu mind map vào knowledge graph...');
    const nodeMap = new Map<string, KnowledgeNode>();

    // Tạo subject node
    const subjectKgNode = await kgService.createOrUpdateNode(
      newPiano.name,
      NodeType.SUBJECT,
      newPiano.id,
      { description: newPiano.description, metadata: newPiano.metadata },
    );
    nodeMap.set(newPiano.name, subjectKgNode);

    // Tạo các nodes khác
    for (const node of mindMap.nodes) {
      if (node.type === 'subject') continue;

      let nodeType: NodeType;
      switch (node.type) {
        case 'domain':
          nodeType = NodeType.DOMAIN;
          break;
        case 'topic':
        case 'concept':
          nodeType = NodeType.CONCEPT;
          break;
        default:
          nodeType = NodeType.CONCEPT;
      }

      const entityId = `${newPiano.id}_${node.name}`;
      const kgNode = await kgService.createOrUpdateNode(
        node.name,
        nodeType,
        entityId,
        {
          description: node.description,
          metadata: {
            ...node.metadata,
            subjectId: newPiano.id,
            subjectName: 'Piano',
            originalType: node.type,
          },
        },
      );
      nodeMap.set(node.name, kgNode);
    }

    // Tạo các edges
    for (const edge of mindMap.edges) {
      const fromKgNode = nodeMap.get(edge.from);
      const toKgNode = nodeMap.get(edge.to);

      if (fromKgNode && toKgNode) {
        let edgeType: EdgeType;
        switch (edge.type) {
          case 'prerequisite':
            edgeType = EdgeType.PREREQUISITE;
            break;
          case 'related':
            edgeType = EdgeType.RELATED;
            break;
          case 'part_of':
            edgeType = EdgeType.PART_OF;
            break;
          default:
            edgeType = EdgeType.RELATED;
        }

        await kgService.createEdge(
          fromKgNode.id,
          toKgNode.id,
          edgeType,
          {
            description: edge.metadata?.description,
            weight: edge.metadata?.weight ?? 1.0,
          },
        );
      }
    }

    console.log(`✅ Đã tạo mind map với ${mindMap.nodes.length} nodes và ${mindMap.edges.length} edges`);

    // Bước 4: Tạo learning nodes cho tất cả topics
    console.log('\n🎓 Đang tạo learning nodes cho tất cả topics...');

    const allKgNodes = await kgService.getMindMapForSubject(newPiano.id);
    
    // Filter topic nodes (Level 3 - CONCEPT với originalType = 'topic' hoặc 'concept')
    const topicNodes = allKgNodes.nodes.filter(node => {
      const isConcept = node.type === NodeType.CONCEPT;
      const originalType = (node.metadata as any)?.originalType;
      const isTopic = originalType === 'topic' || originalType === 'concept';
      const isNotSubjectOrDomain = originalType !== 'subject' && originalType !== 'domain';
      return isConcept && isTopic && isNotSubjectOrDomain;
    });

    console.log(`📝 Tìm thấy ${topicNodes.length} topics, đang tạo learning nodes...\n`);

    let generatedCount = 0;
    for (const topicNode of topicNodes) {
      try {
        // Kiểm tra xem đã có learning nodes cho topic này chưa
        const existingNodes = await nodesService.findByTopicNodeId(topicNode.id);
        if (existingNodes.length > 0) {
          console.log(`   ⏭️  Topic "${topicNode.name}" đã có ${existingNodes.length} learning nodes, bỏ qua...`);
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
          newPiano.id,
          topicNode.id,
          topicNode.name,
          topicNode.description || `Bài học về ${topicNode.name}`,
          newPiano.name,
          newPiano.description,
          domainName,
          1, // Order sẽ được skill tree quản lý sau
        );

        generatedCount++;
        console.log(`   ✅ Đã tạo learning node cho topic "${topicNode.name}"`);
      } catch (error) {
        console.error(`   ❌ Lỗi khi tạo learning node cho topic "${topicNode.name}":`, error.message);
      }
    }

    console.log(`\n✅ Đã tạo ${generatedCount} learning nodes cho ${topicNodes.length} topics`);

    // Bước 5: Kiểm tra kết quả
    const finalMindMap = await kgService.getMindMapForSubject(newPiano.id);
    const finalDomainNodes = finalMindMap.nodes.filter(n => n.type === NodeType.DOMAIN);
    const finalTopicNodes = finalMindMap.nodes.filter(n => {
      const isConcept = n.type === NodeType.CONCEPT;
      const originalType = (n.metadata as any)?.originalType;
      return isConcept && (originalType === 'topic' || originalType === 'concept');
    });
    const finalLearningNodes = await learningNodeRepo.find({
      where: { subjectId: newPiano.id },
    });

    console.log('\n' + '═'.repeat(60));
    console.log('📊 Kết quả cuối cùng:');
    console.log(`   📖 Subject: ${newPiano.name}`);
    console.log(`   📚 Domains: ${finalDomainNodes.length}`);
    console.log(`   📝 Topics: ${finalTopicNodes.length}`);
    console.log(`   🎓 Learning Nodes: ${finalLearningNodes.length}`);
    console.log(`   ✅ Tất cả topics đã có learning nodes: ${finalLearningNodes.length === finalTopicNodes.length ? 'CÓ' : 'CHƯA'}`);
    console.log('═'.repeat(60));

  } catch (error) {
    console.error('❌ Lỗi:', error);
  } finally {
    await app.close();
  }
}

recreatePianoSubject().catch(console.error);

/**
 * Script kiểm tra và tạo đầy đủ topics cho tất cả các môn học
 * 
 * CÁCH SỬ DỤNG:
 * npx ts-node src/seed/check-and-fix-subjects-topics.ts
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
import { KnowledgeNode } from '../knowledge-graph/entities/knowledge-node.entity';
import { KnowledgeEdge } from '../knowledge-graph/entities/knowledge-edge.entity';
import { DataSource } from 'typeorm';

async function checkAndFixSubjectsTopics() {
  const app = await NestFactory.createApplicationContext(AppModule);
  const subjectsService = app.select(SubjectsModule).get(SubjectsService);
  const kgService = app.select(KnowledgeGraphModule).get(KnowledgeGraphService);
  const aiService = app.select(AiModule).get(AiService);
  const dataSource = app.get(DataSource);
  const knowledgeNodeRepo = dataSource.getRepository(KnowledgeNode);
  const knowledgeEdgeRepo = dataSource.getRepository(KnowledgeEdge);

  console.log('🔍 Đang kiểm tra tất cả các môn học...\n');

  try {
    const allSubjects = await subjectsService.findByTrack('explorer');
    console.log(`📚 Tìm thấy ${allSubjects.length} môn học\n`);

    for (const subject of allSubjects) {
      console.log(`\n📖 Subject: ${subject.name} (ID: ${subject.id})`);
      console.log('─'.repeat(60));

      try {
        // Kiểm tra mind map hiện có
        const mindMap = await kgService.getMindMapForSubject(subject.id);
        
        if (mindMap.nodes.length === 0) {
          console.log('   ⚠️  Không có mind map, đang tạo mới...');
          await createMindMapForSubject(subject, aiService, kgService, dataSource);
          continue;
        }

        // Phân loại nodes theo level
        const subjectNodes = mindMap.nodes.filter(n => n.type === NodeType.SUBJECT);
        const domainNodes = mindMap.nodes.filter(n => n.type === NodeType.DOMAIN);
        const topicNodes = mindMap.nodes.filter(n => {
          const isConcept = n.type === NodeType.CONCEPT;
          const originalType = (n.metadata as any)?.originalType;
          return isConcept && (originalType === 'topic' || originalType === 'concept');
        });

        console.log(`   📊 Mind map hiện có:`);
        console.log(`      - Subject nodes: ${subjectNodes.length}`);
        console.log(`      - Domain nodes: ${domainNodes.length}`);
        console.log(`      - Topic nodes: ${topicNodes.length}`);

        // Kiểm tra xem có đủ 3 lớp không
        if (subjectNodes.length === 0) {
          console.log('   ⚠️  Thiếu subject node, đang tạo lại mind map...');
          await recreateMindMapForSubject(subject, aiService, kgService, dataSource);
        } else if (domainNodes.length === 0) {
          console.log('   ⚠️  Thiếu domain nodes, đang tạo lại mind map...');
          await recreateMindMapForSubject(subject, aiService, kgService, dataSource);
        } else if (topicNodes.length === 0) {
          console.log('   ⚠️  Thiếu topic nodes, đang tạo lại mind map...');
          await recreateMindMapForSubject(subject, aiService, kgService, dataSource);
        } else {
          console.log('   ✅ Mind map đã đầy đủ 3 lớp');
        }
      } catch (error) {
        console.error(`   ❌ Lỗi khi kiểm tra subject "${subject.name}":`, error.message);
      }
    }

    console.log('\n' + '═'.repeat(60));
    console.log('✅ Hoàn thành kiểm tra và sửa chữa!');
  } catch (error) {
    console.error('❌ Lỗi:', error);
  } finally {
    await app.close();
  }
}

async function createMindMapForSubject(
  subject: any,
  aiService: AiService,
  kgService: KnowledgeGraphService,
  dataSource: DataSource,
) {
  console.log(`   🤖 Đang tạo mind map cho "${subject.name}"...`);
  
  const mindMap = await aiService.generateMindMap(
    subject.name,
    subject.description,
  );

  // Xóa mind map cũ nếu có
  const existingNodes = await kgService.getMindMapForSubject(subject.id);
  if (existingNodes.nodes.length > 0) {
    const knowledgeNodeRepo = dataSource.getRepository(KnowledgeNode);
    const knowledgeEdgeRepo = dataSource.getRepository(KnowledgeEdge);
    
    // Xóa edges trước
    for (const edge of existingNodes.edges) {
      await knowledgeEdgeRepo.delete(edge.id);
    }
    
    // Xóa nodes
    for (const node of existingNodes.nodes) {
      await knowledgeNodeRepo.delete(node.id);
    }
  }

  // Tạo mind map mới
  const nodeMap = new Map<string, KnowledgeNode>();
  
  // Tạo subject node
  const subjectKgNode = await kgService.createOrUpdateNode(
    subject.name,
    NodeType.SUBJECT,
    subject.id,
    { description: subject.description, metadata: subject.metadata },
  );
  nodeMap.set(subject.name, subjectKgNode);

  // Tạo domain và topic nodes
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

    const entityId = `${subject.id}_${node.name}`;
    const kgNode = await kgService.createOrUpdateNode(
      node.name,
      nodeType,
      entityId,
      {
        description: node.description,
        metadata: {
          ...node.metadata,
          subjectId: subject.id,
          subjectName: subject.name,
          originalType: node.type,
        },
      },
    );
    nodeMap.set(node.name, kgNode);
  }

  // Tạo edges
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

  console.log(`   ✅ Đã tạo mind map với ${mindMap.nodes.length} nodes và ${mindMap.edges.length} edges`);
}

async function recreateMindMapForSubject(
  subject: any,
  aiService: AiService,
  kgService: KnowledgeGraphService,
  dataSource: DataSource,
) {
  // Xóa mind map cũ
  const existingNodes = await kgService.getMindMapForSubject(subject.id);
  if (existingNodes.nodes.length > 0) {
    const knowledgeNodeRepo = dataSource.getRepository(KnowledgeNode);
    const knowledgeEdgeRepo = dataSource.getRepository(KnowledgeEdge);
    
    // Xóa edges trước
    for (const edge of existingNodes.edges) {
      await knowledgeEdgeRepo.delete(edge.id);
    }
    
    // Xóa nodes
    for (const node of existingNodes.nodes) {
      await knowledgeNodeRepo.delete(node.id);
    }
    console.log(`   🗑️  Đã xóa mind map cũ`);
  }

  // Tạo mind map mới
  await createMindMapForSubject(subject, aiService, kgService, dataSource);
}

checkAndFixSubjectsTopics().catch(console.error);

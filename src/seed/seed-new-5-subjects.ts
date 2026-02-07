/**
 * Script xóa tất cả subjects hiện tại và tạo lại 5 subjects mới:
 * - Bóng rổ
 * - Piano
 * - Skincare
 * - Tài chính cá nhân
 * - Tin học văn phòng
 * 
 * Mỗi subject sẽ được tạo với:
 * 1. Mind map (knowledge graph) 3 lớp
 * 2. Tự động tạo learning nodes cho tất cả topics
 * 
 * CÁCH SỬ DỤNG:
 * npx ts-node src/seed/seed-new-5-subjects.ts
 */

import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module';
import { SeedModule } from './seed.module';
import { SeedService } from './seed.service';
import { SubjectsService } from '../subjects/subjects.service';
import { SubjectsModule } from '../subjects/subjects.module';
import { AiModule } from '../ai/ai.module';
import { AiService } from '../ai/ai.service';
import { KnowledgeGraphModule } from '../knowledge-graph/knowledge-graph.module';
import { KnowledgeGraphService } from '../knowledge-graph/knowledge-graph.service';
import { LearningNodesModule } from '../learning-nodes/learning-nodes.module';
import { LearningNodesService } from '../learning-nodes/learning-nodes.service';
import { KnowledgeNode } from '../knowledge-graph/entities/knowledge-node.entity';
import { NodeType } from '../knowledge-graph/entities/knowledge-node.entity';
import { EdgeType } from '../knowledge-graph/entities/knowledge-edge.entity';
import { KnowledgeEdge } from '../knowledge-graph/entities/knowledge-edge.entity';
import { DataSource } from 'typeorm';
import { LearningNode } from '../learning-nodes/entities/learning-node.entity';
import { Domain } from '../domains/entities/domain.entity';
import { ContentItem } from '../content-items/entities/content-item.entity';

async function seedNew5Subjects() {
  const app = await NestFactory.createApplicationContext(AppModule);
  const seedService = app.select(SeedModule).get(SeedService);
  const subjectsService = app.select(SubjectsModule).get(SubjectsService);
  const aiService = app.select(AiModule).get(AiService);
  const kgService = app.select(KnowledgeGraphModule).get(KnowledgeGraphService);
  const nodesService = app.select(LearningNodesModule).get(LearningNodesService);
  
  const dataSource = app.get(DataSource);
  const subjectRepo = (seedService as any).subjectRepository;
  const learningNodeRepo = dataSource.getRepository(LearningNode);
  const domainRepo = dataSource.getRepository(Domain);
  const contentItemRepo = dataSource.getRepository(ContentItem);
  const knowledgeNodeRepo = dataSource.getRepository(KnowledgeNode);
  const knowledgeEdgeRepo = dataSource.getRepository(KnowledgeEdge);

  console.log('🗑️  Bắt đầu xóa tất cả subjects hiện tại...\n');

  try {
    // Xóa content items
    const contentItems = await contentItemRepo.find();
    if (contentItems.length > 0) {
      await contentItemRepo.remove(contentItems);
      console.log(`✅ Đã xóa ${contentItems.length} content items`);
    }

    // Xóa learning nodes
    const learningNodes = await learningNodeRepo.find();
    if (learningNodes.length > 0) {
      await learningNodeRepo.remove(learningNodes);
      console.log(`✅ Đã xóa ${learningNodes.length} learning nodes`);
    }

    // Xóa domains
    const domains = await domainRepo.find();
    if (domains.length > 0) {
      await domainRepo.remove(domains);
      console.log(`✅ Đã xóa ${domains.length} domains`);
    }

    // Xóa knowledge edges
    const knowledgeEdges = await knowledgeEdgeRepo.find();
    if (knowledgeEdges.length > 0) {
      await knowledgeEdgeRepo.remove(knowledgeEdges);
      console.log(`✅ Đã xóa ${knowledgeEdges.length} knowledge edges`);
    }

    // Xóa knowledge nodes
    const knowledgeNodes = await knowledgeNodeRepo.find();
    if (knowledgeNodes.length > 0) {
      await knowledgeNodeRepo.remove(knowledgeNodes);
      console.log(`✅ Đã xóa ${knowledgeNodes.length} knowledge nodes`);
    }

    // Xóa subjects
    const subjects = await subjectRepo.find();
    if (subjects.length > 0) {
      await subjectRepo.remove(subjects);
      console.log(`✅ Đã xóa ${subjects.length} subjects`);
    }

    console.log('\n✅ Hoàn thành xóa dữ liệu cũ!\n');
  } catch (error) {
    console.error('⚠️  Lỗi khi xóa dữ liệu:', error.message);
  }

  console.log('🌱 Bắt đầu tạo 5 subjects mới...\n');

  const newSubjects = [
    {
      name: 'Bóng rổ',
      description: 'Học chơi bóng rổ từ cơ bản đến nâng cao, bao gồm kỹ thuật, chiến thuật và thể lực',
      track: 'explorer' as const,
      icon: '🏀',
      color: '#FF6B35',
    },
    {
      name: 'Piano',
      description: 'Học chơi đàn piano từ cơ bản đến nâng cao, bao gồm nhạc lý, kỹ thuật chơi đàn và cảm thụ âm nhạc',
      track: 'explorer' as const,
      icon: '🎹',
      color: '#8B4513',
    },
    {
      name: 'Skincare',
      description: 'Chăm sóc da đúng cách: hiểu về da, sản phẩm phù hợp và quy trình skincare hiệu quả',
      track: 'explorer' as const,
      icon: '✨',
      color: '#FFB6C1',
    },
    {
      name: 'Tài chính cá nhân',
      description: 'Quản lý tài chính cá nhân: ngân sách, tiết kiệm, đầu tư và lập kế hoạch tài chính',
      track: 'explorer' as const,
      icon: '💰',
      color: '#FFD700',
    },
    {
      name: 'Tin học văn phòng',
      description: 'Thành thạo Microsoft Office: Word, Excel, PowerPoint và các kỹ năng văn phòng cần thiết',
      track: 'explorer' as const,
      icon: '💻',
      color: '#4A90E2',
    },
  ];

  for (const subjectData of newSubjects) {
    try {
      console.log(`\n📚 Đang tạo subject: ${subjectData.name}...`);

      // Create subject
      const subject = await subjectsService.createIfNotExists(
        subjectData.name,
        subjectData.description,
        subjectData.track,
      );

      // Update metadata
      subject.metadata = {
        icon: subjectData.icon,
        color: subjectData.color,
        estimatedDays: 30,
      };
      subject.unlockConditions = {
        minCoin: 0,
      };
      await subjectRepo.save(subject);

      console.log(`✅ Đã tạo subject: ${subjectData.name} (ID: ${subject.id})`);

      // Generate mind map (knowledge graph) using AI
      console.log(`🤖 Đang tạo mind map cho "${subjectData.name}"...`);
      try {
        const mindMap = await aiService.generateMindMap(
          subjectData.name,
          subjectData.description,
        );

        // Create knowledge graph nodes
        console.log(`📊 Đang lưu mind map vào knowledge graph...`);
        const nodeMap = new Map<string, KnowledgeNode>();
        
        for (const node of mindMap.nodes) {
          // Map node type to NodeType enum
          let nodeType: NodeType;
          switch (node.type) {
            case 'subject':
              nodeType = NodeType.SUBJECT;
              break;
            case 'domain':
              nodeType = NodeType.DOMAIN;
              break;
            case 'concept':
            case 'topic':
              nodeType = NodeType.CONCEPT;
              break;
            default:
              nodeType = NodeType.CONCEPT;
          }

          // Use a unique identifier for entityId (subjectId + node name)
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
                subjectName: subjectData.name,
                originalType: node.type,
              },
            },
          );
          nodeMap.set(node.name, kgNode);
        }

        // Create edges (relationships)
        for (const edge of mindMap.edges) {
          const fromKgNode = nodeMap.get(edge.from);
          const toKgNode = nodeMap.get(edge.to);

          if (fromKgNode && toKgNode) {
            // Map edge type to EdgeType enum
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

        // Tự động tạo learning nodes cho tất cả topics
        console.log(`🎓 Đang tự động tạo learning nodes cho tất cả topics...`);
        
        // Lấy tất cả topic nodes (type = CONCEPT và originalType = 'topic' hoặc 'concept')
        const allKgNodes = await kgService.getMindMapForSubject(subject.id);
        
        // Debug: In ra tất cả nodes để kiểm tra
        console.log(`🔍 Debug: Tổng số nodes trong mind map: ${allKgNodes.nodes.length}`);
        allKgNodes.nodes.forEach(n => {
          const originalType = (n.metadata as any)?.originalType;
          console.log(`   - Node: "${n.name}", type: ${n.type}, originalType: ${originalType}`);
        });
        
        // Filter topic nodes: Loại bỏ SUBJECT và DOMAIN, chỉ lấy CONCEPT với originalType là 'topic' hoặc 'concept'
        const topicNodes = allKgNodes.nodes.filter(node => {
          const isConcept = node.type === NodeType.CONCEPT;
          const originalType = (node.metadata as any)?.originalType;
          const isTopic = originalType === 'topic' || originalType === 'concept';
          // Loại bỏ nodes là subject hoặc domain
          const isNotSubjectOrDomain = originalType !== 'subject' && originalType !== 'domain';
          return isConcept && isTopic && isNotSubjectOrDomain;
        });

        console.log(`📝 Tìm thấy ${topicNodes.length} topics, đang tạo learning nodes...`);

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

        console.log(`✅ Đã tạo ${generatedCount} learning nodes cho ${topicNodes.length} topics`);
      } catch (error) {
        console.error(`⚠️  Lỗi khi tạo mind map cho "${subjectData.name}":`, error.message);
      }

      console.log(`✅ Hoàn thành subject: ${subjectData.name}\n`);
    } catch (error) {
      console.error(`❌ Lỗi khi tạo subject "${subjectData.name}":`, error.message);
      console.error(error.stack);
    }
  }

  console.log('✅ Hoàn thành tạo tất cả 5 subjects!');
  await app.close();
}

seedNew5Subjects().catch(console.error);

import { Injectable } from '@nestjs/common';

export interface GenerationProgress {
  taskId: string;
  status: 'pending' | 'generating' | 'saving' | 'completed' | 'error';
  progress: number; // 0-100
  currentStep: string;
  totalNodes: number;
  completedNodes: number;
  error?: string;
  createdAt: Date;
  updatedAt: Date;
}

@Injectable()
export class GenerationProgressService {
  private progressMap: Map<string, GenerationProgress> = new Map();

  createTask(taskId: string, totalNodes: number): void {
    this.progressMap.set(taskId, {
      taskId,
      status: 'pending',
      progress: 0,
      currentStep: 'Đang khởi tạo...',
      totalNodes,
      completedNodes: 0,
      createdAt: new Date(),
      updatedAt: new Date(),
    });
  }

  updateProgress(
    taskId: string,
    updates: Partial<Omit<GenerationProgress, 'taskId' | 'createdAt'>>,
  ): void {
    const progress = this.progressMap.get(taskId);
    if (progress) {
      Object.assign(progress, updates, { updatedAt: new Date() });
      this.progressMap.set(taskId, progress);
    }
  }

  getProgress(taskId: string): GenerationProgress | null {
    return this.progressMap.get(taskId) || null;
  }

  deleteTask(taskId: string): void {
    this.progressMap.delete(taskId);
  }

  // Cleanup old tasks (older than 1 hour)
  cleanup(): void {
    const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000);
    for (const [taskId, progress] of this.progressMap.entries()) {
      if (progress.updatedAt < oneHourAgo) {
        this.progressMap.delete(taskId);
      }
    }
  }
}

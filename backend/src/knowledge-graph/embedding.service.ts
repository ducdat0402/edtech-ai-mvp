import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import OpenAI from 'openai';
import { GoogleGenerativeAI } from '@google/generative-ai';

@Injectable()
export class EmbeddingService {
  private readonly logger = new Logger(EmbeddingService.name);
  private openai: OpenAI | null = null;
  private gemini: GoogleGenerativeAI | null = null;
  private useGemini: boolean = false;

  constructor(private configService: ConfigService) {
    // Try Gemini first (cheaper), fallback to OpenAI
    const geminiApiKey = this.configService.get<string>('GEMINI_API_KEY');
    const openaiApiKey = this.configService.get<string>('OPENAI_API_KEY');

    if (geminiApiKey) {
      this.gemini = new GoogleGenerativeAI(geminiApiKey);
      this.useGemini = true;
      this.logger.log('✅ Using Google Gemini for embeddings');
    } else if (openaiApiKey) {
      this.openai = new OpenAI({ apiKey: openaiApiKey });
      this.logger.log('✅ Using OpenAI for embeddings');
    } else {
      this.logger.warn('⚠️  No embedding API key found. Embeddings will not work.');
    }
  }

  /**
   * Generate embedding vector for a text
   * Returns a 768-dimensional vector (Gemini) or 1536-dimensional vector (OpenAI)
   */
  async generateEmbedding(text: string): Promise<number[]> {
    if (!text || text.trim().length === 0) {
      throw new Error('Text cannot be empty');
    }

    try {
      if (this.useGemini && this.gemini) {
        return await this.generateGeminiEmbedding(text);
      } else if (this.openai) {
        return await this.generateOpenAIEmbedding(text);
      } else {
        throw new Error('No embedding service configured');
      }
    } catch (error) {
      this.logger.error(`Error generating embedding: ${error.message}`, error.stack);
      throw error;
    }
  }

  /**
   * Generate embedding using Google Gemini
   * Model: text-embedding-004 (768 dimensions)
   */
  private async generateGeminiEmbedding(text: string): Promise<number[]> {
    if (!this.gemini) {
      throw new Error('Gemini API not configured');
    }

    try {
      const model = this.gemini.getGenerativeModel({ model: 'text-embedding-004' });
      const result = await model.embedContent(text);
      const embedding = result.embedding.values;

      if (!embedding || embedding.length === 0) {
        throw new Error('Empty embedding returned from Gemini');
      }

      this.logger.debug(`Generated Gemini embedding: ${embedding.length} dimensions`);
      return embedding;
    } catch (error) {
      this.logger.error(`Gemini embedding error: ${error.message}`);
      throw error;
    }
  }

  /**
   * Generate embedding using OpenAI
   * Model: text-embedding-3-small (1536 dimensions) or text-embedding-ada-002 (1536 dimensions)
   */
  private async generateOpenAIEmbedding(text: string): Promise<number[]> {
    if (!this.openai) {
      throw new Error('OpenAI API not configured');
    }

    try {
      const response = await this.openai.embeddings.create({
        model: 'text-embedding-3-small', // Cheaper than text-embedding-3-large
        input: text,
      });

      const embedding = response.data[0]?.embedding;
      if (!embedding || embedding.length === 0) {
        throw new Error('Empty embedding returned from OpenAI');
      }

      this.logger.debug(`Generated OpenAI embedding: ${embedding.length} dimensions`);
      return embedding;
    } catch (error) {
      this.logger.error(`OpenAI embedding error: ${error.message}`);
      throw error;
    }
  }

  /**
   * Generate embeddings for multiple texts in batch
   */
  async generateEmbeddingsBatch(texts: string[]): Promise<number[][]> {
    const embeddings: number[][] = [];

    // Process in batches to avoid rate limits
    const batchSize = 10;
    for (let i = 0; i < texts.length; i += batchSize) {
      const batch = texts.slice(i, i + batchSize);
      const batchPromises = batch.map((text) => this.generateEmbedding(text));
      const batchEmbeddings = await Promise.all(batchPromises);
      embeddings.push(...batchEmbeddings);

      // Small delay between batches to avoid rate limits
      if (i + batchSize < texts.length) {
        await new Promise((resolve) => setTimeout(resolve, 100));
      }
    }

    return embeddings;
  }

  /**
   * Get embedding dimensions based on configured service
   */
  getEmbeddingDimensions(): number {
    if (this.useGemini) {
      return 768; // Gemini text-embedding-004
    } else if (this.openai) {
      return 1536; // OpenAI text-embedding-3-small
    }
    return 0;
  }
}


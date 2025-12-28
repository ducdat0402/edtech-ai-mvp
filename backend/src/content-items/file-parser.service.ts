import { Injectable, BadRequestException } from '@nestjs/common';
import * as mammoth from 'mammoth';

@Injectable()
export class FileParserService {
  /**
   * Parse PDF file to text
   */
  async parsePDF(buffer: Buffer): Promise<string> {
    try {
      // Use require for pdf-parse to avoid TypeScript import issues
      // pdf-parse v2.4.5 uses PDFParse class
      // eslint-disable-next-line @typescript-eslint/no-var-requires
      const pdfParseModule = require('pdf-parse');
      const PDFParse = pdfParseModule.PDFParse || pdfParseModule;
      
      // Create instance and get text
      const parser = new PDFParse({ data: buffer });
      const result = await parser.getText();
      return result.text || '';
    } catch (error) {
      console.error('Error parsing PDF:', error);
      throw new BadRequestException('Failed to parse PDF file. Please ensure it is a valid PDF.');
    }
  }

  /**
   * Parse DOCX file to text
   */
  async parseDOCX(buffer: Buffer): Promise<string> {
    try {
      const result = await mammoth.extractRawText({ buffer });
      return result.value;
    } catch (error) {
      console.error('Error parsing DOCX:', error);
      throw new BadRequestException('Failed to parse DOCX file. Please ensure it is a valid DOCX.');
    }
  }

  /**
   * Parse text file (plain text, .txt)
   */
  async parseTXT(buffer: Buffer): Promise<string> {
    try {
      return buffer.toString('utf-8');
    } catch (error) {
      console.error('Error parsing TXT:', error);
      throw new BadRequestException('Failed to parse text file.');
    }
  }

  /**
   * Auto-detect file type and parse
   */
  async parseFile(buffer: Buffer, mimetype: string, filename: string): Promise<string> {
    const fileExtension = filename.split('.').pop()?.toLowerCase();

    // PDF
    if (mimetype === 'application/pdf' || fileExtension === 'pdf') {
      return this.parsePDF(buffer);
    }

    // DOCX
    if (
      mimetype === 'application/vnd.openxmlformats-officedocument.wordprocessingml.document' ||
      fileExtension === 'docx'
    ) {
      return this.parseDOCX(buffer);
    }

    // TXT
    if (mimetype === 'text/plain' || fileExtension === 'txt') {
      return this.parseTXT(buffer);
    }

    // Try to parse as text if unknown
    if (mimetype.startsWith('text/')) {
      return this.parseTXT(buffer);
    }

    throw new BadRequestException(
      `Unsupported file type: ${mimetype}. Supported types: PDF, DOCX, TXT`,
    );
  }

  /**
   * Validate file
   */
  validateFile(file: Express.Multer.File): void {
    if (!file) {
      throw new BadRequestException('No file provided');
    }

    const maxSize = 10 * 1024 * 1024; // 10MB
    if (file.size > maxSize) {
      throw new BadRequestException(`File size exceeds maximum limit of ${maxSize / 1024 / 1024}MB`);
    }

    const allowedMimeTypes = [
      'application/pdf',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'text/plain',
    ];

    const fileExtension = file.originalname.split('.').pop()?.toLowerCase();
    const allowedExtensions = ['pdf', 'docx', 'txt'];

    if (
      !allowedMimeTypes.includes(file.mimetype) &&
      !allowedExtensions.includes(fileExtension || '')
    ) {
      throw new BadRequestException(
        `File type not allowed. Supported types: ${allowedExtensions.join(', ')}`,
      );
    }
  }
}


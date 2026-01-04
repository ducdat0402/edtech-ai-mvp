import { Injectable, BadRequestException } from '@nestjs/common';
import * as fs from 'fs';
import * as path from 'path';
import { v4 as uuidv4 } from 'uuid';

@Injectable()
export class FileStorageService {
  private readonly uploadsDir = path.join(process.cwd(), 'uploads');
  private readonly imagesDir = path.join(this.uploadsDir, 'images');
  private readonly videosDir = path.join(this.uploadsDir, 'videos');

  constructor() {
    // Ensure upload directories exist
    this.ensureDirectoryExists(this.uploadsDir);
    this.ensureDirectoryExists(this.imagesDir);
    this.ensureDirectoryExists(this.videosDir);
  }

  private ensureDirectoryExists(dirPath: string): void {
    if (!fs.existsSync(dirPath)) {
      fs.mkdirSync(dirPath, { recursive: true });
    }
  }

  /**
   * Save uploaded image file
   */
  async saveImage(file: Express.Multer.File): Promise<string> {
    if (!file) {
      throw new BadRequestException('No file provided');
    }

    // Validate image type
    const allowedMimeTypes = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
    if (!allowedMimeTypes.includes(file.mimetype)) {
      throw new BadRequestException(
        `Invalid image type. Allowed types: ${allowedMimeTypes.join(', ')}`,
      );
    }

    // Validate file size (max 10MB)
    const maxSize = 10 * 1024 * 1024;
    if (file.size > maxSize) {
      throw new BadRequestException(
        `File size exceeds maximum limit of ${maxSize / 1024 / 1024}MB`,
      );
    }

    // Generate unique filename
    const fileExtension = path.extname(file.originalname);
    const filename = `${uuidv4()}${fileExtension}`;
    const filePath = path.join(this.imagesDir, filename);

    // Save file
    fs.writeFileSync(filePath, file.buffer);

    // Return URL path (will be served as static file)
    return `/uploads/images/${filename}`;
  }

  /**
   * Save uploaded video file
   */
  async saveVideo(file: Express.Multer.File): Promise<string> {
    if (!file) {
      throw new BadRequestException('No file provided');
    }

    // Validate video type
    const allowedMimeTypes = ['video/mp4', 'video/webm', 'video/quicktime'];
    if (!allowedMimeTypes.includes(file.mimetype)) {
      throw new BadRequestException(
        `Invalid video type. Allowed types: ${allowedMimeTypes.join(', ')}`,
      );
    }

    // Validate file size (max 100MB for videos)
    const maxSize = 100 * 1024 * 1024;
    if (file.size > maxSize) {
      throw new BadRequestException(
        `File size exceeds maximum limit of ${maxSize / 1024 / 1024}MB`,
      );
    }

    // Generate unique filename
    const fileExtension = path.extname(file.originalname);
    const filename = `${uuidv4()}${fileExtension}`;
    const filePath = path.join(this.videosDir, filename);

    // Save file
    fs.writeFileSync(filePath, file.buffer);

    // Return URL path (will be served as static file)
    return `/uploads/videos/${filename}`;
  }

  /**
   * Delete file
   */
  async deleteFile(fileUrl: string): Promise<void> {
    try {
      // Extract file path from URL
      const filePath = path.join(process.cwd(), fileUrl);
      if (fs.existsSync(filePath)) {
        fs.unlinkSync(filePath);
      }
    } catch (error) {
      console.error(`Error deleting file ${fileUrl}:`, error);
      // Don't throw error, just log it
    }
  }
}


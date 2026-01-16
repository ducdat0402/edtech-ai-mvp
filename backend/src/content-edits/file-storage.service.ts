import { Injectable, BadRequestException, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as fs from 'fs';
import * as path from 'path';
import { v4 as uuidv4 } from 'uuid';
import { CloudinaryStorageService, CloudinaryUploadResult } from './cloudinary-storage.service';

@Injectable()
export class FileStorageService {
  private readonly logger = new Logger(FileStorageService.name);
  private readonly uploadsDir = path.join(process.cwd(), 'uploads');
  private readonly imagesDir = path.join(this.uploadsDir, 'images');
  private readonly videosDir = path.join(this.uploadsDir, 'videos');
  private readonly useCloudStorage: boolean;

  constructor(
    private configService: ConfigService,
    private cloudinaryService: CloudinaryStorageService,
  ) {
    // Ensure upload directories exist (for local fallback)
    this.ensureDirectoryExists(this.uploadsDir);
    this.ensureDirectoryExists(this.imagesDir);
    this.ensureDirectoryExists(this.videosDir);

    // Check if cloud storage is enabled
    this.useCloudStorage = this.cloudinaryService.isEnabled();
    if (this.useCloudStorage) {
      this.logger.log('Using Cloudinary for file storage');
    } else {
      this.logger.log('Using local file storage (Cloudinary not configured)');
    }
  }

  private ensureDirectoryExists(dirPath: string): void {
    if (!fs.existsSync(dirPath)) {
      fs.mkdirSync(dirPath, { recursive: true });
    }
  }

  /**
   * Save uploaded image file
   * Uses Cloudinary if configured, otherwise falls back to local storage
   */
  async saveImage(file: Express.Multer.File): Promise<string> {
    if (!file) {
      throw new BadRequestException('No file provided');
    }

    // Use Cloudinary if available
    if (this.useCloudStorage) {
      try {
        const result: CloudinaryUploadResult = await this.cloudinaryService.uploadImage(file);
        this.logger.log(`Image uploaded to Cloudinary: ${result.publicId}`);
        return result.url; // Return Cloudinary CDN URL
      } catch (error) {
        this.logger.warn(`Cloudinary upload failed, falling back to local storage: ${error.message}`);
        // Fall through to local storage
      }
    }

    // Fallback to local storage
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
   * Uses Cloudinary if configured (RECOMMENDED for production), otherwise falls back to local storage
   */
  async saveVideo(file: Express.Multer.File): Promise<string> {
    if (!file) {
      throw new BadRequestException('No file provided');
    }

    // Use Cloudinary if available (RECOMMENDED for production)
    if (this.useCloudStorage) {
      this.logger.log(`Attempting to upload video to Cloudinary (size: ${(file.size / 1024 / 1024).toFixed(2)}MB, type: ${file.mimetype})`);
      try {
        const result: CloudinaryUploadResult = await this.cloudinaryService.uploadVideo(file);
        this.logger.log(`✅ Video uploaded to Cloudinary successfully: ${result.publicId} (${(result.bytes / 1024 / 1024).toFixed(2)}MB)`);
        this.logger.log(`   Cloudinary URL: ${result.url}`);
        return result.url; // Return Cloudinary CDN URL
      } catch (error) {
        this.logger.error(`❌ Cloudinary upload failed: ${error.message}`);
        this.logger.error(`   Error details: ${JSON.stringify(error)}`);
        this.logger.warn(`⚠️ Falling back to local storage`);
        // Fall through to local storage
      }
    } else {
      this.logger.warn(`⚠️ Cloudinary not configured, using local storage for video upload`);
    }

    // Fallback to local storage (NOT RECOMMENDED for production with many users)
    this.logger.log(`💾 Saving video to local storage: ${file.originalname} (${(file.size / 1024 / 1024).toFixed(2)}MB)`);
    
    // Validate video type
    const allowedMimeTypes = ['video/mp4', 'video/webm', 'video/quicktime', 'video/x-msvideo'];
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
    this.logger.log(`✅ Video saved to local storage: /uploads/videos/${filename}`);

    // Return URL path (will be served as static file)
    return `/uploads/videos/${filename}`;
  }

  /**
   * Delete file
   * Handles both Cloudinary URLs and local file paths
   */
  async deleteFile(fileUrl: string): Promise<void> {
    try {
      // Check if it's a Cloudinary URL
      if (this.cloudinaryService.isCloudinaryUrl(fileUrl)) {
        const publicId = this.cloudinaryService.extractPublicId(fileUrl);
        if (publicId) {
          // Determine resource type from URL
          const resourceType = fileUrl.includes('/video/') ? 'video' : 'image';
          await this.cloudinaryService.deleteFile(publicId, resourceType);
          return;
        }
      }

      // Fallback to local file deletion
      // Extract file path from URL
      const filePath = path.join(process.cwd(), fileUrl);
      if (fs.existsSync(filePath)) {
        fs.unlinkSync(filePath);
        this.logger.log(`Deleted local file: ${fileUrl}`);
      }
    } catch (error) {
      this.logger.error(`Error deleting file ${fileUrl}:`, error);
      // Don't throw error, just log it
    }
  }
}


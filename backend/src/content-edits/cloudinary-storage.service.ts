import { Injectable, BadRequestException, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { v2 as cloudinary } from 'cloudinary';
import { Readable } from 'stream';

export interface CloudinaryUploadResult {
  url: string;
  publicId: string;
  format: string;
  width?: number;
  height?: number;
  duration?: number;
  bytes: number;
  thumbnailUrl?: string;
}

@Injectable()
export class CloudinaryStorageService {
  private readonly logger = new Logger(CloudinaryStorageService.name);
  private isConfigured = false;

  constructor(private configService: ConfigService) {
    this.initializeCloudinary();
  }

  private initializeCloudinary() {
    const cloudName = this.configService.get<string>('CLOUDINARY_CLOUD_NAME');
    const apiKey = this.configService.get<string>('CLOUDINARY_API_KEY');
    const apiSecret = this.configService.get<string>('CLOUDINARY_API_SECRET');

    if (cloudName && apiKey && apiSecret) {
      cloudinary.config({
        cloud_name: cloudName,
        api_key: apiKey,
        api_secret: apiSecret,
        secure: true,
      });
      this.isConfigured = true;
      this.logger.log('Cloudinary configured successfully');
    } else {
      this.logger.warn(
        'Cloudinary not configured. Set CLOUDINARY_CLOUD_NAME, CLOUDINARY_API_KEY, and CLOUDINARY_API_SECRET to enable cloud storage.',
      );
    }
  }

  /**
   * Check if Cloudinary is configured
   */
  isEnabled(): boolean {
    return this.isConfigured;
  }

  /**
   * Upload image to Cloudinary
   */
  async uploadImage(
    file: Express.Multer.File,
    folder = 'content-edits/images',
  ): Promise<CloudinaryUploadResult> {
    if (!this.isConfigured) {
      throw new BadRequestException('Cloudinary is not configured');
    }

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

    try {
      return new Promise((resolve, reject) => {
        const uploadStream = cloudinary.uploader.upload_stream(
          {
            folder,
            resource_type: 'image',
            format: 'auto', // Auto-optimize format
            quality: 'auto', // Auto-optimize quality
            fetch_format: 'auto',
          },
          (error, result) => {
            if (error) {
              this.logger.error('Cloudinary upload error:', error);
              reject(new BadRequestException(`Failed to upload image: ${error.message}`));
              return;
            }

            if (!result) {
              reject(new BadRequestException('Upload failed: No result returned'));
              return;
            }

            resolve({
              url: result.secure_url,
              publicId: result.public_id,
              format: result.format,
              width: result.width,
              height: result.height,
              bytes: result.bytes,
            });
          },
        );

        // Convert buffer to stream
        const bufferStream = new Readable();
        bufferStream.push(file.buffer);
        bufferStream.push(null);
        bufferStream.pipe(uploadStream);
      });
    } catch (error) {
      this.logger.error('Error uploading image to Cloudinary:', error);
      throw new BadRequestException(`Failed to upload image: ${error.message}`);
    }
  }

  /**
   * Upload video to Cloudinary with optimization
   */
  async uploadVideo(
    file: Express.Multer.File,
    folder = 'content-edits/videos',
  ): Promise<CloudinaryUploadResult> {
    if (!this.isConfigured) {
      throw new BadRequestException('Cloudinary is not configured');
    }

    if (!file) {
      throw new BadRequestException('No file provided');
    }

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

    try {
      return new Promise((resolve, reject) => {
        const uploadStream = cloudinary.uploader.upload_stream(
          {
            folder,
            resource_type: 'video',
            format: 'mp4', // Convert to MP4 for better compatibility
            quality: 'auto', // Auto-optimize quality
            eager: [
              // Generate thumbnail
              { width: 640, height: 360, crop: 'fill', format: 'jpg' },
            ],
            eager_async: false,
          },
          (error, result) => {
            if (error) {
              this.logger.error('Cloudinary upload error:', error);
              reject(new BadRequestException(`Failed to upload video: ${error.message}`));
              return;
            }

            if (!result) {
              reject(new BadRequestException('Upload failed: No result returned'));
              return;
            }

            // Extract thumbnail URL from eager transformations
            const thumbnailUrl = result.eager?.[0]?.secure_url;

            resolve({
              url: result.secure_url,
              publicId: result.public_id,
              format: result.format,
              width: result.width,
              height: result.height,
              duration: result.duration,
              bytes: result.bytes,
              thumbnailUrl,
            });
          },
        );

        // Convert buffer to stream
        const bufferStream = new Readable();
        bufferStream.push(file.buffer);
        bufferStream.push(null);
        bufferStream.pipe(uploadStream);
      });
    } catch (error) {
      this.logger.error('Error uploading video to Cloudinary:', error);
      throw new BadRequestException(`Failed to upload video: ${error.message}`);
    }
  }

  /**
   * Delete file from Cloudinary
   */
  async deleteFile(publicId: string, resourceType: 'image' | 'video' = 'image'): Promise<void> {
    if (!this.isConfigured) {
      this.logger.warn('Cloudinary not configured, skipping delete');
      return;
    }

    try {
      await cloudinary.uploader.destroy(publicId, {
        resource_type: resourceType,
      });
      this.logger.log(`Deleted ${resourceType} with public_id: ${publicId}`);
    } catch (error) {
      this.logger.error(`Error deleting file ${publicId} from Cloudinary:`, error);
      // Don't throw error, just log it
    }
  }

  /**
   * Extract public_id from Cloudinary URL
   */
  extractPublicId(url: string): string | null {
    try {
      // Cloudinary URL format: https://res.cloudinary.com/{cloud_name}/{resource_type}/upload/{public_id}.{format}
      const match = url.match(/\/upload\/(?:v\d+\/)?(.+?)(?:\.[^.]+)?$/);
      return match ? match[1] : null;
    } catch {
      return null;
    }
  }

  /**
   * Check if URL is a Cloudinary URL
   */
  isCloudinaryUrl(url: string): boolean {
    return url.includes('cloudinary.com') || url.includes('res.cloudinary.com');
  }
}


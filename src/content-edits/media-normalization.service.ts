import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { v2 as cloudinary } from 'cloudinary';

/**
 * Media Normalization Service
 * Automatically standardizes all uploaded images/videos:
 * - Resize/crop to standard dimensions
 * - Add watermark
 * - Apply template frame
 */
@Injectable()
export class MediaNormalizationService {
  private readonly logger = new Logger(MediaNormalizationService.name);

  // Standard dimensions for content media
  private readonly STANDARD_IMAGE_WIDTH = 1200;
  private readonly STANDARD_IMAGE_HEIGHT = 800;
  private readonly STANDARD_VIDEO_WIDTH = 1920;
  private readonly STANDARD_VIDEO_HEIGHT = 1080;

  // Watermark configuration
  private readonly watermarkText: string;
  private readonly watermarkEnabled: boolean;

  constructor(private configService: ConfigService) {
    // Get watermark text from config or use default
    this.watermarkText =
      this.configService.get<string>('MEDIA_WATERMARK_TEXT') || 'EdTech AI';
    this.watermarkEnabled =
      this.configService.get<string>('MEDIA_WATERMARK_ENABLED') !== 'false';
  }

  /**
   * Get Cloudinary transformations for image normalization
   */
  getImageTransformations(): any[] {
    const transformations: any[] = [];

    // 1. Resize and crop to standard dimensions (maintain aspect ratio, fill to fit)
    transformations.push({
      width: this.STANDARD_IMAGE_WIDTH,
      height: this.STANDARD_IMAGE_HEIGHT,
      crop: 'fill', // Fill the dimensions, cropping if necessary
      gravity: 'center', // Center the crop
      quality: 'auto', // Auto-optimize quality
      fetch_format: 'auto', // Auto-optimize format (WebP, AVIF)
    });

    // 2. Add watermark overlay (if enabled)
    if (this.watermarkEnabled) {
      transformations.push({
        overlay: {
          font_family: 'Arial',
          font_size: 30,
          font_weight: 'bold',
          text: this.watermarkText,
        },
        color: '#FFFFFF',
        gravity: 'south_east', // Bottom right corner
        x: 20,
        y: 20,
        opacity: 60, // 60% opacity
      });
    }

    // 3. Add template frame (border)
    transformations.push({
      border: '3px_solid_rgb:4A90E2', // Blue border, 3px solid
      radius: 8, // Rounded corners
    });

    return transformations;
  }

  /**
   * Get Cloudinary transformations for video normalization
   */
  getVideoTransformations(): any[] {
    const transformations: any[] = [];

    // 1. Resize and crop to standard dimensions (16:9 aspect ratio)
    transformations.push({
      width: this.STANDARD_VIDEO_WIDTH,
      height: this.STANDARD_VIDEO_HEIGHT,
      crop: 'fill',
      gravity: 'center',
      format: 'mp4', // Convert to MP4
      quality: 'auto',
      video_codec: 'h264', // H.264 codec for compatibility
    });

    // 2. Add watermark overlay (if enabled)
    if (this.watermarkEnabled) {
      transformations.push({
        overlay: {
          font_family: 'Arial',
          font_size: 40,
          font_weight: 'bold',
          text: this.watermarkText,
        },
        color: '#FFFFFF',
        gravity: 'south_east',
        x: 30,
        y: 30,
        opacity: 70, // 70% opacity for video
      });
    }

    // Note: Video frames/borders are typically handled via CSS in frontend
    // But we can add a subtle border effect via overlay if needed

    return transformations;
  }

  /**
   * Get eager transformations for images (applied immediately on upload)
   */
  getImageEagerTransformations(): any[] {
    return this.getImageTransformations();
  }

  /**
   * Get eager transformations for videos (applied immediately on upload)
   */
  getVideoEagerTransformations(): any[] {
    return this.getVideoTransformations();
  }

  /**
   * Generate normalized URL for an image (for on-the-fly transformation)
   * Useful when you want to apply transformations to existing images
   */
  getNormalizedImageUrl(publicId: string): string {
    const transformations = this.getImageTransformations();
    return cloudinary.url(publicId, {
      transformation: transformations,
      secure: true,
    });
  }

  /**
   * Generate normalized URL for a video (for on-the-fly transformation)
   */
  getNormalizedVideoUrl(publicId: string): string {
    const transformations = this.getVideoTransformations();
    return cloudinary.url(publicId, {
      resource_type: 'video',
      transformation: transformations,
      secure: true,
    });
  }

  /**
   * Check if normalization is enabled
   */
  isEnabled(): boolean {
    return (
      this.configService.get<string>('MEDIA_NORMALIZATION_ENABLED') !== 'false'
    );
  }

  /**
   * Get standard image dimensions
   */
  getStandardImageDimensions(): { width: number; height: number } {
    return {
      width: this.STANDARD_IMAGE_WIDTH,
      height: this.STANDARD_IMAGE_HEIGHT,
    };
  }

  /**
   * Get standard video dimensions
   */
  getStandardVideoDimensions(): { width: number; height: number } {
    return {
      width: this.STANDARD_VIDEO_WIDTH,
      height: this.STANDARD_VIDEO_HEIGHT,
    };
  }
}


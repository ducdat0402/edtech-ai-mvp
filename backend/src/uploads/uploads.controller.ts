import {
  Controller,
  Post,
  UseGuards,
  UseInterceptors,
  UploadedFile,
  BadRequestException,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { diskStorage } from 'multer';
import { extname } from 'path';
import { v4 as uuidv4 } from 'uuid';
import { existsSync, mkdirSync } from 'fs';
import { unlink } from 'fs/promises';
import { CloudinaryService } from './cloudinary.service';

const IMAGE_DEST = './uploads/images';
const VIDEO_DEST = './uploads/videos';

// Ensure directories exist
if (!existsSync(IMAGE_DEST)) mkdirSync(IMAGE_DEST, { recursive: true });
if (!existsSync(VIDEO_DEST)) mkdirSync(VIDEO_DEST, { recursive: true });

@Controller('uploads')
@UseGuards(JwtAuthGuard)
export class UploadsController {
  constructor(private readonly cloudinaryService: CloudinaryService) {}

  @Post('image')
  @UseInterceptors(
    FileInterceptor('image', {
      storage: diskStorage({
        destination: IMAGE_DEST,
        filename: (_req, file, cb) => {
          const uniqueName = `${uuidv4()}${extname(file.originalname)}`;
          cb(null, uniqueName);
        },
      }),
      limits: { fileSize: 10 * 1024 * 1024 }, // 10MB
      fileFilter: (_req, file, cb) => {
        if (!file.mimetype.startsWith('image/')) {
          return cb(new BadRequestException('Only image files are allowed'), false);
        }
        cb(null, true);
      },
    }),
  )
  async uploadImage(@UploadedFile() file: Express.Multer.File) {
    if (!file) {
      throw new BadRequestException('No image file provided');
    }

    const localImageUrl = `/uploads/images/${file.filename}`;
    if (!this.cloudinaryService.isEnabled()) {
      return { imageUrl: localImageUrl, url: localImageUrl };
    }

    try {
      const imageUrl = await this.cloudinaryService.uploadImageFromPath(
        file.path,
      );
      return { imageUrl, url: imageUrl };
    } catch (error) {
      throw new BadRequestException(
        `Cloudinary upload failed: ${error instanceof Error ? error.message : 'Unknown error'}`,
      );
    } finally {
      try {
        await unlink(file.path);
      } catch {
        // ignore cleanup errors
      }
    }
  }

  @Post('video')
  @UseInterceptors(
    FileInterceptor('video', {
      storage: diskStorage({
        destination: VIDEO_DEST,
        filename: (_req, file, cb) => {
          const uniqueName = `${uuidv4()}${extname(file.originalname)}`;
          cb(null, uniqueName);
        },
      }),
      limits: { fileSize: 100 * 1024 * 1024 }, // 100MB
      fileFilter: (_req, file, cb) => {
        if (!file.mimetype.startsWith('video/')) {
          return cb(new BadRequestException('Only video files are allowed'), false);
        }
        cb(null, true);
      },
    }),
  )
  async uploadVideo(@UploadedFile() file: Express.Multer.File) {
    if (!file) {
      throw new BadRequestException('No video file provided');
    }
    const videoUrl = `/uploads/videos/${file.filename}`;
    return { videoUrl, url: videoUrl };
  }
}

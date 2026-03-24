import { Injectable } from '@nestjs/common';
import { v2 as cloudinary } from 'cloudinary';

@Injectable()
export class CloudinaryService {
  private readonly enabled: boolean;

  constructor() {
    const cloudName = process.env.CLOUDINARY_CLOUD_NAME;
    const apiKey = process.env.CLOUDINARY_API_KEY;
    const apiSecret = process.env.CLOUDINARY_API_SECRET;

    this.enabled = Boolean(cloudName && apiKey && apiSecret);
    if (this.enabled) {
      cloudinary.config({
        cloud_name: cloudName,
        api_key: apiKey,
        api_secret: apiSecret,
      });
    }
  }

  isEnabled(): boolean {
    return this.enabled;
  }

  async uploadImageFromPath(
    filePath: string,
    folder = 'edtech-ai/images',
  ): Promise<string> {
    const result = await cloudinary.uploader.upload(filePath, {
      folder,
      resource_type: 'image',
      overwrite: false,
      unique_filename: true,
    });
    return result.secure_url;
  }
}

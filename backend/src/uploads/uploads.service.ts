import { Injectable, BadRequestException } from '@nestjs/common';
import sharp from 'sharp';
import * as path from 'path';
import * as fs from 'fs';
import { v4 as uuidv4 } from 'uuid';

@Injectable()
export class UploadsService {
  async processAndSaveImage(file: Express.Multer.File, folder: string = 'general'): Promise<string> {
    if (!file) {
      throw new BadRequestException('No file provided');
    }

    // Validar tipo de imagen si es necesario
    if (!file.mimetype.startsWith('image/')) {
      throw new BadRequestException('File is not an image');
    }

    const uploadsDir = path.join(process.cwd(), 'uploads', folder);
    
    // Crear directorio si no existe
    if (!fs.existsSync(uploadsDir)) {
      fs.mkdirSync(uploadsDir, { recursive: true });
    }

    const filename = `${uuidv4()}.webp`;
    const filepath = path.join(uploadsDir, filename);

    // Procesar, redimensionar a resolución estándar web y comprimir a webp (80% calidad)
    await sharp(file.buffer)
      .resize({ width: 800, height: 800, fit: 'inside', withoutEnlargement: true })
      .webp({ quality: 80 })
      .toFile(filepath);

    return `/uploads/${folder}/${filename}`;
  }
}

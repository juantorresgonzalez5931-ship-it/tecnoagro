import { v2 as cloudinary } from 'cloudinary';
import { CloudinaryStorage } from 'multer-storage-cloudinary';
import multer from 'multer';
import dotenv from 'dotenv';

dotenv.config();


console.log('Cloud name:', process.env.CLOUDINARY_CLOUD_NAME); console.log('API key:', process.env.CLOUDINARY_API_KEY);

cloudinary.config({

    
    cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
    api_key: process.env.CLOUDINARY_API_KEY,
    api_secret: process.env.CLOUDINARY_API_SECRET

});

const storage = new CloudinaryStorage({
    cloudinary: cloudinary,
    params: {
        folder: 'Tienda/productos',
        resource_type: 'auto',
        allowed_formats: ['jpg', 'png', 'jpeg', 'avif', 'webp', 'mp4', 'avi']
    }
});

export const upload=multer({
    storage,
    limits: {
        fileSize: 50 * 1024 * 1024
    }
    });

    export { cloudinary };
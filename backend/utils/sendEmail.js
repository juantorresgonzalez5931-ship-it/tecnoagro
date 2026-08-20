import nodemailer from 'nodemailer';
import dotenv from 'dotenv';

dotenv.config();

export const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASSWORD
    }
});

export const enviarCorreo = async (destinatario, asunto, html) => {
    return transporter.sendMail({
        from: process.env.EMAIL_USER,
        to: destinatario,
        subject: asunto,
        html
    });
};
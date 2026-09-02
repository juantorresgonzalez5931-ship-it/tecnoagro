import nodemailer from 'nodemailer';

const transporter = nodemailer.createTransport({
    host: 'smtp.gmail.com',
    port: 587,
    secure: false,
    family: 4,
    auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS,
    },
});

// Función para enviar un correo electrónico
export const enviarCorreo = async (destinatario, asunto, html) => {
    return transporter.sendMail({
        from: process.env.EMAIL_USER,
        to: destinatario,
        subject: asunto,
        html
    });
};

// Función para enviar un correo de confirmación de registro
export const enviarConfirmacionPedido = async (email, nombre, pedidoId, total) => {
    return transporter.sendMail({
        from: process.env.EMAIL_USER,
        to: email,
        subject: `Confirmación de pedido #${pedidoId} - TecnoAgro`,
        html: `
            <p>Hola ${nombre},</p>
            <p>Tu pedido <strong>#${pedidoId}</strong> ha sido creado con éxito.</p>
            <p>Total: <strong>$${total}</strong></p>
            <p>Te avisaremos cuando el estado de tu pedido cambie.</p>
        `
    });
};
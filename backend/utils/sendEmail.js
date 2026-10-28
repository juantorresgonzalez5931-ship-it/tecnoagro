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
// Correo de confirmación de reserva
export const enviarConfirmacionPedido = async (email, nombre, pedidoId, total, codigo, fechaLimite) => {
    const limite = fechaLimite
        ? new Date(fechaLimite).toLocaleString('es-CO', { dateStyle: 'long', timeStyle: 'short' })
        : null;

    return transporter.sendMail({
        from: process.env.EMAIL_USER,
        to: email,
        subject: `Reserva ${codigo} confirmada - TecnoAgro`,
        html: `
            <p>Hola ${nombre},</p>
            <p>Tu reserva <strong>#${pedidoId}</strong> fue creada con éxito.</p>
            <p>Código para reclamar en la tienda:</p>
            <h2 style="letter-spacing:2px;">${codigo}</h2>
            <p>Total a pagar en tienda: <strong>$${total}</strong></p>
            ${limite ? `<p>Tienes hasta el <strong>${limite}</strong> para reclamarla; después se libera y vence.</p>` : ''}
            <p>Presenta este código en la tienda para recoger tus productos.</p>
        `
    });
};
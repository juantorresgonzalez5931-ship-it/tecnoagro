// Envío de correos por la API HTTP de Brevo (funciona en Render gratis,
// a diferencia de SMTP/Gmail, cuyos puertos están bloqueados).
//
// Variables de entorno necesarias en Render:
//   BREVO_API_KEY    -> API key de Brevo (SMTP & API -> API Keys)
//   EMAIL_FROM       -> correo remitente verificado en Brevo (Senders)
//   EMAIL_FROM_NAME  -> (opcional) nombre visible, por defecto "TecnoAgro"

const BREVO_URL = 'https://api.brevo.com/v3/smtp/email';

// Función genérica para enviar un correo electrónico
export const enviarCorreo = async (destinatario, asunto, html) => {
  const apiKey = process.env.BREVO_API_KEY;
  const remitente = process.env.EMAIL_FROM;

  if (!apiKey || !remitente) {
    throw new Error('Faltan BREVO_API_KEY o EMAIL_FROM en las variables de entorno');
  }

  console.log(`[correo] Enviando a ${destinatario}: ${asunto}`);

  const respuesta = await fetch(BREVO_URL, {
    method: 'POST',
    headers: {
      'api-key': apiKey,
      'Content-Type': 'application/json',
      accept: 'application/json',
    },
    body: JSON.stringify({
      sender: { name: process.env.EMAIL_FROM_NAME || 'TecnoAgro', email: remitente },
      to: [{ email: destinatario }],
      subject: asunto,
      htmlContent: html,
    }),
    signal: AbortSignal.timeout(15000), // nunca se queda colgado más de 15 s
  });

  const cuerpo = await respuesta.text();

  if (!respuesta.ok) {
    throw new Error(`Brevo respondió ${respuesta.status}: ${cuerpo}`);
  }

  console.log(`[correo] Enviado a ${destinatario} (${respuesta.status})`);
  return cuerpo;
};

// Correo de confirmación de reserva
export const enviarConfirmacionPedido = async (email, nombre, pedidoId, total, codigo, fechaLimite) => {
  const limite = fechaLimite
    ? new Date(fechaLimite).toLocaleString('es-CO', {
        dateStyle: 'long',
        timeStyle: 'short',
        timeZone: 'America/Bogota',
      })
    : null;

  return enviarCorreo(
    email,
    `Reserva ${codigo} confirmada - TecnoAgro`,
    `
      <p>Hola ${nombre},</p>
      <p>Tu reserva <strong>#${pedidoId}</strong> fue creada con éxito.</p>
      <p>Código para reclamar en la tienda:</p>
      <h2 style="letter-spacing:2px;">${codigo}</h2>
      <p>Total a pagar en tienda: <strong>$${total}</strong></p>
      ${limite ? `<p>Tienes hasta el <strong>${limite}</strong> para reclamarla; después se libera y vence.</p>` : ''}
      <p>Presenta este código en la tienda para recoger tus productos.</p>
    `
  );
};
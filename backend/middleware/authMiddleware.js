import jwt from 'jsonwebtoken';

// Verifica que exista un token válido (usuario autenticado)
export const verificarToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({
      error: 'Token no proporcionado, por favor inicie sesión',
      code: 'TOKEN_MISSING',
    });
  }

  jwt.verify(token, process.env.JWT_SECRET, (err, decoded) => {
    if (err) {
      const expirado = err.name === 'TokenExpiredError';
      return res.status(401).json({
        error: expirado
          ? 'La sesión expiró, por favor inicie sesión nuevamente'
          : 'Sesión inválida, por favor inicie sesión nuevamente',
        code: expirado ? 'TOKEN_EXPIRED' : 'TOKEN_INVALID',
      });
    }

    // Por si la columna `rol` está guardada con espacios al final (char(n))
    if (typeof decoded.rol === 'string') decoded.rol = decoded.rol.trim();

    req.usuario = decoded;
    next();
  });
};

// Solo deja pasar si el usuario tiene rol admin (panel administrador)
export const verificarAdmin = (req, res, next) => {
  if (req.usuario?.rol?.trim() !== 'admin') {
    return res.status(403).json({ error: 'No tienes permisos de administrador' });
  }
  next();
};
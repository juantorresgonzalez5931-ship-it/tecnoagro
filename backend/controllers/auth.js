import bycrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import {crearUsuario, obtenerPorEmail} from '../models/usuario.js';


// registro
export const registro = async (req, res) => {
    const {nombre, email, password} = req.body;

    //validar datos
}
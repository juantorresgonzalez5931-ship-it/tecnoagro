//Importamos la conexion a la base de datos
import { supabase } from "../config/supabase.js";


// crear el usuario
export const crearUsuario = async (nombre, email, password, telefono, rol, codigoVerificacion,
    codigoVerificacionExpiracion) => {
    const { data, error } = await supabase
        .from('usuarios')
        .insert({ nombre, email, password, telefono, rol, isVerified: false, codigoVerificacion, codigoVerificacionExpiracion })
        .select('id,nombre,email,rol')
        .single();

    return { data, error }
};

//OBTENER TODOS LOS USUARIOS
export const obtenerUsuarios = async ()=>{
    const {data,error}=await supabase
    .from('usuarios')
    .select('*')
    return {data,error};
};

//BUSCAR USUARIO POR EMAIL PARA EL LOGIN
export const obtenerPorEmail= async(email)=>{
    const{data,error}=await supabase 
    .from("usuarios")
    .select("*")
    .eq ('email', email)
    .single();
    return{data,error};

};

//Obtener un usuario por id
export const obtenerPorId = async (id) => {
    const { data,error } = await supabase
        .from('usuarios')
        .select('id, nombre, email, rol')
        .eq('id', id)
        .single();
    return {data, error};
};

//actualizar su usuario
export const actualizarUsuario = async (id, campos) => {
    const { data, error } = await supabase
        .from('usuarios')
        .update(campos)
        .eq('id', id)
        .select('id, nombre, email, rol');
    return { data,error };
};

//actualizar solo la contraseña (usado en recuperacion de contraseña)
export const actualizarContrasena = async (id, nuevoPassword) => {
    const { data,error } = await supabase
        .from('usuarios')
        .update({ password: nuevoPassword })
        .eq('id', id)
        .select('id, nombre, email');
    return { data,error };
};

//eliminar un usuario
export const eliminarUsuario = async (id) => {
    const { data,error } = await supabase
        .from('usuarios')
        .delete()
        .eq('id', id)
        .select('id, nombre, email, rol')
        return { data,error };
};
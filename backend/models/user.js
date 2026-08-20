//Importamos la conexion a la base de datos
import { supabase } from "../config/supabase.js";

//obtener  todos los usuarios
export const crearUsuario=async (nombre,email,password,rol)=>{
        const {data,error}=await supabase
        .from('usuarios')
        .insert({nombre,email,password,rol})
        .select('*')
        return{data,error};
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
export const obtenerUsuarioPorId = async (id) => {
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

//eliminar un usuario
export const eliminarUsuario = async (id) => {
    const { data,error } = await supabase
        .from('usuarios')
        .delete()
        .eq('id', id)
        .select('id, nombre, email, rol')
        return { data,error };
};
   



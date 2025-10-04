const fs = require('fs');

// Estas variables de entorno deben estar configuradas en Vercel
const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseKey) {
  console.error('Error: Las variables de entorno NEXT_PUBLIC_SUPABASE_URL y NEXT_PUBLIC_SUPABASE_ANON_KEY no están definidas.');
  console.error('Asegúrate de haberlas configurado en Vercel.');
  process.exit(1);
}

const configContent = `
// Este archivo es generado automáticamente por el script de build en Vercel.
// NO LO MODIFIQUES MANUALMENTE

const SUPABASE_URL = "${supabaseUrl}";
const SUPABASE_KEY = "${supabaseKey}";
`;

try {
  fs.writeFileSync('config.js', configContent);
  console.log('Archivo config.js creado exitosamente para el entorno de Vercel.');
} catch (error) {
  console.error('Error al escribir el archivo config.js:', error);
  process.exit(1);
}

const bcrypt = require('bcrypt');
const { ObjectId } = require('mongodb');

// Función para crear juegos
async function seedJuegos(database) {
    try {
        console.log('Iniciando seed de juegos...');
        
        const juegos = [
            { 
                IDJuego: 1,
                NombreJuego: 'League of Legends', 
                Genero: 'MOBA', 
                Descripcion: 'Juego de estrategia en tiempo real',
                Imagen: 'https://cdn.mos.cms.futurecdn.net/3P5QJZ5QZ5QZ5QZ5QZ5QZ5.jpg'
            },
            { 
                IDJuego: 2,
                NombreJuego: 'Valorant', 
                Genero: 'FPS', 
                Descripcion: 'Juego de disparos táctico',
                Imagen: 'https://cdn.mos.cms.futurecdn.net/3P5QJZ5QZ5QZ5QZ5QZ5QZ5.jpg'
            },
            { 
                IDJuego: 3,
                NombreJuego: 'Counter-Strike 2', 
                Genero: 'FPS', 
                Descripcion: 'Juego de disparos en primera persona',
                Imagen: 'https://cdn.mos.cms.futurecdn.net/3P5QJZ5QZ5QZ5QZ5QZ5QZ5.jpg'
            },
            { 
                IDJuego: 4,
                NombreJuego: 'Fortnite', 
                Genero: 'Battle Royale', 
                Descripcion: 'Juego de supervivencia y construcción',
                Imagen: 'https://cdn.mos.cms.futurecdn.net/3P5QJZ5QZ5QZ5QZ5QZ5QZ5.jpg'
            },
            { 
                IDJuego: 5,
                NombreJuego: 'Apex Legends', 
                Genero: 'Battle Royale', 
                Descripcion: 'Juego de disparos en primera persona',
                Imagen: 'https://cdn.mos.cms.futurecdn.net/3P5QJZ5QZ5QZ5QZ5QZ5QZ5.jpg'
            },
            { 
                IDJuego: 6,
                NombreJuego: 'Call of Duty: Warzone', 
                Genero: 'Battle Royale', 
                Descripcion: 'Juego de disparos en primera persona',
                Imagen: 'https://cdn.mos.cms.futurecdn.net/3P5QJZ5QZ5QZ5QZ5QZ5QZ5.jpg'
            },
            { 
                IDJuego: 7,
                NombreJuego: 'Dota 2', 
                Genero: 'MOBA', 
                Descripcion: 'Juego de estrategia en tiempo real',
                Imagen: 'https://cdn.mos.cms.futurecdn.net/3P5QJZ5QZ5QZ5QZ5QZ5QZ5.jpg'
            },
            { 
                IDJuego: 8,
                NombreJuego: 'Overwatch 2', 
                Genero: 'FPS', 
                Descripcion: 'Juego de disparos en primera persona',
                Imagen: 'https://cdn.mos.cms.futurecdn.net/3P5QJZ5QZ5QZ5QZ5QZ5QZ5.jpg'
            },
            { 
                IDJuego: 9,
                NombreJuego: 'Rainbow Six Siege', 
                Genero: 'FPS', 
                Descripcion: 'Juego de disparos táctico',
                Imagen: 'https://cdn.mos.cms.futurecdn.net/3P5QJZ5QZ5QZ5QZ5QZ5QZ5.jpg'
            },
            { 
                IDJuego: 10,
                NombreJuego: 'Rocket League', 
                Genero: 'Deportes', 
                Descripcion: 'Juego de fútbol con coches',
                Imagen: 'https://cdn.mos.cms.futurecdn.net/3P5QJZ5QZ5QZ5QZ5QZ5QZ5.jpg'
            }
        ];

        const juegosCollection = database.collection('juego');
        
        // Eliminar juegos existentes para evitar duplicados
        await juegosCollection.deleteMany({});
        
        // Insertar los juegos
        const result = await juegosCollection.insertMany(juegos);
        console.log(`${result.insertedCount} juegos creados`);
        
        return result.insertedIds;
    } catch (error) {
        console.error('Error al crear juegos:', error);
        throw error;
    }
}

// Función para crear usuarios decoy
async function seedUsuarios(database) {
    try {
        console.log('Iniciando seed de usuarios decoy...');
        
        const usuariosCollection = database.collection('usuario');
        const juegosCollection = database.collection('juego');
        
        // Verificar si ya existen usuarios decoy
        const existingDecoy = await usuariosCollection.findOne({ Correo: 'alexgamer@example.com' });
        if (existingDecoy) {
            console.log('Los usuarios decoy ya existen en la base de datos');
            return;
        }

        // Obtener los juegos existentes
        const juegosExistentes = await juegosCollection.find({}).toArray();
        if (juegosExistentes.length === 0) {
            console.error('No hay juegos en la base de datos');
            return;
        }

        console.log(`Juegos encontrados: ${juegosExistentes.map(j => j.NombreJuego).join(', ')}`);

        // Nombres y descripciones para los usuarios decoy
        const decoyUsers = [
            { 
                nombre: 'AlexGamer', 
                edad: 22, 
                genero: 'Masculino', 
                descripcion: 'Busco equipo para rankeds. Main ADC en LoL y Duelista en Valorant. Jugador competitivo con más de 5 años de experiencia. Disponible por las tardes y fines de semana.',
                region: 'Europa',
                idiomas: ['Español', 'Inglés'],
                imagen: 'DwarfTestIcon',
                juegos: [
                    { nombre: 'League of Legends', rango: 'Diamante' },
                    { nombre: 'Valorant', rango: 'Inmortal' }
                ]
            },
            { 
                nombre: 'SarahPro', 
                edad: 25, 
                genero: 'Femenino', 
                descripcion: 'Streamer y jugadora competitiva. Especialista en estrategia y análisis de juego. Más de 10k seguidores en Twitch. Busco equipo para torneos profesionales.',
                region: 'América del Norte',
                idiomas: ['Inglés', 'Español'],
                imagen: 'ToadTestIcon',
                juegos: [
                    { nombre: 'Counter Strike', rango: 'Águila' },
                    { nombre: 'Dota 2', rango: 'Inmortal' }
                ]
            },
            { 
                nombre: 'MikeTheTank', 
                edad: 20, 
                genero: 'Masculino', 
                descripcion: 'Tank main en todos los juegos. Siempre protegiendo al equipo. Experiencia en torneos locales y regionales. Busco equipo para competir a nivel profesional.',
                region: 'Europa',
                idiomas: ['Español', 'Inglés', 'Francés'],
                imagen: 'TerroristTestIcon',
                juegos: [
                    { nombre: 'League of Legends', rango: 'Platino' },
                    { nombre: 'Overwatch 2', rango: 'Diamante' }
                ]
            },
            { 
                nombre: 'LunaGaming', 
                edad: 23, 
                genero: 'Femenino', 
                descripcion: 'Amante de los FPS. Alta precisión y buen trabajo en equipo. Jugadora profesional con experiencia en múltiples torneos. Disponible para prácticas diarias.',
                region: 'Asia',
                idiomas: ['Japonés', 'Inglés'],
                imagen: 'CatTestIcon',
                juegos: [
                    { nombre: 'Valorant', rango: 'Radiante' },
                    { nombre: 'Counter Strike', rango: 'Global Elite' }
                ]
            },
            { 
                nombre: 'CarlosNinja', 
                edad: 21, 
                genero: 'Masculino', 
                descripcion: 'Jugador versátil. Me adapto a cualquier rol y estrategia. Experiencia en coaching y análisis de partidas. Busco equipo para mejorar y competir.',
                region: 'América Latina',
                idiomas: ['Español', 'Portugués', 'Inglés'],
                imagen: 'DogTestIcon',
                juegos: [
                    { nombre: 'Fortnite', rango: 'Campeón' },
                    { nombre: 'Apex Legends', rango: 'Predador' }
                ]
            },
            { 
                nombre: 'EmmaBuilder', 
                edad: 24, 
                genero: 'Femenino', 
                descripcion: 'Especialista en construcción y edición en Fortnite. Busco duo para torneos. Ganadora de varios torneos locales. Disponible para prácticas intensivas.',
                region: 'Europa',
                idiomas: ['Inglés', 'Alemán'],
                imagen: 'DwarfTestIcon',
                juegos: [
                    { nombre: 'Fortnite', rango: 'Campeón' },
                    { nombre: 'Call of Duty: Warzone', rango: 'Crimson' }
                ]
            },
            { 
                nombre: 'DavidSniper', 
                edad: 22, 
                genero: 'Masculino', 
                descripcion: 'AWP main en CS2. Precisión y paciencia son mis puntos fuertes. Jugador profesional con experiencia en torneos internacionales. Busco equipo para ESL.',
                region: 'Europa',
                idiomas: ['Español', 'Inglés', 'Ruso'],
                imagen: 'ToadTestIcon',
                juegos: [
                    { nombre: 'Counter Strike', rango: 'Global Elite' },
                    { nombre: 'Rainbow Six Siege', rango: 'Diamante' }
                ]
            },
            { 
                nombre: 'SophiaSupport', 
                edad: 25, 
                genero: 'Femenino', 
                descripcion: 'Support main en LoL. Me encanta ayudar al equipo a brillar. Experiencia en torneos universitarios y locales. Busco equipo para competir en ligas.',
                region: 'América del Norte',
                idiomas: ['Inglés', 'Español'],
                imagen: 'TerroristTestIcon',
                juegos: [
                    { nombre: 'League of Legends', rango: 'Maestro' },
                    { nombre: 'Overwatch 2', rango: 'Maestro' }
                ]
            },
            { 
                nombre: 'LeoRush', 
                edad: 20, 
                genero: 'Masculino', 
                descripcion: 'Jugador agresivo. Me especializo en early game y snowball. Jugador profesional con experiencia en múltiples juegos. Busco equipo para torneos.',
                region: 'Asia',
                idiomas: ['Coreano', 'Inglés'],
                imagen: 'CatTestIcon',
                juegos: [
                    { nombre: 'League of Legends', rango: 'Desafiante' },
                    { nombre: 'Valorant', rango: 'Radiante' }
                ]
            },
            { 
                nombre: 'MiaTactics', 
                edad: 23, 
                genero: 'Femenino', 
                descripcion: 'Estratega nata. Me gusta analizar y explotar las debilidades del rival. Experiencia en coaching y análisis de partidas. Busco equipo para competir.',
                region: 'Europa',
                idiomas: ['Inglés', 'Francés', 'Alemán'],
                imagen: 'DogTestIcon',
                juegos: [
                    { nombre: 'Dota 2', rango: 'Inmortal' },
                    { nombre: 'Rainbow Six Siege', rango: 'Campeón' }
                ]
            },
            { 
                nombre: 'RyanFlex', 
                edad: 21, 
                genero: 'Masculino', 
                descripcion: 'Jugador flexible. Puedo adaptarme a cualquier rol y situación. Experiencia en múltiples juegos y torneos. Busco equipo para competir a nivel profesional.',
                region: 'América del Norte',
                idiomas: ['Inglés', 'Español'],
                imagen: 'DwarfTestIcon',
                juegos: [
                    { nombre: 'Apex Legends', rango: 'Maestro' },
                    { nombre: 'Rocket League', rango: 'Supersonic' }
                ]
            },
            { 
                nombre: 'ZoeCreative', 
                edad: 24, 
                genero: 'Femenino', 
                descripcion: 'Jugadora creativa. Me especializo en estrategias poco convencionales. Experiencia en torneos y creación de contenido. Busco equipo para innovar y competir.',
                region: 'Europa',
                idiomas: ['Inglés', 'Español', 'Italiano'],
                imagen: 'ToadTestIcon',
                juegos: [
                    { nombre: 'Call of Duty: Warzone', rango: 'Iridescente' },
                    { nombre: 'Rocket League', rango: 'Grand Champ' }
                ]
            }
        ];

        // Crear usuarios decoy
        for (const user of decoyUsers) {
            const newUser = {
                Nombre: user.nombre,
                Correo: `${user.nombre.toLowerCase()}@example.com`,
                Contraseña: await bcrypt.hash('password123', 10),
                FotoPerfil: user.imagen,
                Edad: user.edad,
                Region: user.region,
                Descripcion: user.descripcion,
                Juegos: user.juegos,
                Genero: user.genero,
                Idiomas: user.idiomas
            };

            await usuariosCollection.insertOne(newUser);
            console.log(`Usuario decoy creado exitosamente: ${user.nombre}`);
        }

        console.log('Proceso de creación de usuarios decoy completado');
    } catch (error) {
        console.error('Error al crear usuarios decoy:', error);
    }
}

// Función principal para ejecutar todos los seeders
async function runSeeders(database) {
    try {
        console.log('Iniciando proceso de seeders...');
        await seedJuegos(database);
        await seedUsuarios(database);
        console.log('Proceso de seeders completado');
    } catch (error) {
        console.error('Error en el proceso de seeders:', error);
    }
}

module.exports = {
    runSeeders
}; 
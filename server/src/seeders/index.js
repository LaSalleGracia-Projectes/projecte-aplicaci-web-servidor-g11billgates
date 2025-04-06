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

        // Lista de rangos por juego
        const rangosPorJuego = {
            'League of Legends': ['Hierro', 'Bronce', 'Plata', 'Oro', 'Platino', 'Diamante', 'Maestro', 'Gran Maestro', 'Desafiante'],
            'Valorant': ['Hierro', 'Bronce', 'Plata', 'Oro', 'Platino', 'Diamante', 'Ascendente', 'Inmortal', 'Radiante'],
            'Counter-Strike 2': ['Plata I', 'Plata II', 'Plata III', 'Plata IV', 'Plata Elite', 'Plata Elite Master', 'Nova I', 'Nova II', 'Nova III', 'Nova Master', 'AK I', 'AK II', 'AK Cruz', 'Águila I', 'Águila II', 'Águila Master', 'Supremo', 'Global Elite'],
            'Fortnite': ['Bronce', 'Plata', 'Oro', 'Platino', 'Diamante', 'Champion', 'Unreal'],
            'Apex Legends': ['Bronce', 'Plata', 'Oro', 'Platino', 'Diamante', 'Maestro', 'Predator'],
            'Call of Duty: Warzone': ['Bronce', 'Plata', 'Oro', 'Platino', 'Diamante', 'Crimson', 'Iridescent'],
            'Dota 2': ['Herald', 'Guardian', 'Crusader', 'Archon', 'Legend', 'Ancient', 'Divine', 'Immortal'],
            'Overwatch 2': ['Bronce', 'Plata', 'Oro', 'Platino', 'Diamante', 'Maestro', 'Gran Maestro', 'Top 500'],
            'Rainbow Six Siege': ['Cobre', 'Bronce', 'Plata', 'Oro', 'Platino', 'Diamante', 'Champion'],
            'Rocket League': ['Bronce', 'Plata', 'Oro', 'Platino', 'Diamante', 'Champion', 'Grand Champion', 'Supersonic Legend']
        };

        // Nombres y descripciones para los usuarios decoy
        const decoyUsers = [
            { nombre: 'AlexGamer', edad: 22, genero: 'Masculino', descripcion: 'Busco equipo para rankeds. Main ADC en LoL y Duelista en Valorant.' },
            { nombre: 'SarahPro', edad: 25, genero: 'Femenino', descripcion: 'Streamer y jugadora competitiva. Especialista en estrategia y análisis de juego.' },
            { nombre: 'MikeTheTank', edad: 20, genero: 'Masculino', descripcion: 'Tank main en todos los juegos. Siempre protegiendo al equipo.' },
            { nombre: 'LunaGaming', edad: 23, genero: 'Femenino', descripcion: 'Amante de los FPS. Alta precisión y buen trabajo en equipo.' },
            { nombre: 'CarlosNinja', edad: 21, genero: 'Masculino', descripcion: 'Jugador versátil. Me adapto a cualquier rol y estrategia.' },
            { nombre: 'EmmaBuilder', edad: 24, genero: 'Femenino', descripcion: 'Especialista en construcción y edición en Fortnite. Busco duo para torneos.' },
            { nombre: 'DavidSniper', edad: 22, genero: 'Masculino', descripcion: 'AWP main en CS2. Precisión y paciencia son mis puntos fuertes.' },
            { nombre: 'SophiaSupport', edad: 25, genero: 'Femenino', descripcion: 'Support main en LoL. Me encanta ayudar al equipo a brillar.' },
            { nombre: 'LeoRush', edad: 20, genero: 'Masculino', descripcion: 'Jugador agresivo. Me especializo en early game y snowball.' },
            { nombre: 'MiaTactics', edad: 23, genero: 'Femenino', descripcion: 'Estratega nata. Me gusta analizar y explotar las debilidades del rival.' },
            { nombre: 'RyanFlex', edad: 21, genero: 'Masculino', descripcion: 'Jugador flexible. Puedo adaptarme a cualquier rol y situación.' },
            { nombre: 'ZoeCreative', edad: 24, genero: 'Femenino', descripcion: 'Jugadora creativa. Me especializo en estrategias poco convencionales.' }
        ];

        // Crear cada usuario decoy
        for (const user of decoyUsers) {
            try {
                // Seleccionar 2-3 juegos aleatorios para cada usuario
                const userGames = [];
                const numGames = Math.floor(Math.random() * 2) + 2; // 2 o 3 juegos
                const availableGames = [...juegosExistentes];
                
                for (let i = 0; i < numGames; i++) {
                    const gameIndex = Math.floor(Math.random() * availableGames.length);
                    const selectedGame = availableGames[gameIndex];
                    availableGames.splice(gameIndex, 1); // Evitar duplicados
                    
                    const rangos = rangosPorJuego[selectedGame.NombreJuego];
                    if (!rangos) {
                        console.error(`No se encontraron rangos para el juego: ${selectedGame.NombreJuego}`);
                        continue;
                    }
                    
                    const rangoIndex = Math.floor(Math.random() * rangos.length);
                    
                    userGames.push({
                        IDJuego: selectedGame._id,
                        NombreJuego: selectedGame.NombreJuego,
                        NivelElo: rangos[rangoIndex]
                    });
                }

                if (userGames.length === 0) {
                    console.error(`No se pudieron asignar juegos al usuario ${user.nombre}`);
                    continue;
                }

                // Crear el usuario decoy
                const newUser = await usuariosCollection.insertOne({
                    Nombre: user.nombre,
                    Correo: `${user.nombre.toLowerCase()}@example.com`,
                    Contraseña: await bcrypt.hash('decoy123', 10),
                    Edad: user.edad,
                    Genero: user.genero,
                    Descripcion: user.descripcion,
                    Juegos: userGames,
                    FotoPerfil: `https://api.dicebear.com/7.x/avataaars/svg?seed=${user.nombre}`,
                    bloqueado: false,
                    IDUsuario: Math.floor(Math.random() * 1000000) // ID único para cada usuario
                });

                console.log(`Usuario decoy creado exitosamente: ${user.nombre}`);
            } catch (error) {
                console.error(`Error al crear usuario decoy ${user.nombre}:`, error);
            }
        }

        console.log('Proceso de creación de usuarios decoy completado');
    } catch (error) {
        console.error('Error general al crear usuarios decoy:', error);
        throw error;
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
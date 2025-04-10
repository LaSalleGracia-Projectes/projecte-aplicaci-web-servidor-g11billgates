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
        console.log('Iniciando seed de usuarios...');
        
        const usuariosCollection = database.collection('usuario');
        const juegosCollection = database.collection('juego');
        
        // Eliminar usuarios existentes
        await usuariosCollection.deleteMany({});

        // Obtener los juegos existentes
        const juegosExistentes = await juegosCollection.find({}).toArray();
        if (juegosExistentes.length === 0) {
            console.error('No hay juegos en la base de datos');
            return;
        }

        // Arrays para generar datos aleatorios
        const nombres = ['Alex', 'Sarah', 'Mike', 'Luna', 'Carlos', 'Emma', 'David', 'Sophia', 'Leo', 'Mia', 
                        'Jack', 'Ana', 'Pablo', 'Elena', 'Daniel', 'Laura', 'Mario', 'Julia', 'Victor', 'Isabel'];
        const apellidos = ['García', 'Smith', 'Wang', 'Kumar', 'Silva', 'Müller', 'Dubois', 'Johnson', 'Kim', 'López',
                          'Rossi', 'Brown', 'Chen', 'Patel', 'Santos', 'Weber', 'Martin', 'Lee', 'Popov', 'González'];
        const generos = ['Masculino', 'Femenino', 'No binario'];
        const regiones = ['Europa', 'América del Norte', 'América Latina', 'Asia', 'Oceanía'];
        const idiomas = ['Español', 'Inglés', 'Francés', 'Alemán', 'Chino', 'Japonés', 'Coreano', 'Portugués', 'Ruso'];
        const avatares = ['DwarfTestIcon', 'ToadTestIcon', 'TerroristTestIcon', 'CatTestIcon', 'DogTestIcon'];
        const rangos = {
            'League of Legends': ['Hierro', 'Bronce', 'Plata', 'Oro', 'Platino', 'Diamante', 'Maestro', 'Gran Maestro', 'Desafiante'],
            'Valorant': ['Hierro', 'Bronce', 'Plata', 'Oro', 'Platino', 'Diamante', 'Ascendente', 'Inmortal', 'Radiante'],
            'Counter-Strike 2': ['Plata 1', 'Plata Élite', 'Ak', 'Doble Ak', 'Águila', 'Águila Maestra', 'Supremo', 'Global Elite'],
            'Fortnite': ['División 1', 'División 2', 'División 3', 'Contendiente', 'Campeón', 'Elite'],
            'Apex Legends': ['Bronce', 'Plata', 'Oro', 'Platino', 'Diamante', 'Maestro', 'Predador'],
            'Dota 2': ['Heraldo', 'Guardián', 'Cruzado', 'Arconte', 'Leyenda', 'Ancestral', 'Divino', 'Inmortal'],
            'Overwatch 2': ['Bronce', 'Plata', 'Oro', 'Platino', 'Diamante', 'Maestro', 'Gran Maestro', 'Top 500'],
            'Rainbow Six Siege': ['Cobre', 'Bronce', 'Plata', 'Oro', 'Platino', 'Diamante', 'Campeón'],
            'Rocket League': ['Bronce', 'Plata', 'Oro', 'Platino', 'Diamante', 'Campeón', 'Gran Campeón', 'Supersónico']
        };

        const usuarios = [];
        const hashedPassword = await bcrypt.hash('password123', 10); // Contraseña común para todos los usuarios de prueba

        for (let i = 0; i < 20; i++) {
            // Seleccionar 2-3 juegos aleatorios para cada usuario
            const numJuegos = Math.floor(Math.random() * 2) + 2; // 2 o 3 juegos
            const juegosUsuario = [];
            const juegosDisponibles = [...juegosExistentes];
            
            for (let j = 0; j < numJuegos; j++) {
                const randomIndex = Math.floor(Math.random() * juegosDisponibles.length);
                const juego = juegosDisponibles.splice(randomIndex, 1)[0];
                const rangosJuego = rangos[juego.NombreJuego] || ['Principiante', 'Intermedio', 'Avanzado'];
                const rangoAleatorio = rangosJuego[Math.floor(Math.random() * rangosJuego.length)];
                
                juegosUsuario.push({
                    nombre: juego.NombreJuego,
                    rango: rangoAleatorio
                });
            }

            // Generar 2-3 idiomas aleatorios
            const numIdiomas = Math.floor(Math.random() * 2) + 2;
            const idiomasUsuario = [];
            const idiomasDisponibles = [...idiomas];
            for (let k = 0; k < numIdiomas; k++) {
                const randomIndex = Math.floor(Math.random() * idiomasDisponibles.length);
                idiomasUsuario.push(idiomasDisponibles.splice(randomIndex, 1)[0]);
            }

            const usuario = {
                IDUsuario: i + 1,
                Nombre: nombres[i],
                Apellido: apellidos[i],
                NombreUsuario: `${nombres[i].toLowerCase()}${Math.floor(Math.random() * 1000)}`,
                Correo: `${nombres[i].toLowerCase()}${Math.floor(Math.random() * 1000)}@example.com`,
                Contraseña: hashedPassword,
                Edad: Math.floor(Math.random() * 12) + 18, // Edad entre 18 y 30
                Genero: generos[Math.floor(Math.random() * generos.length)],
                Region: regiones[Math.floor(Math.random() * regiones.length)],
                Descripcion: `¡Hola! Soy ${nombres[i]}, jugador${generos[Math.floor(Math.random() * generos.length)] === 'Femenino' ? 'a' : ''} de ${juegosUsuario.map(j => j.nombre).join(' y ')}. Busco equipo para mejorar y competir.`,
                Idiomas: idiomasUsuario,
                FotoPerfil: avatares[Math.floor(Math.random() * avatares.length)],
                Juegos: juegosUsuario,
                FechaRegistro: new Date(Date.now() - Math.floor(Math.random() * 90) * 24 * 60 * 60 * 1000), // Últimos 90 días
                UltimaConexion: new Date(),
                Estado: 'Activo'
            };

            usuarios.push(usuario);
        }

        // Insertar los usuarios
        const result = await usuariosCollection.insertMany(usuarios);
        console.log(`${result.insertedCount} usuarios creados`);
        
        return result.insertedIds;
    } catch (error) {
        console.error('Error al crear usuarios:', error);
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
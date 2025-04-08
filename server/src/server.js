// Endpoint para obtener usuarios con rangos compatibles
app.get('/api/users/compatible', async (req, res) => {
    try {
        const { userId } = req.query;
        
        // Obtener el usuario actual
        const currentUser = await usuario.findOne({ _id: new ObjectId(userId) });
        if (!currentUser) {
            return res.status(404).json({ error: 'Usuario no encontrado' });
        }

        // Convertir rangos a números para comparación
        const rankValues = {
            'Hierro': 1, 'Bronce': 2, 'Plata': 3, 'Oro': 4, 
            'Platino': 5, 'Diamante': 6, 'Maestro': 7, 'Gran Maestro': 8, 
            'Desafiante': 9
        };

        // Obtener los IDs de los juegos del usuario actual
        const userGameIds = currentUser.juegos.map(game => game.juegoId.toString());

        // Construir la consulta para encontrar usuarios compatibles
        const query = {
            _id: { $ne: new ObjectId(userId) },
            juegos: {
                $elemMatch: {
                    juegoId: { $in: currentUser.juegos.map(game => new ObjectId(game.juegoId)) }
                }
            }
        };

        // Buscar usuarios compatibles
        const compatibleUsers = await usuario.find(query)
            .select('-password')
            .sort({ 'juegos.rango': 1 }); // Ordenar por rango

        // Filtrar usuarios para asegurar que tengan al menos un juego en común
        const filteredUsers = compatibleUsers.filter(user => {
            const userGameIds = user.juegos.map(game => game.juegoId.toString());
            return userGameIds.some(id => userGameIds.includes(id));
        });

        res.json(filteredUsers);
    } catch (error) {
        console.error('Error al obtener usuarios compatibles:', error);
        res.status(500).json({ error: 'Error al obtener usuarios compatibles' });
    }
});

// Función para crear usuarios decoy
async function createDecoyUsers() {
    try {
        console.log('Iniciando creación de usuarios decoy...');
        
        // Primero, obtener los juegos existentes de la base de datos
        const juegosExistentes = await juego.find({});
        console.log(`Juegos encontrados en la base de datos: ${juegosExistentes.length}`);
        
        if (juegosExistentes.length === 0) {
            console.error('No hay juegos en la base de datos');
            return;
        }

        // Lista de rangos por juego
        const rangosPorJuego = {
            'League of Legends': ['Hierro', 'Bronce', 'Plata', 'Oro', 'Platino', 'Diamante', 'Maestro', 'Gran Maestro', 'Desafiante'],
            'Valorant': ['Hierro', 'Bronce', 'Plata', 'Oro', 'Platino', 'Diamante', 'Ascendente', 'Inmortal', 'Radiante'],
            'Counter-Strike 2': ['Plata I', 'Plata II', 'Plata III', 'Plata IV', 'Plata Elite', 'Plata Elite Master', 'Nova I', 'Nova II', 'Nova III', 'Nova Master', 'AK I', 'AK II', 'AK Cruz', 'Águila I', 'Águila II', 'Águila Master', 'Supremo', 'Global Elite'],
            'Fortnite': ['Bronce', 'Plata', 'Oro', 'Platino', 'Diamante', 'Champion', 'Unreal']
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

        // Verificar si ya existen usuarios decoy
        const existingDecoy = await usuario.findOne({ email: 'alexgamer@example.com' });
        if (existingDecoy) {
            console.log('Los usuarios decoy ya existen en la base de datos');
            return;
        }

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
                    
                    const rangos = rangosPorJuego[selectedGame.nombre];
                    if (!rangos) {
                        console.error(`No se encontraron rangos para el juego: ${selectedGame.nombre}`);
                        continue;
                    }
                    
                    const rangoIndex = Math.floor(Math.random() * rangos.length);
                    
                    userGames.push({
                        juegoId: selectedGame._id,
                        nombre: selectedGame.nombre,
                        rango: rangos[rangoIndex]
                    });
                }

                if (userGames.length === 0) {
                    console.error(`No se pudieron asignar juegos al usuario ${user.nombre}`);
                    continue;
                }

                // Crear el usuario decoy
                const newUser = await usuario.create({
                    nombre: user.nombre,
                    email: `${user.nombre.toLowerCase()}@example.com`,
                    password: 'decoy123', // Contraseña por defecto para usuarios decoy
                    edad: user.edad,
                    genero: user.genero,
                    descripcion: user.descripcion,
                    juegos: userGames,
                    imagenPerfil: `https://api.dicebear.com/7.x/avataaars/svg?seed=${user.nombre}` // Avatar generado
                });

                console.log(`Usuario decoy creado exitosamente: ${newUser.nombre}`);
            } catch (error) {
                console.error(`Error al crear usuario decoy ${user.nombre}:`, error);
            }
        }

        console.log('Proceso de creación de usuarios decoy completado');
    } catch (error) {
        console.error('Error general al crear usuarios decoy:', error);
    }
}

// Modificar la función de inicio del servidor
async function startServer() {
    try {
        await client.connect();
        console.log('Conexión a MongoDB establecida');

        // Crear/verificar colecciones
        await Promise.all([
            usuario.createIndexes(),
            mensaje.createIndexes(),
            chat.createIndexes(),
            matchusers.createIndexes(),
            actividad.createIndexes(),
            juego.createIndexes(),
            juegousuario.createIndexes(),
            archivos_multimedia.createIndexes()
        ]);

        // Crear usuarios decoy
        await createDecoyUsers();

        app.listen(PORT, () => {
            console.log(`Servidor corriendo en puerto ${PORT}`);
        });
    } catch (error) {
        console.error('Error al iniciar el servidor:', error);
    }
}

startServer(); 
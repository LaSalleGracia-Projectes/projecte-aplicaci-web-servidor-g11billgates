// Endpoint para obtener usuarios con rangos compatibles
app.get('/api/users/compatible', async (req, res) => {
    try {
        const { userId } = req.query;
        
        // Obtener el usuario actual
        const currentUser = await usuario.findOne({ _id: new ObjectId(userId) });
        if (!currentUser) {
            return res.status(404).json({ error: 'Usuario no encontrado' });
        }

        // Obtener los IDs de los juegos del usuario actual
        const userGameIds = currentUser.Juegos.map(game => game.nombre);

        // Construir la consulta para encontrar usuarios compatibles
        const query = {
            _id: { $ne: new ObjectId(userId) },
            Juegos: {
                $elemMatch: {
                    nombre: { $in: userGameIds }
                }
            }
        };

        // Buscar usuarios compatibles
        const compatibleUsers = await usuario.find(query)
            .select('-Contraseña')
            .sort({ 'Juegos.rango': 1 }); // Ordenar por rango

        // Filtrar usuarios para asegurar que tengan al menos un juego en común
        const filteredUsers = compatibleUsers.filter(user => {
            const userGames = user.Juegos.map(game => game.nombre);
            return userGames.some(game => userGameIds.includes(game));
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

        // Validador para usuario
        await database.command({
            collMod: "usuario",
            validator: {
                $jsonSchema: {
                    bsonType: "object",
                    required: ["Nombre", "Correo", "Contraseña"],
                    properties: {
                        IDUsuario: { bsonType: ["int", "number"] },
                        Nombre: { bsonType: "string" },
                        Correo: { bsonType: "string" },
                        Contraseña: { bsonType: "string" },
                        FotoPerfil: { bsonType: ["string", "null"] },
                        Edad: { bsonType: ["int", "number", "null"] },
                        Region: { bsonType: ["string", "null"] },
                        bloqueado: { bsonType: "bool" },
                        likes: { 
                            bsonType: "array",
                            items: { bsonType: ["int", "number"] }
                        },
                        matches: { 
                            bsonType: "array",
                            items: { bsonType: ["int", "number"] }
                        }
                    }
                }
            },
            validationLevel: "moderate",
            validationAction: "error"
        });

        app.listen(PORT, () => {
            console.log(`Servidor corriendo en puerto ${PORT}`);
        });
    } catch (error) {
        console.error('Error al iniciar el servidor:', error);
    }
}

// Middleware para validar token
const validateToken = async (req, res, next) => {
    try {
        const token = req.headers.authorization?.split(' ')[1];
        if (!token) {
            return res.status(401).json({ error: 'Token no proporcionado' });
        }
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        req.user = decoded;
        next();
    } catch (error) {
        res.status(401).json({ error: 'Token inválido' });
    }
};

// Endpoint mejorado para likes
app.post('/api/users/:userId/like', async (req, res) => {
    try {
        const { userId } = req.params;
        const { likedUserId } = req.body;

        const database = client.db(dbName);
        const usuarios = database.collection('usuario');

        // Validaciones básicas
        if (userId === likedUserId) {
            return res.status(400).json({ error: 'No puedes darte like a ti mismo' });
        }

        // Verificar que ambos usuarios existen
        const [user, likedUser] = await Promise.all([
            usuarios.findOne({ IDUsuario: Number(userId) }),
            usuarios.findOne({ IDUsuario: Number(likedUserId) })
        ]);

        if (!user || !likedUser) {
            return res.status(404).json({ error: 'Usuario no encontrado' });
        }

        // Inicializar arrays si no existen
        if (!user.likes) user.likes = [];
        if (!user.matches) user.matches = [];
        if (!likedUser.likes) likedUser.likes = [];
        if (!likedUser.matches) likedUser.matches = [];

        // Verificar si ya existe un like previo
        if (user.likes.includes(Number(likedUserId))) {
            return res.status(400).json({ error: 'Ya has dado like a este usuario' });
        }

        // Verificar si ya hay match
        if (user.matches.includes(Number(likedUserId))) {
            return res.status(400).json({ error: 'Ya tienes un match con este usuario' });
        }

        // Verificar si el otro usuario ya dio like (esto crearía un match)
        const isMatch = likedUser.likes.includes(Number(userId));

        if (isMatch) {
            // Crear match en una sola operación
            await Promise.all([
                usuarios.updateOne(
                    { IDUsuario: Number(userId) },
                    { 
                        $push: { matches: Number(likedUserId) },
                        $pull: { likes: Number(likedUserId) }
                    }
                ),
                usuarios.updateOne(
                    { IDUsuario: Number(likedUserId) },
                    { 
                        $push: { matches: Number(userId) },
                        $pull: { likes: Number(userId) }
                    }
                )
            ]);
            
            // Crear un nuevo chat para el match
            const chat = await database.collection('chat').insertOne({
                usuarios: [Number(userId), Number(likedUserId)],
                mensajes: [],
                createdAt: new Date()
            });
            
            console.log(`Nuevo match entre ${user.Nombre} y ${likedUser.Nombre}`);
        } else {
            // Solo añadir el like
            await usuarios.updateOne(
                { IDUsuario: Number(likedUserId) },
                { $addToSet: { likes: Number(userId) } }
            );
        }

        res.json({ 
            isMatch,
            matchedUser: isMatch ? {
                id: likedUser.IDUsuario,
                name: likedUser.Nombre,
                profileImage: likedUser.FotoPerfil
            } : null,
            message: isMatch ? '¡Match! Ambos usuarios se han gustado' : 'Like enviado correctamente'
        });
    } catch (error) {
        console.error('Error en el sistema de likes:', error);
        res.status(500).json({ 
            error: 'Error interno del servidor',
            details: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
});

// Endpoint para obtener los matches de un usuario
app.get('/api/users/:userId/matches', async (req, res) => {
    try {
        const { userId } = req.params;
        
        const database = client.db(dbName);
        const usuarios = database.collection('usuario');
        
        const user = await usuarios.findOne({ IDUsuario: Number(userId) });
        if (!user) {
            return res.status(404).json({ error: 'Usuario no encontrado' });
        }
        
        const matches = await usuarios.find({
            IDUsuario: { $in: user.matches || [] }
        }).toArray();
        
        res.json(matches);
    } catch (error) {
        console.error('Error al obtener matches:', error);
        res.status(500).json({ error: 'Error al obtener matches' });
    }
});

// Endpoint para obtener usuarios compatibles (excluyendo likes y matches)
app.get('/api/users/compatible/:userId', async (req, res) => {
    try {
        const { userId } = req.params;
        
        const database = client.db(dbName);
        const usuarios = database.collection('usuario');
        
        const currentUser = await usuarios.findOne({ IDUsuario: Number(userId) });
        if (!currentUser) {
            return res.status(404).json({ error: 'Usuario no encontrado' });
        }
        
        // Obtener usuarios que no sean el actual, no estén en likes ni en matches
        const compatibleUsers = await usuarios.find({
            IDUsuario: { 
                $ne: Number(userId),
                $nin: [...(currentUser.likes || []), ...(currentUser.matches || [])]
            }
        }).toArray();
        
        res.json(compatibleUsers);
    } catch (error) {
        console.error('Error al obtener usuarios compatibles:', error);
        res.status(500).json({ error: 'Error al obtener usuarios compatibles' });
    }
});

// Configuración de directorios para archivos
const uploadDir = path.join(__dirname, 'uploads');
const profileImagesDir = path.join(uploadDir, 'profiles');
const chatMediaDir = path.join(uploadDir, 'chat');
const chatImagesDir = path.join(chatMediaDir, 'images');
const chatVideosDir = path.join(chatMediaDir, 'videos');
const chatAudioDir = path.join(chatMediaDir, 'audio');

// Crear directorios si no existen
[uploadDir, profileImagesDir, chatMediaDir, chatImagesDir, chatVideosDir, chatAudioDir].forEach(dir => {
    if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
    }
});

// Configuración de multer para subida de archivos
const storage = multer.diskStorage({
    destination: function (req, file, cb) {
        let uploadPath = uploadDir;
        if (file.fieldname === 'profileImage') {
            uploadPath = profileImagesDir;
        } else if (file.fieldname === 'chatMedia') {
            // Determinar el subdirectorio según el tipo de archivo
            const fileType = file.mimetype.split('/')[0];
            switch (fileType) {
                case 'image':
                    uploadPath = chatImagesDir;
                    break;
                case 'video':
                    uploadPath = chatVideosDir;
                    break;
                case 'audio':
                    uploadPath = chatAudioDir;
                    break;
                default:
                    uploadPath = chatMediaDir;
            }
        }
        cb(null, uploadPath);
    },
    filename: function (req, file, cb) {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        cb(null, file.fieldname + '-' + uniqueSuffix + path.extname(file.originalname));
    }
});

// Endpoint para subir archivos multimedia al chat
app.post('/upload-chat-media', upload.single('chatMedia'), async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ error: 'No se ha subido ningún archivo' });
        }

        const { chatId, userId } = req.body;
        if (!chatId || !userId) {
            return res.status(400).json({ error: 'Se requiere chatId y userId' });
        }

        const database = client.db(dbName);
        const archivosMultimedia = database.collection('archivos_multimedia');
        const mensajes = database.collection('mensaje');

        // Determinar el tipo de archivo y su subdirectorio
        const fileType = req.file.mimetype.split('/')[0];
        let processedFilePath = req.file.path;
        let duracion = null;
        let fileUrl = '';

        try {
            // Procesar el archivo según su tipo
            switch (fileType) {
                case 'image':
                    processedFilePath = path.join(chatImagesDir, 'processed-' + req.file.filename);
                    await sharp(req.file.path)
                        .resize(800, 800, { fit: 'inside' })
                        .jpeg({ quality: 80 })
                        .toFile(processedFilePath);
                    fs.unlinkSync(req.file.path);
                    fileUrl = `/uploads/chat/images/processed-${path.basename(req.file.filename)}`;
                    break;

                case 'video':
                    processedFilePath = path.join(chatVideosDir, req.file.filename);
                    fileUrl = `/uploads/chat/videos/${path.basename(req.file.filename)}`;
                    // Obtener duración del video
                    duracion = await new Promise((resolve, reject) => {
                        ffmpeg.ffprobe(req.file.path, (err, metadata) => {
                            if (err) reject(err);
                            resolve(metadata.format.duration);
                        });
                    });
                    break;

                case 'audio':
                    processedFilePath = path.join(chatAudioDir, req.file.filename);
                    fileUrl = `/uploads/chat/audio/${path.basename(req.file.filename)}`;
                    // Obtener duración del audio
                    duracion = await new Promise((resolve, reject) => {
                        ffmpeg.ffprobe(req.file.path, (err, metadata) => {
                            if (err) reject(err);
                            resolve(metadata.format.duration);
                        });
                    });
                    break;

                default:
                    throw new Error('Tipo de archivo no soportado');
            }

            // Crear mensaje en la base de datos
            const lastMessage = await mensajes.findOne({}, { sort: { IDMensaje: -1 } });
            const IDMensaje = lastMessage ? (lastMessage.IDMensaje || 0) + 1 : 1;

            const mensaje = {
                IDMensaje: Number(IDMensaje),
                IDChat: Number(chatId),
                IDUsuario: Number(userId),
                Tipo: fileType,
                Contenido: fileUrl,
                FechaEnvio: new Date(),
                Duracion: duracion
            };

            await mensajes.insertOne(mensaje);

            // Devolver respuesta con la URL completa
            const baseUrl = process.env.BASE_URL || 'http://localhost:3000';
            const fullUrl = `${baseUrl}${fileUrl}`;

            res.json({
                message: 'Archivo multimedia subido exitosamente',
                data: {
                    url: fullUrl,
                    type: fileType,
                    duration: duracion,
                    messageId: IDMensaje
                }
            });

        } catch (error) {
            // Limpiar archivos en caso de error
            if (fs.existsSync(req.file.path)) {
                fs.unlinkSync(req.file.path);
            }
            if (fs.existsSync(processedFilePath)) {
                fs.unlinkSync(processedFilePath);
            }
            throw error;
        }

    } catch (error) {
        console.error('Error al subir archivo multimedia:', error);
        res.status(500).json({ 
            error: 'Error al procesar el archivo',
            details: error.message
        });
    }
});

startServer(); 
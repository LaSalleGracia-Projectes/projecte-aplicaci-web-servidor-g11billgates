const express = require('express');
const { MongoClient, ObjectId } = require('mongodb');
const cors = require('cors');
require('dotenv').config();

const app = express();
const port = process.env.PORT || 3000;
const uri = process.env.MONGODB_URI || "mongodb+srv://rogerjove2005:rogjov01@cluster0.rxxyf.mongodb.net/";
const dbName = process.env.DB_NAME || "Projecte_prova";

app.use(cors());
app.use(express.json());

// Endpoint para obtener usuarios con juegos en común
app.get('/api/users/matching', async (req, res) => {
    try {
        const { userId } = req.query;
        
        if (!userId) {
            return res.status(400).json({ error: 'Se requiere el ID del usuario' });
        }

        const client = new MongoClient(uri);
        await client.connect();
        const db = client.db(dbName);

        // Obtener el usuario actual
        const currentUser = await db.collection('usuario').findOne({ _id: new ObjectId(userId) });
        if (!currentUser) {
            return res.status(404).json({ error: 'Usuario no encontrado' });
        }

        // Obtener los nombres de los juegos del usuario actual
        const userGameNames = currentUser.Juegos.map(game => game.nombre);

        // Buscar usuarios que compartan al menos un juego
        const matchingUsers = await db.collection('usuario')
            .find({
                _id: { $ne: new ObjectId(userId) },
                'Juegos.nombre': { $in: userGameNames }
            })
            .project({
                _id: 1,
                Nombre: 1,
                FotoPerfil: 1,
                Juegos: 1,
                Edad: 1,
                Region: 1
            })
            .toArray();

        // Filtrar y formatear los resultados
        const formattedUsers = matchingUsers.map(user => ({
            id: user._id,
            nombre: user.Nombre,
            fotoPerfil: user.FotoPerfil,
            juegos: user.Juegos.filter(game => userGameNames.includes(game.nombre)),
            edad: user.Edad,
            region: user.Region
        }));

        res.json(formattedUsers);
        await client.close();
    } catch (error) {
        console.error('Error:', error);
        res.status(500).json({ error: 'Error al obtener usuarios' });
    }
});

app.listen(port, () => {
    console.log(`Servidor simplificado corriendo en puerto ${port}`);
}); 
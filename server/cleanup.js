require('dotenv').config();
const { MongoClient } = require('mongodb');

async function cleanup() {
    const client = new MongoClient(process.env.MONGODB_URI);
    try {
        await client.connect();
        const db = client.db(process.env.DB_NAME);
        
        // Eliminar chats duplicados
        const chats = await db.collection('chat').find().toArray();
        const uniqueChats = new Map();
        
        for (const chat of chats) {
            const key = `${chat.IDUsuario1}-${chat.IDUsuario2}`;
            if (!uniqueChats.has(key)) {
                uniqueChats.set(key, chat);
            }
        }
        
        // Eliminar todos los chats
        await db.collection('chat').deleteMany({});
        
        // Insertar chats únicos
        const uniqueChatsArray = Array.from(uniqueChats.values());
        if (uniqueChatsArray.length > 0) {
            await db.collection('chat').insertMany(uniqueChatsArray);
        }
        
        console.log('Limpieza completada con éxito');
    } catch (error) {
        console.error('Error durante la limpieza:', error);
    } finally {
        await client.close();
    }
}

cleanup(); 
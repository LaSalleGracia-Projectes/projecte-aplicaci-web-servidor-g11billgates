// Endpoint para obtener usuarios con rangos compatibles
app.get('/api/users/compatible', async (req, res) => {
    try {
        const { userId, juegoId } = req.query;
        
        // Obtener el usuario actual
        const currentUser = await usuario.findOne({ _id: new ObjectId(userId) });
        if (!currentUser) {
            return res.status(404).json({ error: 'Usuario no encontrado' });
        }

        // Obtener el rango del usuario actual para el juego especificado
        const userRank = currentUser.juegos.find(j => j.juegoId.toString() === juegoId)?.rango;
        if (!userRank) {
            return res.status(400).json({ error: 'Usuario no tiene rango en este juego' });
        }

        // Convertir rangos a números para comparación
        const rankValues = {
            'Hierro': 1, 'Bronce': 2, 'Plata': 3, 'Oro': 4, 
            'Platino': 5, 'Diamante': 6, 'Maestro': 7, 'Gran Maestro': 8, 
            'Desafiante': 9
        };

        const currentRankValue = rankValues[userRank];

        // Buscar usuarios con rangos compatibles (±1 rango)
        const compatibleUsers = await usuario.find({
            _id: { $ne: new ObjectId(userId) },
            juegos: {
                $elemMatch: {
                    juegoId: new ObjectId(juegoId),
                    rango: {
                        $in: Object.entries(rankValues)
                            .filter(([_, value]) => Math.abs(value - currentRankValue) <= 1)
                            .map(([rank]) => rank)
                    }
                }
            }
        }).select('-password');

        res.json(compatibleUsers);
    } catch (error) {
        console.error('Error al obtener usuarios compatibles:', error);
        res.status(500).json({ error: 'Error al obtener usuarios compatibles' });
    }
}); 
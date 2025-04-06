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

        // Obtener los juegos del usuario actual
        const userGameIds = currentUser.juegos.map(game => game.juegoId.toString());

        // Construir la consulta para encontrar usuarios compatibles
        const query = {
            _id: { $ne: new ObjectId(userId) },
            juegos: {
                $all: currentUser.juegos.map(game => ({
                    juegoId: new ObjectId(game.juegoId),
                    rango: {
                        $in: Object.entries(rankValues)
                            .filter(([_, value]) => 
                                Math.abs(value - rankValues[game.rango]) <= 1
                            )
                            .map(([rank]) => rank)
                    }
                }))
            }
        };

        // Buscar usuarios compatibles
        const compatibleUsers = await usuario.find(query)
            .select('-password')
            .sort({ 'juegos.rango': 1 }); // Ordenar por rango

        res.json(compatibleUsers);
    } catch (error) {
        console.error('Error al obtener usuarios compatibles:', error);
        res.status(500).json({ error: 'Error al obtener usuarios compatibles' });
    }
}); 
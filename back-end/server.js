const express = require('express');
const sql = require('mssql'); // Using the Windows Auth driver
const cors = require('cors');

const app = express();
app.use(express.json());
app.use(cors());

// Configure Azure SQL Database Connection
const dbConfig = {
  server: 'tracker-api-server.database.windows.net', // Replace with your Azure server URL
  database: 'calorie-tracker-db',
  user: 'bilawalferoze',             // Replace with the username you just created
  password: process.env.DB_PASSWORD,   // Replace with the password you just created
  options: {
    encrypt: true,             // Required for Azure SQL
    trustServerCertificate: false 
  }
};

// Test database connection on startup
sql.connect(dbConfig).then(pool => {
  if (pool.connected) {
    console.log('Successfully connected to Microsoft SQL Server using Windows Authentication.');
  }
}).catch(err => {
  console.error('SQL Server connection error. Check your server name:', err);
});

// POST endpoint to receive feedback
app.post('/api/feedback', async (req, res) => {
  const { feedbackText } = req.body;

  if (!feedbackText || feedbackText.trim() === '') {
    return res.status(400).json({ error: 'Feedback text is required.' });
  }

  try {
    const pool = await sql.connect(dbConfig);
    
    const result = await pool.request()
      .input('feedbackText', sql.NVarChar(sql.MAX), feedbackText)
      .query(`
        INSERT INTO app_feedback (feedback_text) 
        VALUES (@feedbackText); 
        SELECT SCOPE_IDENTITY() AS id;
      `);
      
    const newId = result.recordset[0].id;

    return res.status(201).json({ 
      message: 'Feedback submitted successfully', 
      id: newId 
    });
  } catch (err) {
    console.error('Database insertion error:', err);
    return res.status(500).json({ error: 'Failed to save feedback to the database.' });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Feedback API server running on port ${PORT}`);
});
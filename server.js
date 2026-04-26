const express = require('express');
const multer = require('multer');
const { exec } = require('child_process');
const fs = require('fs');
const path = require('path');

const app = express();
const port = 3000;


app.use(express.static('.'));

app.post('/analyze', multer().single('file'), (req, res) => {
    if (!req.file) {
        return res.status(400).send('No file uploaded');
    }

    const inputContent = req.file.buffer.toString('utf8');
    const inputPath = path.join(__dirname, 'temp_input.c');
    const outputPath = path.join(__dirname, 'output.txt');


    fs.writeFileSync(inputPath, inputContent);

    exec(`a.exe ${inputPath}`, (error, stdout, stderr) => {
        if (error) {
            console.error(`Error: ${error.message}`);
            return res.status(500).send('Analysis failed');
        }

        let output;
        try {
            output = fs.readFileSync(outputPath, 'utf8');
        } catch (err) {
            return res.status(500).send('Output file not found');
        }

        try {
            fs.unlinkSync(inputPath);
            fs.unlinkSync(outputPath);
        } catch (err) {
            console.warn('Failed to clean up temp files');
        }

        res.send(output);
    });
});

app.listen(port, () => {
    console.log(`LEXISCAN server running at http://localhost:${port}`);
});
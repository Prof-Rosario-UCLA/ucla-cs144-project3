// app.js
import express from 'express';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const port = 1919;

// Debug middleware
app.use((req, res, next) => {
  console.log(`Request for: ${req.path}`);
  next();
});

// Serve files from dist directory with proper MIME types
app.use('/dist', express.static(path.join(__dirname, 'dist'), {
  setHeaders: (res, file) => {
    if (file.endsWith('.wasm')) {
      res.set('Content-Type', 'application/wasm');
    }
  }
}));

// Serve static files from public directory
app.use(express.static(path.join(__dirname, 'public')));

// Start server
app.listen(port, () => {
  console.log(`Server running on port ${port}`);
});

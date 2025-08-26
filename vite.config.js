import { defineConfig } from 'vite';

// We point Vite at your HTML living in pages/public
export default defineConfig({
  root: 'pages/public',
  build: {
    // Output dist under pages/public so Netlify can publish it directly
    outDir: 'dist',
    emptyOutDir: true
  }
});

// filepath: c:\Users\selli\mvp-painting-site-website\vite.config.mjs
import { defineConfig } from 'vite'
import { resolve } from 'path'

export default defineConfig({
  root: 'public',
  build: {
    outDir: '../dist',
    emptyOutDir: true,
    rollupOptions: {
      input: {
        index:    resolve(__dirname, 'public/index.html'),
        about:    resolve(__dirname, 'public/about.html'),
        services: resolve(__dirname, 'public/services.html'),
        gallery:  resolve(__dirname, 'public/gallery.html'),
        blog:     resolve(__dirname, 'public/blog.html'),
        contact:  resolve(__dirname, 'public/contact.html'),
      }
    }
  }
})
import { defineConfig } from 'vite'
import { resolve } from 'path'

export default defineConfig({
  root: 'public',
  build: {
    outDir: resolve(__dirname, 'dist'),
    emptyOutDir: true,
    rollupOptions: {
      input: {
        main: resolve(__dirname, 'public/index.html'),
        about: resolve(__dirname, 'public/about.html'),
        blog: resolve(__dirname, 'public/blog.html'),
        contact: resolve(__dirname, 'public/contact.html'),
        gallery: resolve(__dirname, 'public/gallery.html'),
        services: resolve(__dirname, 'public/services.html'),
      },
    },
  },
})
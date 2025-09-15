# MVP Painting Site

This is the codebase for the MVP Painting website. It is a modern, mobile-friendly, static website built with HTML, Tailwind CSS, and JavaScript, powered by Vite.

## Features
- Home, About, Services, Gallery, Blog, and Contact pages
- Responsive design and clean layout
- Call-to-action buttons for lead generation
- Organized assets for CSS, JS, and images
- Modern design, mobile responsive, SEO-friendly meta tags

## Project Structure

- `public/` — Source HTML files and static assets (edit these files)
- `src/input.css` — Tailwind CSS entry file (add your custom CSS here)
- `dist/` — Production build output (auto-generated, do not edit directly)
- `dist/assets/css/` — Built CSS files (output from Vite/Tailwind build)
- `dist/assets/js/` — Built JavaScript files

## Development Workflow

1. Install dependencies:
   ```
   npm install
   ```
2. To start the local dev server:
   ```
   npm run dev
   ```
3. To build for production:
   ```
   npm run build
   ```
   This will output the production site to the `dist/` folder.
4. To preview the production build locally:
   ```
   npm run preview
   ```
5. Edit HTML files in `public/` and CSS in `src/input.css`. Do not edit files in `dist/` directly.

## Build, Deploy, and Update Workflow

### 1. Install Dependencies
```
npm install
```

### 2. Start Local Development
```
npm run dev
```
- Edits to HTML in `public/` and CSS in `src/input.css` will hot-reload.

### 3. Build for Production
```
npm run build
```
- Outputs to `dist/`.
- Only necessary files are included for deploy.

### 4. Preview Production Build
```
npm run preview
```

### 5. Update Dependencies
```
npm outdated
npm update
```
- Regularly update for security and new features.

### 6. Optimize Images
- Convert large `.jpg`/`.png` images in `public/assets/images/` to `.webp` or `.avif` for better performance.
- Update HTML to use new formats, with `<picture>` for fallback if needed.

### 7. Deploy
- Deploy the contents of `dist/` to your static host (e.g., Vercel).
- Ensure your host is configured to use `dist` as the output directory.

### 8. Maintenance
- Remove unused assets and CSS regularly.
- Keep dependencies up to date.
- Document any workflow changes in this README.

---
This workflow ensures fast, modern, and maintainable static site development with Vite and Tailwind CSS.

## Deployment
- Deploy the contents of the `dist/` folder to your static host (e.g., Vercel).
- Make sure your Vercel project is configured to use `dist` as the output directory.

## Contact
For questions or help, contact: elvirpurovic@mvpdecor.com

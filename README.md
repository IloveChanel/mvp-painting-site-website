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

## Development & Deployment Workflow

### 1. Install Dependencies
```sh
npm install
```

### 2. Start Local Development
```sh
npm run dev
```
- Edit HTML in `public/`, CSS in `src/input.css`, and JS in `public/assets/js/`.
- Changes hot-reload in your browser at `http://localhost:5173`.

### 3. Build for Production
```sh
npm run build
```
- Outputs the production-ready site to `dist/`.

### 4. Preview Production Build Locally
```sh
npm run preview
```
- See exactly what will be deployed.

### 5. Deploy to Vercel
- Push your changes to your GitHub repo (if connected to Vercel), or run:
  ```sh
  vercel --prod
  ```
- Vercel will automatically build and deploy from the latest code in `dist/`.
- Make sure your Vercel project is set to use `dist` as the output directory.

### 6. Maintenance & Optimization
- Regularly run:
  ```sh
  npm outdated
  npm update
  ```
- Optimize images in `public/assets/images/` (use `.webp` or `.avif` for best performance).
- Remove unused assets and CSS.
- Document any workflow changes in this README.

---

## Quick Reference

- **Edit:** `public/` for HTML, `src/input.css` for CSS, `public/assets/js/` for JS.
- **Build:** `npm run build`
- **Preview:** `npm run preview`
- **Deploy:** Push to GitHub or use `vercel --prod`
- **Do not edit:** Anything in `dist/` directly.

---

## Contact

For questions or help, contact: elvirpurovic@mvpdecor.com
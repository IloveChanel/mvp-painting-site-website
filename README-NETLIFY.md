# Netlify Deployment Instructions

## Deploying to Netlify

1. **Build your CSS:**
   - Run `npm run build` to generate the latest Tailwind CSS in `assets/css/style.css`.

2. **Connect to Netlify:**
   - Go to [Netlify](https://app.netlify.com/) and create a new site from Git.
   - Select your repository.
   - Set the **publish directory** to `mvp-painting-site/pages/public`.
   - Set the **build command** to `npm run build` (if you want Netlify to build Tailwind for you).

3. **Custom Routing (SPA):**
   - The `_redirects` file is included for client-side routing support.

4. **Environment Variables:**
   - If you use any, add them in Netlify's dashboard under Site Settings > Environment Variables.

5. **Go Live!**
   - Deploy and your site will be live on your Netlify URL.

---

**Troubleshooting:**
- If you see missing styles, make sure the Tailwind build ran and `assets/css/style.css` exists in the publish directory.
- For custom domains, set them up in Netlify's domain management.

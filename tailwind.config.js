module.exports = {
  content: [
    "./mvp-painting-site/pages/public/**/*.html",
    "./src/**/*.{js,css}"
  ],
  theme: {
    extend: {},
  },
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/typography'),
    require('@tailwindcss/aspect-ratio'),
  ],
};

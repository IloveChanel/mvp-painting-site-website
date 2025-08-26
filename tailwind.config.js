/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./index.html",
    "./src/**/*.{html,js}", 
    "./components/**/*.{html,js}", 
  ],
  theme: {
    extend: {
      colors: {
        primary: "#1F2937",     // dark gray-blue
        accent: "#F59E0B",      // warm golden (amber)
        soft: "#F3F4F6",        // light gray background
        mvpBlue: "#2563EB",     // MVP theme blue
        mvpOrange: "#EA580C",   // MVP accent orange
      },
      fontFamily: {
        sans: ['"Public Sans"', 'sans-serif'],
        heading: ['"Rubik"', 'sans-serif'],
      },
      borderRadius: {
        xl: "1.5rem",
        '2xl': "2rem",
      },
    },
  },
  plugins: [],
}

/** @type {import("tailwindcss").Config} */
module.exports = {
  content: [
    "./public/**/*.html",
    "./src/**/*.{js,ts,jsx,tsx,vue}"
  ],
  theme: {
    extend: {
      colors: {
        ink:   "#141414",
        paper: "#F7F4EF",
        accent:"#C78686",
        gold:  "#D6B25E"
      },
      fontFamily: {
        sans: [
          "Montserrat",
          "system-ui",
          "Segoe UI",
          "Roboto",
          "Helvetica",
          "Arial",
          "sans-serif"
        ]
      }
    }
  },
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/typography')
  ]
}
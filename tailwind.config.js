// Tailwind config: brand palette + typography
module.exports = {
  content: ["./public/**/*.html"],
  theme: {
    extend: {
      colors: {
        brand: {
          50: "#e8fff2",
          100: "#c8ffd1",
          200: "#97f7aa",
          300: "#63e287",
          400: "#35c56a",
          500: "#18a651",
          600: "#0f8642",
          700: "#0c6935",
          800: "#0a512a",
          900: "#073a1f"
        },
        dark: "#0e1116"
      },
      fontFamily: {
        display: ["Poppins", "ui-sans-serif", "system-ui"],
        body: ["Inter", "ui-sans-serif", "system-ui"]
      },
      boxShadow: {
        soft: "0 10px 30px -10px rgba(0,0,0,0.25)"
      }
    }
  },
  plugins: []
}

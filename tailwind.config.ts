import type { Config } from "tailwindcss";

const config: Config = {
  content: ["./src/**/*.{js,ts,jsx,tsx,mdx}"],
  theme: {
    extend: {
      colors: {
        ink: {
          950: "#171717",
          900: "#22201d",
          700: "#55514c",
          500: "#868078"
        },
        sand: {
          50: "#fcfaf7",
          100: "#f5efe6",
          200: "#ece2d4"
        },
        moss: {
          500: "#69826b",
          600: "#526d56"
        },
        coral: {
          500: "#d67c61"
        },
        gold: {
          400: "#d4ae68"
        }
      },
      boxShadow: {
        calm: "0 14px 50px rgba(34, 32, 29, 0.10)"
      },
      borderRadius: {
        "4xl": "2rem"
      },
      fontFamily: {
        sans: ["ui-sans-serif", "system-ui", "sans-serif"]
      }
    }
  },
  plugins: []
};

export default config;

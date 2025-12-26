import type { Config } from "tailwindcss";

const config: Config = {
  darkMode: 'class',
  content: [
    "./pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./components/**/*.{js,ts,jsx,tsx,mdx}",
    "./app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      colors: {
        background: "var(--background)",
        foreground: "var(--foreground)",
        primary: {
          DEFAULT: '#FF8C42',
          50: '#FFF3EB',
          100: '#FFE7D6',
          200: '#FFCEAD',
          300: '#FFB685',
          400: '#FF9D5C',
          500: '#FF8C42',
          600: '#FF6B0A',
          700: '#D15400',
          800: '#993D00',
          900: '#612700',
        },
        accent: {
          DEFAULT: '#007AFF',
          50: '#E6F2FF',
          100: '#CCE5FF',
          200: '#99CBFF',
          300: '#66B0FF',
          400: '#3396FF',
          500: '#007AFF',
          600: '#0062CC',
          700: '#004999',
          800: '#003166',
          900: '#001833',
        },
      },
    },
  },
  plugins: [],
};
export default config;

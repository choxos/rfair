/** @type {import('tailwindcss').Config} */
export default {
  content: ["./index.html", "./src/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        fair: { f: "#118AB2", a: "#06D6A0", i: "#FFD166", r: "#EF476F", dark: "#073B4C" },
        maturity: { incomplete: "#fe7d37", initial: "#dfb317", moderate: "#97ca00", advanced: "#4c1" },
      },
    },
  },
  plugins: [],
};

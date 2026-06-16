import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

// Dev serves at "/"; production builds for GitHub Pages at /rfuji/app/.
export default defineConfig(({ command }) => ({
  plugins: [react()],
  base: command === "build" ? "/rfuji/app/" : "/",
}));

# GEMINI Project Context: News Application

This document provides context for the Gemini Code Assist agent to understand and work effectively with this project.

## 1. Project Overview

This project is a web application that fetches news articles from various third-party APIs, processes them, and displays them to the user. The primary goal is to provide a clean, fast, and customizable news feed.

## 2. Key Technologies

- **Frontend**: React with TypeScript, bootstrapped with Vite.
- **Backend**: Node.js with Express.js for serving data to the frontend.
- **Styling**: Tailwind CSS for utility-first styling.
- **Package Manager**: `npm` is used for managing dependencies.

## 3. Project Structure

```
/
├── public/           # Static assets (images, fonts)
├── src/
│   ├── components/   # Reusable React components
│   ├── services/     # Logic for fetching data from APIs
│   └── App.tsx       # Main application component
├── server/
│   ├── routes/       # Express API routes
│   └── index.js      # Main server entry point
├── GEMINI.md         # This context file
├── package.json      # Project dependencies and scripts
└── tailwind.config.js # Tailwind CSS configuration
```

## 4. How to Build and Run

1.  **Install dependencies**: `npm install`
2.  **Run the development server (frontend & backend)**: `npm run dev`
3.  **Build for production**: `npm run build`

## 5. Agent Instructions & Coding Conventions

- **DO**: Use functional components and React Hooks for all new frontend code.
- **DO**: Place all new backend API logic in the `server/routes/` directory.
- **DO**: Ensure all components are styled using Tailwind CSS utility classes.
- **DO NOT**: Use class-based components in React.
- **DO NOT**: Add new dependencies without updating `package.json` by running `npm install <package-name>`.
- **Style**: Follow the existing code style. Code is formatted with Prettier, which can be run with `npm run format`.
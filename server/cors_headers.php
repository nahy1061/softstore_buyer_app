<?php
// ──────────────────────────────────────────────────────────────────────────────
// cors_headers.php — Deploy to softstore.pk public root
//
// Place this file in your web root (same directory as index.php).
// Add the require line BELOW as the VERY FIRST thing in index.php,
// before session_start(), before any output, before any other require.
//
//   require_once __DIR__ . '/cors_headers.php';
//
// ──────────────────────────────────────────────────────────────────────────────

// Only act on requests that come from a browser (have an Origin header).
$origin = $_SERVER['HTTP_ORIGIN'] ?? '';

// ── Allowed origins ──────────────────────────────────────────────────────────
// Add any domain your Flutter web app is served from.
// NEVER use '*' when sending credentials (cookies).
$allowedOrigins = [
    'https://softstore.pk',       // production
    'https://www.softstore.pk',   // production (www)
    'http://localhost:3000',      // flutter run -d chrome
    'http://localhost:8080',      // alt dev port
    'http://localhost:5555',      // alt dev port
];

if ($origin !== '' && in_array($origin, $allowedOrigins, true)) {
    header("Access-Control-Allow-Origin: $origin");
    header('Vary: Origin');
    header('Access-Control-Allow-Credentials: true');
    header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
    header('Access-Control-Allow-Headers: Content-Type, Accept');
    header('Access-Control-Max-Age: 86400');
}

// ── Handle OPTIONS preflight ─────────────────────────────────────────────────
// Future-proofing: if any client ever sends a preflight, respond cleanly.
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

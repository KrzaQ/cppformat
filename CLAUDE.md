# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A web-based C++ code formatter written in D using the vibe.d framework. It provides an HTTP interface to `clang-format`, allowing users to format C++ code in their browser with various predefined styles (LLVM, Google, Chromium, Mozilla, WebKit, file).

Hosted at http://format.krzaq.cc/

## Build Commands

This is a standard dub (D package manager) project:

- **Build:** `dub build`
- **Run:** `dub run` (starts server on port 8080)

External dependency: `clang-format` must be installed and available in PATH.

## Architecture

- `source/app.d` — Main entry point. Configures vibe.d HTTP server (port 8080), URL routing, and the `WebInterface` class that handles GET (serve form) and POST (format code via clang-format) requests.
- `source/pipedprocess.d` — Custom async process wrapper around vibe.d streams for spawning clang-format, managing bidirectional pipes with proper thread synchronization.
- `views/index.dt` — Jade/Diet template for the web UI (code textarea, style selector, submit button).
- `public/` — Static assets (CSS).

The request flow: user submits code + style choice → `WebInterface.post()` spawns `clang-format --style=<style>` via `PipedProcess` → writes code to stdin → reads formatted output from stdout → returns result to template.

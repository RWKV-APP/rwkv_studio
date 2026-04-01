# RWKV-Studio

<h1 align="center">
    <img src="https://raw.githubusercontent.com/RWKV-APP/rwkv_studio/refs/heads/master/assets/img/rwkv_logo.png" width="150" height="150" alt="RWKV-Studio logo" /><br>
</h1>

**Offline-first AI Studio for RWKV & LLMs**

RWKV-Studio is a cross-platform application for running, managing, and integrating Large Language
Models, with first-class support for RWKV and practical support for OpenAI-compatible providers.

It is built around a local-first workflow: load models on your own machine, connect remote services
when needed, and manage chat, workflows, MCP tools, and model lifecycle in one place.

## Features

- Native RWKV inference with local GPU / CPU execution
- OpenAI-compatible remote model integration
- Multi-session chat and text generation views
- Batch inference for parallel prompt execution
- Visual workflow editor for agent-style pipelines
- Built-in MCP server management and tool connectivity
- Local model download, import, and lifecycle management
- OpenAI-compatible local HTTP service for external integrations

## Tech Stack

- Flutter desktop / web application
- Fluent UI based interface
- Hive local storage
- RWKV runtime via sibling packages:
  - `../rwkv_dart`
  - `../rwkv_downloader`
  - `../rwkv_libs`

## Quick Start

### Prerequisites

- Flutter SDK `^3.10.0`
- Local sibling dependencies required by `pubspec.yaml`:
  - `../rwkv_dart`
  - `../rwkv_downloader`
  - `../rwkv_libs`

### Run

```bash
flutter pub get
flutter run -d windows
```

You can also target `linux`, `macos`, or `web` depending on your environment.

## Repository Layout

- `lib/` application source code
- `assets/` bundled images and RWKV-related assets
- `docs/` screenshots used by this README
- `examples/` small example scripts and experiments

## Screenshots

<p align="center">
  <img src="https://raw.githubusercontent.com/RWKV-APP/rwkv_studio/refs/heads/master/docs/chat.png" width="260" alt="Chat view" />
  <img src="https://raw.githubusercontent.com/RWKV-APP/rwkv_studio/refs/heads/master/docs/workflow.png" width="260" alt="Workflow view" />
  <img src="https://raw.githubusercontent.com/RWKV-APP/rwkv_studio/refs/heads/master/docs/setting.png" width="260" alt="Settings view" />
</p>

## Status

RWKV-Studio is under active development. The current repository already includes the core desktop
experience for chat, model management, workflow editing, MCP configuration, and local service
integration.

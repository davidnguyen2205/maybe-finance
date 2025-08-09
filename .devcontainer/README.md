# Maybe Finance Development Container

This directory contains the development container configuration for Maybe Finance. The dev container provides a complete, consistent development environment with all necessary tools and dependencies pre-installed.

## What's Included

### Development Environment
- **Ruby 3.4.4** with Bundler and development gems
- **Node.js 20 LTS** with npm and development tools
- **PostgreSQL 16** with development database pre-configured
- **Redis 7** for background jobs and caching
- **Oh My Zsh** with helpful aliases and a great developer experience

### VS Code Extensions
- **Ruby & Rails**: Shopify Ruby LSP, RuboCop, debugging support
- **JavaScript/CSS**: Biome for linting/formatting, Tailwind CSS support
- **Database**: PostgreSQL management tools
- **General**: GitLens, GitHub Actions, YAML support, and more

### Development Tools
- **Debugging**: Ruby debugger (rdbg) with VS Code integration
- **Testing**: Pre-configured for Minitest with VS Code test explorer
- **Linting**: RuboCop for Ruby, Biome for JavaScript
- **Database Management**: pgAdmin web interface
- **Redis Management**: Redis Commander web interface

## Quick Start

1. **Open in VS Code**: Ensure you have the "Dev Containers" extension installed
2. **Reopen in Container**: VS Code should prompt you, or use Command Palette: "Dev Containers: Reopen in Container"
3. **Wait for Setup**: The container will build and install dependencies automatically
4. **Start Development**: Run `bin/dev` to start all services

## Available Services

| Service | URL | Purpose |
|---------|-----|---------|
| Rails App | http://localhost:3000 | Main application |
| pgAdmin | http://localhost:5050 | Database management |
| Redis Commander | http://localhost:8081 | Redis management |

### pgAdmin Credentials
- **Email**: admin@maybe.co
- **Password**: password

## Quick Commands

The container includes helpful aliases in the shell:

```bash
# Development
dev              # Start full development server (Rails + Sidekiq + CSS)
rs               # Start Rails server only
rc               # Rails console
rt               # Run tests
rts              # Run system tests

# Database
migrate          # Run migrations
rollback         # Rollback last migration
seed             # Load seed data
reset            # Reset database

# Code Quality
lint             # Run RuboCop
lint-fix         # Run RuboCop with auto-fixes

# Background Jobs
sidekiq          # Start Sidekiq worker
sidekiq-dev      # Start Sidekiq in development mode

# Git shortcuts
gst              # git status
gco              # git checkout
gcb              # git checkout -b
gp               # git pull
gps              # git push
gc               # git commit
ga               # git add
```

## Development Workflow

1. **Start Services**: `bin/dev` (starts Rails, Sidekiq, and CSS watcher)
2. **Run Tests**: `bin/rails test` for unit tests, `bin/rails test:system` for integration tests
3. **Database Changes**: Create migrations with `bin/rails generate migration`, then `migrate`
4. **Code Quality**: Run `lint` before committing, use `lint-fix` for auto-corrections
5. **Debugging**: Set breakpoints in VS Code or use `debugger` in Ruby code

Happy coding! 🎉

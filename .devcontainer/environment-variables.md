# Environment Variables for Maybe Finance

## Application Name Configuration

You can customize the application name by setting the `APP_NAME` environment variable.

### Default
- `APP_NAME=Maybe` (default if not set)

### Custom Example
- `APP_NAME=Expenso` (currently configured in dev container)

## Other Available Environment Variables

- `DATABASE_URL` - PostgreSQL database connection string
- `REDIS_URL` - Redis connection string  
- `RAILS_ENV` - Rails environment (development, production, test)
- `SECRET_KEY_BASE` - Rails secret key base
- `SELF_HOSTED` - Set to "true" for self-hosted mode
- `PLAID_CLIENT_ID` - Plaid integration client ID
- `PLAID_SECRET` - Plaid integration secret
- `STRIPE_PUBLIC_KEY` - Stripe public key
- `STRIPE_SECRET_KEY` - Stripe secret key

## OCR Configuration (Optional)

For receipt processing with OCR, you can configure one or more of these services:

### Google Vision API
- `GOOGLE_VISION_API_KEY` - Google Cloud Vision API key
- `GOOGLE_APPLICATION_CREDENTIALS` - Path to Google service account JSON file

### AWS Textract
- `AWS_ACCESS_KEY_ID` - AWS access key ID
- `AWS_SECRET_ACCESS_KEY` - AWS secret access key
- `AWS_REGION` - AWS region (default: us-east-1)

### Tesseract OCR
- No configuration needed - included in dev container
- Works offline but less accurate than cloud services

## Current Dev Container Configuration

The dev container is currently configured with `APP_NAME=Expenso` in the docker-compose.yml file.

To change this:
1. Edit `.devcontainer/docker-compose.yml`
2. Update the `APP_NAME` value in the `x-rails-env` section
3. Restart the dev container

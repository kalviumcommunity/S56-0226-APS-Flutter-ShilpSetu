# Environment Variables Setup

## Cloudinary Configuration

This app uses environment variables for Cloudinary credentials to keep them secure.

### Development (Default Values)

The app includes default values for development. No additional setup needed for local testing.

### Production Deployment

To use custom Cloudinary credentials in production:

#### Option 1: Command Line (Recommended for Testing)

```bash
flutter run --dart-define=CLOUDINARY_CLOUD_NAME=your_cloud_name \
            --dart-define=CLOUDINARY_UPLOAD_PRESET=your_preset
```

#### Option 2: Build with Environment Variables

```bash
flutter build apk --dart-define=CLOUDINARY_CLOUD_NAME=your_cloud_name \
                  --dart-define=CLOUDINARY_UPLOAD_PRESET=your_preset
```

#### Option 3: VS Code Launch Configuration

Add to `.vscode/launch.json`:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Flutter (Production)",
      "request": "launch",
      "type": "dart",
      "args": [
        "--dart-define=CLOUDINARY_CLOUD_NAME=your_cloud_name",
        "--dart-define=CLOUDINARY_UPLOAD_PRESET=your_preset"
      ]
    }
  ]
}
```

### Security Notes

- Never commit actual credentials to Git
- Use unsigned upload presets (no API secret required)
- Default values are for development only
- Override with real credentials for production builds

### Getting Cloudinary Credentials

1. Sign up at https://cloudinary.com
2. Go to Dashboard → Settings
3. Copy your Cloud Name
4. Create an unsigned upload preset:
   - Settings → Upload → Upload presets
   - Add upload preset
   - Set signing mode to "Unsigned"
   - Copy the preset name

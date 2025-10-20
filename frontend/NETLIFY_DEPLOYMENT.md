# Netlify Deployment Guide for BrightBuy Frontend

## Issues Fixed

✅ Removed `--turbopack` flag from build script (Netlify compatibility)
✅ Added `netlify.toml` configuration file
✅ Updated `next.config.mjs` with proper settings
✅ Created `.env.example` for environment variables

## Deployment Steps

### 1. Install Netlify Next.js Plugin

Before deploying, make sure Netlify has the Next.js plugin installed. This happens automatically, but if you encounter issues:

```bash
npm install -D @netlify/plugin-nextjs
```

### 2. Configure Environment Variables in Netlify

Go to your Netlify site dashboard:
- **Site settings** → **Environment variables**
- Add the following variable:

```
Key: NEXT_PUBLIC_API_URL
Value: https://your-backend-api-url.com/api
```

**Important:** Replace `https://your-backend-api-url.com/api` with your actual backend API URL.

### 3. Build Settings in Netlify

In your Netlify site settings, configure:

- **Build command:** `npm run build`
- **Publish directory:** `.next`
- **Node version:** 18 or higher

### 4. Deploy

You can deploy via:

#### Option A: Git-based deployment (Recommended)
1. Push your code to GitHub/GitLab/Bitbucket
2. Connect your repository to Netlify
3. Netlify will automatically deploy on push

#### Option B: Manual deployment
```bash
# Install Netlify CLI
npm install -g netlify-cli

# Login to Netlify
netlify login

# Deploy
netlify deploy --prod
```

## Backend Considerations

⚠️ **Important:** Your backend needs to be hosted separately!

Your frontend is making API calls to a backend server. You need to:

1. **Host your backend** on a service like:
   - Heroku
   - Render
   - Railway
   - AWS/Azure/GCP
   - DigitalOcean

2. **Update the API URL** in Netlify environment variables to point to your hosted backend

3. **Configure CORS** on your backend to allow requests from your Netlify domain:
   ```javascript
   // In your backend (server.js or similar)
   const cors = require('cors');
   app.use(cors({
     origin: 'https://your-netlify-site.netlify.app',
     credentials: true
   }));
   ```

## Common Issues & Solutions

### Issue: 404 errors on page refresh
**Solution:** The `netlify.toml` file includes redirects configuration to handle client-side routing.

### Issue: API calls failing
**Solution:** 
- Check if `NEXT_PUBLIC_API_URL` is set in Netlify environment variables
- Ensure your backend is running and accessible
- Check CORS configuration on backend
- Verify the backend URL is correct

### Issue: Images not loading
**Solution:** 
- Images should be in the `public` folder
- For external images, add domains to `next.config.mjs`
- Use relative paths for local images: `/images/...`

### Issue: Build fails
**Solution:**
- Check Node version (should be 18+)
- Clear build cache in Netlify
- Check build logs for specific errors
- Try building locally: `npm run build`

## Testing Locally

Before deploying, test the production build locally:

```bash
# Build the project
npm run build

# Run the production build
npm start
```

## Environment Variables

Create a `.env.local` file for local development (don't commit this):

```
NEXT_PUBLIC_API_URL=http://localhost:5001/api
```

For production, set this in Netlify to your actual backend URL.

## Next Steps

1. ✅ Configuration files created
2. 🔄 Host your backend API
3. 🔄 Set environment variables in Netlify
4. 🔄 Deploy to Netlify
5. 🔄 Test the deployed application

## Need Help?

- Check Netlify logs for build errors
- Review Next.js deployment documentation
- Ensure backend API is accessible from the internet

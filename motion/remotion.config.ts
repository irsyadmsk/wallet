import { Config } from '@remotion/cli/config';

// Fonts and the wordmark come straight from the app's own assets, so the
// videos cannot drift from the product's typography.
Config.setPublicDir('../assets');
Config.setVideoImageFormat('jpeg');
Config.setConcurrency(2);

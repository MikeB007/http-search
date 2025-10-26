# NewsSearch

This project was generated with [Angular CLI](https://github.com/angular/angular-cli) version 12.0.2.

## Live Demo

🚀 **Deployed at:** https://mikeb007.github.io/http-search/#/search/Bitcoin

Example searches:
- [Bitcoin News](https://mikeb007.github.io/http-search/#/search/Bitcoin)
- [Gold Market](https://mikeb007.github.io/http-search/#/search/Gold)
- [Technology Updates](https://mikeb007.github.io/http-search/#/search/Technology)

**Mixed Content / CORS Proxy**

The production build uses a CORS proxy (AllOrigins) to work around Mixed Content errors when accessing HTTP backend from HTTPS GitHub Pages.

- **Development:** Direct HTTP connection to `http://[SERVER-IP]:[PORT]`
- **Production:** Proxied through `https://api.allorigins.win/raw?url=...`

## Alternative Solutions

If the proxy service is slow or unavailable:

1. **Use HTTP access** (if available) instead of HTTPS
2. **Set up HTTPS on backend** at `[SERVER-IP]:[PORT]` with SSL certificate
3. **Use a different proxy:**
   - Update `src/app/_environments/environment.prod.ts`
   - Options: `cors-anywhere.herokuapp.com`, `corsproxy.io`, or deploy your own

## Development server

Run `ng serve` for a dev server. Navigate to `http://localhost:4200/`. The app will automatically reload if you change any of the source files.

## Code scaffolding

Run `ng generate component component-name` to generate a new component. You can also use `ng generate directive|pipe|service|class|guard|interface|enum|module`.

## Build

Run `ng build` to build the project. The build artifacts will be stored in the `dist/` directory.

## Running unit tests

Run `ng test` to execute the unit tests via [Karma](https://karma-runner.github.io).

## Running end-to-end tests

Run `ng e2e` to execute the end-to-end tests via a platform of your choice. To use this command, you need to first add a package that implements end-to-end testing capabilities.

## Further help

To get more help on the Angular CLI use `ng help` or go check out the [Angular CLI Overview and Command Reference](https://angular.io/cli) page.

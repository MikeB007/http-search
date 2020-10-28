import { AppRoutingModule } from './app-routing.module';
import { RouterModule } from '@angular/router';
import { NgModule } from '@angular/core';
import { BrowserModule } from '@angular/platform-browser';
import { FormsModule } from '@angular/forms';
import { HttpClientModule } from '@angular/common/http';
import { HttpClientXsrfModule } from '@angular/common/http';

import { HttpClientInMemoryWebApiModule } from 'angular-in-memory-web-api';

import {HTTP_INTERCEPTORS} from '@angular/common/http';

import { InMemoryDataService } from './in-memory-data.service';

import { RequestCache, RequestCacheWithMap } from './request-cache.service';

import { AppComponent } from './app.component';
import { AuthService } from './auth.service';
import { ConfigComponent } from './config/config.component';
import { DownloaderComponent } from './downloader/downloader.component';
import { HeroesComponent } from './heroes/heroes.component';
import { HttpErrorHandler } from './http-error-handler.service';
import { MessageService } from './message.service';
import { MessagesComponent } from './messages/messages.component';
import { NewsSearchComponent } from './news-search/news-search.component';
import { UploaderComponent } from './uploader/uploader.component';

import { httpInterceptorProviders } from './http-interceptors/index';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';

import { MatInputModule } from '@angular/material/input';
import {MatProgressSpinnerModule} from '@angular/material/progress-spinner';
import { MySpinnerComponent } from './my-spinner/my-spinner.component';
import { MySpinnerService } from './my-spinner/my-spinner.service';
import { MyHTTPLoaderInterceptor } from './http-interceptors/loader-interceptor.service';
import { NewsStatsComponent } from './news-stats/news-stats.component';
import { NewsDashComponent } from './news-dash/news-dash.component';
import { NewsNavComponent } from './news-nav/news-nav.component';
import { UnderConstructionComponent } from './under-construction/under-construction.component';

@NgModule({
  imports: [
    BrowserModule,
    MatInputModule,
    MatProgressSpinnerModule,
    FormsModule,
    RouterModule,
    AppRoutingModule,
    // import HttpClientModule after BrowserModule.
    HttpClientModule,
    HttpClientXsrfModule.withOptions({
      cookieName: 'My-Xsrf-Cookie',
      headerName: 'My-Xsrf-Header',
    }),

    // The HttpClientInMemoryWebApiModule module intercepts HTTP requests
    // and returns simulated server responses.
    // Remove it when a real server is ready to receive requests.
    HttpClientInMemoryWebApiModule.forRoot(
      InMemoryDataService, {
        dataEncapsulation: false,
        passThruUnknownUrl: true,
        put204: false // return entity after PUT/update
      }
    ),
    BrowserAnimationsModule,
  ],
  declarations: [
    AppComponent,
    ConfigComponent,
    DownloaderComponent,
    HeroesComponent,
    MessagesComponent,
    UploaderComponent,
    NewsSearchComponent,
    MySpinnerComponent,
    NewsStatsComponent,
    NewsDashComponent,
    NewsNavComponent,
    UnderConstructionComponent,
  ],
  providers: [
    AuthService,
    HttpErrorHandler,
    MessageService,
    { provide: RequestCache, useClass: RequestCacheWithMap },
    httpInterceptorProviders,
    { provide: HTTP_INTERCEPTORS, useClass: MyHTTPLoaderInterceptor, multi: true },
    MySpinnerService
  ],
  bootstrap: [ AppComponent ]
})
export class AppModule {}

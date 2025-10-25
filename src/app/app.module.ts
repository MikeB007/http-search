import { AppRoutingModule } from './app-routing.module';
import { RouterModule } from '@angular/router';
import { NgModule } from '@angular/core';
import { BrowserModule } from '@angular/platform-browser';
import { FormsModule } from '@angular/forms';
import { HttpClientModule } from '@angular/common/http';
import { HttpClientXsrfModule } from '@angular/common/http';

import {HTTP_INTERCEPTORS} from '@angular/common/http';
import { RequestCache, RequestCacheWithMap } from './request-cache.service';
import { AppComponent } from './app.component';
import { HttpErrorHandler } from './http-error-handler.service';
import { NewsSearchComponent } from './news-search/news-search.component';

import { httpInterceptorProviders } from './http-interceptors/index';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';

import { MatInputModule } from '@angular/material/input';
import {MatProgressSpinnerModule} from '@angular/material/progress-spinner';
import { MySpinnerComponent } from './my-spinner/my-spinner.component';
import { MySpinnerService } from './my-spinner/my-spinner.service';
import { MyHTTPLoaderInterceptor } from './http-interceptors/loader-interceptor.service';

import { NewsDashComponent } from './news-dash/news-dash.component';
import { NewsNavComponent } from './news-nav/news-nav.component';
import { CompanyDashComponent } from './company-dash/company-dash.component';
import { AuthService } from './auth.service';
import { MessageService } from './message.service';
import { NewsFindComponent } from './news-find/news-find.component';
import { ShowProfileComponent } from './stocks/show-profile/show-profile.component';
@NgModule({
  declarations: [
    AppComponent,
    MySpinnerComponent,
    NewsSearchComponent,
    NewsDashComponent,
    NewsNavComponent,
  CompanyDashComponent,
    NewsFindComponent,
    ShowProfileComponent
  ],

  imports: [
    BrowserModule,
    AppRoutingModule,
    MatInputModule,
    MatProgressSpinnerModule,
    FormsModule,
    RouterModule,
    HttpClientModule
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
  bootstrap: [AppComponent]
})
export class AppModule { }

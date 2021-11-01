import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders, HttpParams } from '@angular/common/http';

import { Observable, of } from 'rxjs';
import { catchError, map } from 'rxjs/operators';

import { HttpErrorHandler, HandleError } from '../http-error-handler.service';


export interface KeywordsInfo {
  keyword: string;
}


export interface StatusInfo {
  ID: string;
}


export const callUrl  = 'http://198.84.134.138:5000/api/news/get/keywords';


const httpOptions = {
  headers: new HttpHeaders({
    'x-refresh':  'true'
  })
};

function createHttpOptions(searchTerm: string, refresh = false) {
    // npm package name search api
    // e.g., http://npmsearch.com/query?q=dom'
    const params = new HttpParams({ fromObject: { q: searchTerm } });
    const headerMap = refresh ? {'x-refresh': 'true'} : {};
    const headers = new HttpHeaders(headerMap) ;
    return { headers, params };
}

@Injectable({
  providedIn: 'root'
})

export class NewsNavService {
  private handleError: HandleError;


  constructor(
    private http: HttpClient,
    httpErrorHandler: HttpErrorHandler) {
    this.handleError = httpErrorHandler.createHandleError('HeroesService');
  }

  getKeywords( dataLoading:boolean, refresh = false): Observable<KeywordsInfo[]> {
    dataLoading=false;
    console.log("Showing results");
    // clear if no pkg name

    const options = createHttpOptions("", refresh);
   // TODO: Add error handling
   return this.http.get(callUrl).pipe(
     map((data: any) => {
       return data.map((nn: KeywordsInfo) => ({
           keyword:nn.keyword
         }  as KeywordsInfo )
       );
     }),
     catchError(this.handleError('search', []))
   );
 }

}

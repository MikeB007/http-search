import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders, HttpParams } from '@angular/common/http';

import { Observable, of } from 'rxjs';
import { catchError, map } from 'rxjs/operators';

import { HttpErrorHandler, HandleError } from '../http-error-handler.service';


export interface NewsInfo {
  ID: string;
  SRC: string;
  ARTICLE_DT: string;
  ARTICLE_TM: string;
	LABEL: string;
	ARTICLE_URL: string;
}



//export const searchUrl = 'https://npmsearch.com/query';
export const searchUrl = 'http://107.190.108.53/api/news/search/';



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

@Injectable()
export class NewsSearchService {

  private handleError: HandleError;
  find: string;
  constructor(
    private http: HttpClient,
    httpErrorHandler: HttpErrorHandler) {
    this.handleError = httpErrorHandler.createHandleError('HeroesService');
  }

  search(searchTerm: string, dataLoading:boolean, refresh = false): Observable<NewsInfo[]> {
     dataLoading=true;

     this.find = searchTerm;
     const myRegExp = new RegExp(this.find, "gi");

     console.log("Showing results");
     console.log(this.find);
     // clear if no pkg name
    if (!searchTerm.trim() || (searchTerm.trim().length)<4) { return of([]); }

    const options = createHttpOptions(searchTerm, refresh);


    // TODO: Add error handling
    return this.http.get(searchUrl+searchTerm).pipe(
      map((data: any) => {
        return data.map((nn: NewsInfo) => ({
            SRC:nn.SRC,
            ARTICLE_DT: nn.ARTICLE_DT,
            ARTICLE_TM: nn.ARTICLE_TM,
            LABEL: nn.LABEL.replace(myRegExp," <div class='searchstyle2'>" + searchTerm +"</div>"),
            ARTICLE_URL: nn.ARTICLE_URL
          }  as NewsInfo )
        );
      }),
      catchError(this.handleError('search', []))
    );
  }
}

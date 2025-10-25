import {Settings} from "../_environments/environment";
import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders, HttpParams } from '@angular/common/http';

import { Observable, of } from 'rxjs';
import { catchError, map } from 'rxjs/operators';

import { HttpErrorHandler, HandleError } from '../http-error-handler.service';


export interface NewsInfo {
  ID: string;
  SRC: string;
  isFAV:boolean;
  ARTICLE_DT: string;
  ARTICLE_TM: string;
	LABEL: string;
	ARTICLE_URL: string;
  FAV_ID: string;
  DAYS_OLD:number;
}


export interface StatusInfo {
  ID: string;
}


//export const searc Url = 'https://npmsearch.com/query';
export const searchUrl  = Settings.server_url + '/api/news/search/';
export const saveFavURL = Settings.server_url + '/api/news/saveFav/';



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

  public getTime():string {
    var tm = new Date();
   return ("Search:" + tm.getHours() + ":" + tm.getMinutes() + ":" + tm.getSeconds());

  }

  private handleError: HandleError;
  find: string;
  myAlert:string;
  constructor(
    private http: HttpClient,
    httpErrorHandler: HttpErrorHandler) {
    this.handleError = httpErrorHandler.createHandleError('HeroesService');
  }



  searchIt(searchTerm: string, dataLoading:boolean, refresh = false): Observable<NewsInfo[]> {
     dataLoading=false;
     this.find = searchTerm;
     const myRegExp = new RegExp(this.find, "gi");

     console.log("getting results:Search it");
     // clear if no pkg name
    if (!searchTerm.trim() || (searchTerm.trim().length)<3) { return of([]); }
    const options = createHttpOptions(searchTerm, refresh);
    console.log("getting results:Search it 2");
    // TODO: Add error handling
    return this.http.get(searchUrl+searchTerm +"/7").pipe(
      map((data: any) => {
        return data.map((nn: NewsInfo) => ({
            ID:nn.ID,
            SRC:nn.SRC,
            ARTICLE_DT: nn.ARTICLE_DT,
            ARTICLE_TM: nn.ARTICLE_TM,
            LABEL: nn.LABEL.replace(myRegExp," <div class='searchstyle2'>" + searchTerm +"</div>"),
            ARTICLE_URL: nn.ARTICLE_URL,
            FAV_ID: nn.FAV_ID,
            DAYS_OLD: nn.DAYS_OLD
          }  as NewsInfo )
        );

      }),
      catchError(this.handleError('search', []))
    );
  }

  saveFav(id: string, dataLoading:boolean, refresh = false): Observable <StatusInfo[]> {

    console.log("The save fave function has been called")
    dataLoading=false;
   const options = createHttpOptions(id, refresh);

   // TODO: Add error handling
   return this.http.get(saveFavURL+id ).pipe(
     map((data: any) => {
       return data.map((nn: StatusInfo) => ({
           ID:nn.ID,
         }  as StatusInfo )
       );
     }),
     catchError(this.handleError('SaveFav', []))
   );
 }

}

import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import {SERVER} from "../_environments/environment";
import { catchError, map } from 'rxjs/operators';
import { HttpErrorHandler, HandleError } from '../http-error-handler.service';


const baseURL = SERVER.server_url;

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

@Injectable({
  providedIn: 'root'
})

export class NewsService {
  private handleError: HandleError;

  constructor(private http: HttpClient, httpErrorHandler: HttpErrorHandler) {
    this.handleError = httpErrorHandler.createHandleError('HeroesService');
    }

  // Functions
  getKeywordsEric(){
    return this.http.get(baseURL+'news/get/keywords/0')
  }

  getKeywordsRecent(){
    return this.http.get(baseURL+'news/get/keywords/1')
  }
  // Functions
  getSearchResults( key: string){
    const myRegExp = new RegExp(key, "gi")
    return this.http.get(baseURL +'news/search/' + key +"/10").pipe(
      map((data: any) => {
        return data.map((nn: NewsInfo) => ({
            ID:nn.ID,
            SRC:nn.SRC,
            ARTICLE_DT: nn.ARTICLE_DT,
            ARTICLE_TM: nn.ARTICLE_TM,
            LABEL: nn.LABEL.replace(myRegExp," <div class='searchstyle2'>" + key +"</div>"),
            ARTICLE_URL: nn.ARTICLE_URL,
            FAV_ID: nn.FAV_ID,
            DAYS_OLD: nn.DAYS_OLD
          }  as NewsInfo )
        );

      }),
      catchError(this.handleError('search', []))
    );


  }

  getFavourites(){
      return this.http.get("url")
  }

}

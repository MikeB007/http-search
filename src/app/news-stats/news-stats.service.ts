import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders, HttpParams, HttpErrorResponse } from '@angular/common/http';

import { Observable, of } from 'rxjs';
import { catchError, map,tap } from 'rxjs/operators';

import { HttpErrorHandler, HandleError } from '../http-error-handler.service';

export interface StatsInfo {
  SRC: string;
  count: BigInteger;
  }


@Injectable({
 providedIn: 'root'
 })


export class NewsStatService {

  constructor(private http: HttpClient) { }

  private extractData(res: Response) {
    const body = res;
    return body || { };
  }
  getStats(): Observable<any> {
    return this.http.get(statsUrl).pipe(
      map(this.extractData));
  }

  private handleError<T> (operation = 'operation', result?: T) {
    return (error: any): Observable<T> => {
      // TODO: send the error to remote logging infrastructure
      console.error(error); // log to console instead
      // TODO: better job of transforming error for user consumption
      console.log(`${operation} failed: ${error.message}`);
      // Let the app keep running by returning an empty result.
      return of(result as T);
    };
  }
}
export const statsUrl = 'http://107.190.108.53/api/news/stats';

const httpOptions = {
  headers: new HttpHeaders({
    'x-refresh':  'true',
    'Content-Type':  'application/json'
  })
}

function createHttpOptions( refresh = false) {
  const params = new HttpParams({ });
  const headerMap = refresh ? {'x-refresh': 'true'} : {};
  const headers = new HttpHeaders(headerMap) ;
    return { headers, params };
}





import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import {SERVER} from "../_environments/environment";

const baseURL = SERVER.server_url;

@Injectable({
  providedIn: 'root'
})

export class NewsService {

  constructor(private http: HttpClient) { }

  // Functions
  getKeywords(){
    return this.http.get(baseURL+'news/get/keywords')
  }

  getFavourites(){
      return this.http.get("url")
  }

}

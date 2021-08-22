import { Component, OnInit, ViewEncapsulation } from '@angular/core';


import { Observable, Subject } from 'rxjs';
import { debounceTime, distinctUntilChanged, switchMap } from 'rxjs/operators';

import { NewsInfo, NewsSearchService } from './news-search.service';



@Component({
  selector: 'app-news-search',
  templateUrl: './news-search.component.html',
  styleUrls: ['./news.search.css'],

  providers: [NewsSearchService ],
  encapsulation: ViewEncapsulation.None,
})
export class NewsSearchComponent implements OnInit {
  public withRefresh = false;
  public dataLoading=false;
  imageType:string[];

  isLiked:boolean[];
  heartImage:boolean[];

  news$: Observable<NewsInfo[]>;
  private searchText$ = new Subject<string>();

  handleFocus = event => {
    event.preventDefault();
    const { target } = event;
    const extensionStarts = target.value.length();

    //const extensionStarts = target.value.lastIndexOf('.');
    target.focus();
    target.setSelectionRange(0, extensionStarts);
  }

  setFavourite(text:string, index:number){
  this.searchService.saveFav(text, true).toPromise().then(result => console.log("Success"));
  this.heartImage[index] =  !this.heartImage[index]  ;
  }

  selectMyText(text:string)
  {
    text = "component";
    alert(text);
  }

  search(SearchTerm: string  ) {

    this.searchText$.next(SearchTerm);
  }

  ngOnInit() {
    this.news$ = this.searchText$.pipe(
      debounceTime(900),
      distinctUntilChanged(),
      switchMap(SearchTerm => this.searchService.search(SearchTerm, this.withRefresh))
    );
    this.imageType = new Array(2);
    this.imageType[0]="heart.svg";
    this.imageType[1]="heart_on.svg";
    this.heartImage = new Array(300).fill(false);
  }

  constructor(private searchService: NewsSearchService) { }



  toggleRefresh() { this.withRefresh  = ! this.withRefresh; }

}

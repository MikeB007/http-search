import { NewsService } from './../_services/news.service';
import { Component, OnInit, ViewEncapsulation } from '@angular/core';


import { Observable, Subject } from 'rxjs';
import { debounceTime, distinctUntilChanged, switchMap, map } from 'rxjs/operators';

import { NewsInfo, NewsSearchService } from './news-search.service';
import { ActivatedRoute } from '@angular/router';
import { ThisReceiver } from '@angular/compiler';





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
  public articles;
  imageType:string[];

  backColor:string[];


  isLiked:boolean[];
  heartImage:boolean[];
  key:string;
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
  }

  search(SearchTerm: string  ) {
    this.searchText$.next(SearchTerm);
  }

  ngOnInit() {
    this.news$ = this.searchText$.pipe(
      debounceTime(900),
      distinctUntilChanged(),
      switchMap(SearchTerm => this.searchService.searchIt(SearchTerm, this.withRefresh))
    );
    this.imageType = new Array(2);
    this.imageType[0]="heart.svg";
    this.imageType[1]="heart_on.svg";
    this.heartImage = new Array(300).fill(false);
    this.backColor = new Array(10);
    this.backColor[0]='green';
    this.backColor[1]='orange';
    this.backColor[2]='blue';
    this.backColor[3]='yellow';
    this.backColor[4]='red';
    this.backColor[5]='purple';
    this.backColor[6]='brown';
    this.backColor[7]='magenta';

    this.newsService.getSearchResults(this.key).subscribe((news$) => {
      this.articles= (news$)
    }
    );

  }

  constructor(private searchService: NewsSearchService,private _Activatedroute:ActivatedRoute,private newsService: NewsService) {
   // this.key=this._Activatedroute.snapshot.paramMap.get("key");

    this._Activatedroute.paramMap.subscribe(params => {
      this.key = params.get('key');
  });

  }


  toggleRefresh() { this.withRefresh  = ! this.withRefresh; }

}




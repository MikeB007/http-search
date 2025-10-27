import { FontService } from './../font-service';
import { NewsService } from './../_services/news.service';
import { Component, OnInit, OnDestroy, ViewEncapsulation } from '@angular/core';


import { Observable, Subject,Subscription } from 'rxjs';
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
export class NewsSearchComponent implements OnInit, OnDestroy {
  public withRefresh = false;
  public dataLoading=false;
  public articles;
  //public fs: FontService;
  imageType:string[];
  backColor:string[];

  fSize: String;
  subscription: Subscription;


  isLiked:boolean[];
  heartImage:boolean[];
  key:string;
  news: any[];
  news$: Observable<NewsInfo[]>;
  //news$:any;
  private searchText$ = new Subject<string>();

  handleFocus = event => {
    const { target } = event;
    // Only select text if there is content in the input
    if (target.value && target.value.trim().length > 0) {
      // Use setTimeout to ensure the selection happens after the click event
      setTimeout(() => {
        target.select();
      }, 0);
    }
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

  onSearchInput(event: Event): void {
    const target = event.target as HTMLInputElement;
    this.search(target.value);
  }

  getFavoriteIconPath(index: number): string {
    return `assets/img/fav/${this.imageType[+this.heartImage[index]]}`;
  }

  getBackgroundColor(daysOld: number): string {
    return this.backColor[daysOld];
  }

  ngOnInit() {
    this.subscription = this.data.currentFontSize.subscribe(fSize => this.fSize = fSize)
    this.news$ = this.searchText$.pipe(
      debounceTime(900),
      distinctUntilChanged(),
      switchMap(SearchTerm => this.searchService.searchIt(SearchTerm, this.withRefresh))
    );

    // Translating the observable into an array
    (this.news$.subscribe(result => this.news = result))
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
  }

  ngOnDestroy(){
    this.subscription.unsubscribe;
  }

  constructor(private searchService: NewsSearchService,private _Activatedroute:ActivatedRoute,private newsService: NewsService,private data:FontService) {
   // this.key=this._Activatedroute.snapshot.paramMap.get("key");

    this._Activatedroute.paramMap.subscribe(params => {
      this.key = params.get('key');
      if(this.key){
        this.searchService.searchIt(this.key, this.withRefresh).subscribe(result => {
          this.news= result
        })
      }
  });

  }


  toggleRefresh() { this.withRefresh  = ! this.withRefresh; }

}




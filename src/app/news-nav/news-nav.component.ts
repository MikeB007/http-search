import { FontService } from '../font-service';
import { NewsSearchComponent } from './../news-search/news-search.component';
import { nullSafeIsEquivalent } from '@angular/compiler/src/output/output_ast';
import { Component, OnInit, OnDestroy } from '@angular/core';
import { Observable, Subject,Subscription } from 'rxjs';
import { KeywordsInfo, NewsNavService } from './news-nav.service';
import { Output, EventEmitter } from '@angular/core';


// Services
import { NewsService } from '../_services/news.service';
import { style } from '@angular/animations';


@Component({
  selector: 'app-news-nav',
  templateUrl: './news-nav.component.html',
  styleUrls: ['./news-nav.component.css']
})
export class NewsNavComponent implements OnInit, OnDestroy   {
  // keywords$: Observable<KeywordsInfo[]>;
  // this.keywords=nullSafeIsEquivalent;
  // constructor(private newsNavService: NewsNavService) { }
  // OnInit(): void {
  // this.keywords$= null;
  // }

  // Output to send the latest term to the search

  fStyle:string;
  subscription: Subscription;

  @Output()
  public popularSearch = new EventEmitter();
  public recentSearch = new EventEmitter();
  public fontStyle = new EventEmitter();

  // Variables
  public keywords;
  public customFontSize;

  public recentKeywords;
  constructor(private newsService: NewsService,private data:FontService  ){}

  ngOnInit() : void {
    this.customFontSize = 4;
    this.subscription = this.data.currentFontSize.subscribe (fStyle => this.fStyle = fStyle );
    this.newsService.getKeywordsEric().subscribe((keywords) => {
      this.keywords= (keywords)
    }
    );

    this.newsService.getKeywordsRecent().subscribe((recentKeywords) => {
      this.recentKeywords= (recentKeywords)
    }

    );
  }


  ngOnDestroy(){
    this.subscription.unsubscribe();
  }



  ImageClick (size){

    if ((size == 1 && this.customFontSize == 5) || (size == -1 && this.customFontSize == 1))
      {size =0}

    this.customFontSize = this.customFontSize + size;
    this.fStyle = "myinline" + this.customFontSize;

    this.data.changeFont(this.fStyle);
    //alert (this.fStyle);
  }


  updatePopularSearch(term){
   // console.log("updated popular search to ", term)
    //this.popularSearch.emit(term);
  }

  updateRecentSearch(term){
    //console.log("updated recent search to ", term)
    //this.recentSearch.emit(term);
  }

}

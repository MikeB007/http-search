import { NewsSearchComponent } from './../news-search/news-search.component';
import { nullSafeIsEquivalent } from '@angular/compiler/src/output/output_ast';
import { Component, OnInit } from '@angular/core';
import { Observable, Subject } from 'rxjs';
import { KeywordsInfo, NewsNavService } from './news-nav.service';
import { Output, EventEmitter } from '@angular/core';

// Services
import { NewsService } from '../_services/news.service';

@Component({
  selector: 'app-news-nav',
  templateUrl: './news-nav.component.html',
  styleUrls: ['./news-nav.component.css']
})
export class NewsNavComponent implements OnInit {
  // keywords$: Observable<KeywordsInfo[]>;
  // this.keywords=nullSafeIsEquivalent;
  // constructor(private newsNavService: NewsNavService) { }
  // OnInit(): void {
  // this.keywords$= null;
  // }

  // Output to send the latest term to the search
  @Output()
  public popularSearch = new EventEmitter();


  // Variables
  public keywords;
  constructor(private newsService: NewsService ){}

  ngOnInit() : void {

    this.newsService.getKeywordsEric().subscribe((keywords) => {
      this.keywords= (keywords)
    }
    );

  }

  updatePopularSearch(term){
    console.log("updated popular search to ", term)
    this.popularSearch.emit(term);
  }

}

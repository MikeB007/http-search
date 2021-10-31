import { NewsSearchComponent } from './../news-search/news-search.component';
import { nullSafeIsEquivalent } from '@angular/compiler/src/output/output_ast';
import { Component, OnInit } from '@angular/core';
import { Observable, Subject } from 'rxjs';
import { KeywordsInfo, NewsNavService } from './news-nav.service';

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

  // Variables
  public keywords;
  constructor(private newsService: NewsService ){}

  ngOnInit() : void {

    this.newsService.getKeywordsEric().subscribe((keywords) => {
      this.keywords= (keywords)
    }
    );

  }

}

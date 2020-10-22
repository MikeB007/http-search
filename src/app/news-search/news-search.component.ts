import { Component, OnInit, ViewEncapsulation } from '@angular/core';

import { Observable, Subject } from 'rxjs';
import { debounceTime, distinctUntilChanged, switchMap } from 'rxjs/operators';

import { NewsInfo, NewsSearchService } from './news-search.service';



@Component({
  selector: 'app-news-search',
  templateUrl: './news-search.component.html',
  styleUrls: ['./news.search.css'],
  providers: [ NewsSearchService ],
  encapsulation: ViewEncapsulation.None,
})
export class NewsSearchComponent implements OnInit {
  withRefresh = false;
  dataLoading=false;
  news$: Observable<NewsInfo[]>;
  private searchText$ = new Subject<string>();

  search(SearchTerm: string) {
    this.searchText$.next(SearchTerm);
  }

  ngOnInit() {
    this.news$ = this.searchText$.pipe(
      debounceTime(500),
      distinctUntilChanged(),
      switchMap(SearchTerm =>this.searchService.search(SearchTerm, this.withRefresh))
    );
  }

  constructor(private searchService: NewsSearchService) { }


  toggleRefresh() { this.withRefresh = ! this.withRefresh; }

}

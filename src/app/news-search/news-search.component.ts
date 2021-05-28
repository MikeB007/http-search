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

  handleFocus = event => {
    event.preventDefault();
    const { target } = event;
    const extensionStarts = target.value.length();

    //const extensionStarts = target.value.lastIndexOf('.');
    target.focus();
    target.setSelectionRange(0, extensionStarts);
  }


  selectMyText(text:string)
  {
    text = "component";
    alert(text);
  }

  search(SearchTerm: string) {
    //alert(SearchTerm);
    this.searchText$.next(SearchTerm);
  }

  ngOnInit() {
    this.news$ = this.searchText$.pipe(
      debounceTime(900),
      distinctUntilChanged(),
      switchMap(SearchTerm =>this.searchService.search(SearchTerm, this.withRefresh))
    );
  }

  constructor(private searchService: NewsSearchService) { }


  toggleRefresh() { this.withRefresh = ! this.withRefresh; }

}

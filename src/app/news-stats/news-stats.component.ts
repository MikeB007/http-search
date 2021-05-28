import { Component, OnInit, ViewEncapsulation } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';

import { StatsInfo, NewsStatService } from './news-stats.service';



@Component({
  selector: 'app-news-stats',
  templateUrl: './news-stats.component.html',
  styleUrls: ['./news-stats.component.css'],
  providers: [ NewsStatService ],
  encapsulation: ViewEncapsulation.None,
})
export class NewsStatsComponent implements OnInit {

   stats: any = [];

  constructor(public _stats: NewsStatService, private route: ActivatedRoute, private router: Router) { }


  ngOnInit() {
 // this.getStats();
}


   getStats() {
    this.stats = []
    this._stats.getStats().subscribe((data: {}) => {
    console.log(data);
    this.stats = data;
  });
}
  }

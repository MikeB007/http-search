import { formatDate } from '@angular/common';
import { Component, OnInit } from '@angular/core';

@Component({
  selector: 'app-news-dash',
  templateUrl: './news-dash.component.html',
  styleUrls: ['./news-dash.component.css',]
})
export class NewsDashComponent implements OnInit {
a:string;

  public getTime():string {
    var tm = new Date();

   return ("Dash:" + tm.getHours() + ":" + tm.getMinutes() + ":" + tm.getSeconds());

  }

  constructor() { }

  ngOnInit(): void {
    this.a="test"+ Date();
  }

}

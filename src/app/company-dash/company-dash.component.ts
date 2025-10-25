import { formatDate } from '@angular/common';
import { Component, OnInit } from '@angular/core';

@Component({
  selector: 'app-company-dash',
  templateUrl: './company-dash.component.html',
  styleUrls: ['./company-dash.component.css',]
})
export class CompanyDashComponent implements OnInit {
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

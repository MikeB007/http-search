import { Component, OnInit } from '@angular/core';

import { ActivatedRoute } from '@angular/router';
import { NewsFindService } from './news-find.service';
import { ThisReceiver } from '@angular/compiler';
import { Router } from '@angular/router';
@Component({
  selector: 'app-news-find',
  templateUrl: './news-find.component.html',
  styleUrls: ['./news-find.component.css']
})
export class NewsFindComponent implements OnInit {

  key:string;

  constructor(private findService: NewsFindService,private _Activatedroute:ActivatedRoute,private router: Router) {
    // this.key=this._Activatedroute.snapshot.paramMap.get("key");
     this._Activatedroute.paramMap.subscribe(params => {
       this.key = params.get('key');
       if (this.key) {
         this.router.navigate(['/search/' + this.key]);
       }
   });

   }


  ngOnInit(): void {
  }

}


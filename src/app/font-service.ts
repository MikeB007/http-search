import { Injectable, OnInit } from '@angular/core';
import { BehaviorSubject } from 'rxjs';
@Injectable({
  providedIn: 'root'
})
export class FontService implements OnInit{
  private fontSize = new BehaviorSubject('myinline3');
  currentFontSize = this.fontSize.asObservable();
  constructor() { }
  changeFont(newFont: string) {
    this.fontSize.next(newFont);
  }
  ngOnInit(){
    this.changeFont("myinline2");
  }

}

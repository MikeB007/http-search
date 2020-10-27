import { Component } from '@angular/core';

@Component({
  selector: 'app-root',
  templateUrl: './app.component.html'
})
export class AppComponent {
  /*showHeroes = true;
  showConfig = true;
  showDownloader = true;
  showUploader = true;
  */
  showSearch = true;
  toggleSearch() { this.showSearch = !this.showSearch; }
 }

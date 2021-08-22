

// my-loader.component.ts
import { Component, OnInit } from '@angular/core';
import { MySpinnerService } from './my-spinner.service';

@Component({
  selector: 'app-my-spinner',
  templateUrl: './my-spinner.component.html',
  styleUrls: ['./my-spinner.component.css']
})
export class MySpinnerComponent implements OnInit {

  loading: boolean;

  constructor(private loaderService: MySpinnerService) {

    this.loaderService.isLoading.subscribe((v) => {
      this.loading = v;
    });

  }
  ngOnInit() {
  }

}


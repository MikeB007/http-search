import { ComponentFixture, TestBed } from '@angular/core/testing';

import { NewsStatsComponent } from './news-stats.component';

describe('NewsStatsComponent', () => {
  let component: NewsStatsComponent;
  let fixture: ComponentFixture<NewsStatsComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [ NewsStatsComponent ]
    })
    .compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(NewsStatsComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});

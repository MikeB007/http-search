import { ComponentFixture, TestBed } from '@angular/core/testing';

import { NewsNavComponent } from './news-nav.component';

describe('NewsNavComponent', () => {
  let component: NewsNavComponent;
  let fixture: ComponentFixture<NewsNavComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [ NewsNavComponent ]
    })
    .compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(NewsNavComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});

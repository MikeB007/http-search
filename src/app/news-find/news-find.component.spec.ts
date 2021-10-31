import { ComponentFixture, TestBed } from '@angular/core/testing';

import { NewsFindComponent } from './news-find.component';


describe('NewsFindComponent', () => {
  let component: NewsFindComponent;
  let fixture: ComponentFixture<NewsFindComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [ NewsFindComponent ]
    })
    .compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(NewsFindComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});

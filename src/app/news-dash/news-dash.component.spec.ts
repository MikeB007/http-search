import { ComponentFixture, TestBed } from '@angular/core/testing';

import { NewsDashComponent } from './news-dash.component';

describe('NewsDashComponent', () => {
  let component: NewsDashComponent;
  let fixture: ComponentFixture<NewsDashComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [ NewsDashComponent ]
    })
    .compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(NewsDashComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});

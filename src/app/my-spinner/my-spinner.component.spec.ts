import { ComponentFixture, TestBed } from '@angular/core/testing';

import { MySpinnerComponent } from './my-spinner.component';

describe('MySpinnerComponent', () => {
  let component: MySpinnerComponent;
  let fixture: ComponentFixture<MySpinnerComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [ MySpinnerComponent ]
    })
    .compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(MySpinnerComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});

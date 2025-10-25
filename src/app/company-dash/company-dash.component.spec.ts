import { ComponentFixture, TestBed } from '@angular/core/testing';

import { CompanyDashComponent } from './company-dash.component';

describe('CompanyDashComponent', () => {
  let component: CompanyDashComponent;
  let fixture: ComponentFixture<CompanyDashComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [ CompanyDashComponent ]
    })
    .compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(CompanyDashComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});

import { TestBed } from '@angular/core/testing';

import { MySpinnerService } from './my-spinner.service';

describe('MySpinnerService', () => {
  let service: MySpinnerService;

  beforeEach(() => {
    TestBed.configureTestingModule({});
    service = TestBed.inject(MySpinnerService);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });
});

import { TestBed } from '@angular/core/testing';

import { NewsNavService } from '../news-nav/news-nav.service';

describe('NewsNavService', () => {
  let service: NewsNavService;

  beforeEach(() => {
    TestBed.configureTestingModule({});
    service = TestBed.inject(NewsNavService);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });
});

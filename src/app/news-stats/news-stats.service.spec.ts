import { TestBed } from '@angular/core/testing';

import { NewsStatService } from './news-stats.service';

describe('NewsStatService', () => {
  let service: NewsStatService;

  beforeEach(() => {
    TestBed.configureTestingModule({});
    service = TestBed.inject(NewsStatService);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });
});

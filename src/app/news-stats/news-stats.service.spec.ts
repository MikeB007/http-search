import { TestBed } from '@angular/core/testing';
import { HttpClientTestingModule } from '@angular/common/http/testing';

import { NewsStatService } from './news-stats.service';

describe('NewsStatService', () => {
  let service: NewsStatService;

  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [HttpClientTestingModule]
    });
    service = TestBed.inject(NewsStatService);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });
});

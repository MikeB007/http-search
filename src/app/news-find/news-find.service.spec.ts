import { TestBed } from '@angular/core/testing';

import { NewsFindService } from './news-find.service';

describe('NewsFindService', () => {
  let service: NewsFindService;

  beforeEach(() => {
    TestBed.configureTestingModule({});
    service = TestBed.inject(NewsFindService);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });
});

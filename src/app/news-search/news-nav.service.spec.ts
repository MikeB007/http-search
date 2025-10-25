import { TestBed } from '@angular/core/testing';
import { HttpClientTestingModule } from '@angular/common/http/testing';

import { NewsNavService } from '../news-nav/news-nav.service';
import { HttpErrorHandler } from '../http-error-handler.service';
import { MessageService } from '../message.service';

describe('NewsNavService', () => {
  let service: NewsNavService;

  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [HttpClientTestingModule],
      providers: [HttpErrorHandler, MessageService]
    });
    service = TestBed.inject(NewsNavService);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });
});
